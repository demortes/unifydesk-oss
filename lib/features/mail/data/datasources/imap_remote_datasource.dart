import 'dart:convert';
import 'dart:typed_data';

import 'package:enough_mail/enough_mail.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/security/secure_storage_service.dart';
import '../../domain/entities/email_account.dart';
import '../../domain/entities/email_message.dart';
import '../models/email_message_model.dart';
import '../models/mailbox_model.dart';

/// Remote data source for IMAP operations.
class ImapRemoteDataSource {
  ImapRemoteDataSource({
    SecureStorageService? secureStorage,
    Logger? logger,
  })  : _secureStorage = secureStorage ?? SecureStorageService(),
        _logger = logger ?? Logger();

  final SecureStorageService _secureStorage;
  final Logger _logger;
  final _uuid = const Uuid();

  ImapClient? _client;
  String? _connectedAccountId;

  /// Connect to IMAP server for the given account.
  Future<void> connect(EmailAccount account) async {
    // Disconnect if connected to a different account
    if (_client != null && _connectedAccountId != account.id) {
      await disconnect();
    }

    // Already connected to this account
    if (_client != null && _connectedAccountId == account.id) {
      return;
    }

    final imapConfig = account.effectiveImapConfig;
    _client = ImapClient();

    try {
      await _client!.connectToServer(
        imapConfig.host,
        imapConfig.port,
        isSecure: account.useSsl,
      );

      // Authenticate
      final password = await _secureStorage.getPassword(account.id);
      if (password == null) {
        throw Exception('No credentials found for account ${account.email}');
      }

      await _client!.login(account.email, password);
      _connectedAccountId = account.id;
      _logger.d('Connected to IMAP server for ${account.email}');
    } catch (e) {
      _client = null;
      _connectedAccountId = null;
      _logger.e('Failed to connect to IMAP: $e');
      rethrow;
    }
  }

  /// Disconnect from IMAP server.
  Future<void> disconnect() async {
    if (_client != null) {
      try {
        await _client!.logout();
      } catch (e) {
        _logger.w('Error during logout: $e');
      }
      _client = null;
      _connectedAccountId = null;
    }
  }

  /// Check if connected.
  bool get isConnected => _client != null && _connectedAccountId != null;

  /// Fetch list of mailboxes from server.
  Future<List<MailboxModel>> fetchMailboxes(EmailAccount account) async {
    await connect(account);

    final mailboxes = await _client!.listMailboxes();
    return mailboxes
        .map(
          (mb) => MailboxModel(
            accountId: account.id,
            name: mb.name,
            path: mb.path,
            delimiter: mb.pathSeparator,
            flags: mb.flags.map((f) => f.toString()).toList(),
            isSelectable: !mb.isNotSelectable,
          ),
        )
        .toList();
  }

  /// Fetch mailbox status (message counts).
  Future<({int total, int unread})> fetchMailboxStatus(
    EmailAccount account,
    String mailboxPath,
  ) async {
    await connect(account);

    final mailbox = await _client!.selectMailboxByPath(mailboxPath);
    return (
      total: mailbox.messagesExists,
      unread: mailbox.messagesUnseen,
    );
  }

  /// Fetch emails from a mailbox.
  ///
  /// [sinceUid] - Only fetch emails with UID greater than this value.
  /// [limit] - Maximum number of emails to fetch.
  Future<List<EmailMessageModel>> fetchEmails(
    EmailAccount account,
    String mailboxPath, {
    int? sinceUid,
    int limit = 50,
  }) async {
    await connect(account);

    final mailbox = await _client!.selectMailboxByPath(mailboxPath);
    if (mailbox.messagesExists == 0) {
      return [];
    }

    try {
      FetchImapResult fetchResult;

      if (sinceUid != null && sinceUid > 0) {
        // Incremental sync: Fetch messages with UID greater than sinceUid
        final uidNext = mailbox.uidNext ?? (sinceUid + 1000);
        if (sinceUid >= uidNext - 1) {
          // No new messages
          return [];
        }
        final sequence = MessageSequence.fromRange(
          sinceUid + 1,
          uidNext - 1,
          isUidSequence: true,
        );
        fetchResult = await _client!.uidFetchMessages(
          sequence,
          '(UID FLAGS ENVELOPE BODYSTRUCTURE BODY.PEEK[TEXT])',
        );
      } else {
        // Full sync: Fetch latest messages by sequence number
        final start = mailbox.messagesExists > limit
            ? mailbox.messagesExists - limit + 1
            : 1;
        final sequence =
            MessageSequence.fromRange(start, mailbox.messagesExists);
        fetchResult = await _client!.fetchMessages(
          sequence,
          '(UID FLAGS ENVELOPE BODYSTRUCTURE BODY.PEEK[TEXT])',
        );
      }

      final messages = <EmailMessageModel>[];
      for (final result in fetchResult.messages) {
        final message = _parseMessage(account.id, mailboxPath, result);
        if (message != null) {
          messages.add(message);
        }
      }

      // Sort by date descending
      messages.sort((a, b) => b.date.compareTo(a.date));
      _logger.d('Fetched ${messages.length} messages from $mailboxPath');
      return messages;
    } catch (e) {
      _logger.e('Error fetching messages: $e');
      rethrow;
    }
  }

  /// Fetch a single email with full body.
  Future<EmailMessageModel?> fetchEmail(
    EmailAccount account,
    String mailboxPath,
    int uid,
  ) async {
    await connect(account);

    await _client!.selectMailboxByPath(mailboxPath);

    try {
      final sequence = MessageSequence.fromId(uid, isUid: true);
      final fetchResult = await _client!.uidFetchMessages(
        sequence,
        '(UID FLAGS ENVELOPE BODY[])',
      );

      if (fetchResult.messages.isEmpty) {
        return null;
      }

      return _parseMessage(
        account.id,
        mailboxPath,
        fetchResult.messages.first,
        fetchFullBody: true,
      );
    } catch (e) {
      _logger.e('Error fetching message: $e');
      return null;
    }
  }

  /// Mark email as read/unread on server.
  Future<void> setReadStatus(
    EmailAccount account,
    String mailboxPath,
    int uid, {
    required bool isRead,
  }) async {
    await connect(account);

    await _client!.selectMailboxByPath(mailboxPath);
    final sequence = MessageSequence.fromId(uid, isUid: true);

    if (isRead) {
      await _client!.uidStore(sequence, [MessageFlags.seen]);
    } else {
      await _client!
          .uidStore(sequence, [MessageFlags.seen], action: StoreAction.remove);
    }
  }

  /// Mark email as starred/flagged on server.
  Future<void> setStarredStatus(
    EmailAccount account,
    String mailboxPath,
    int uid, {
    required bool isStarred,
  }) async {
    await connect(account);

    await _client!.selectMailboxByPath(mailboxPath);
    final sequence = MessageSequence.fromId(uid, isUid: true);

    if (isStarred) {
      await _client!.uidStore(sequence, [MessageFlags.flagged]);
    } else {
      await _client!.uidStore(
        sequence,
        [MessageFlags.flagged],
        action: StoreAction.remove,
      );
    }
  }

  /// Move email to another mailbox.
  Future<void> moveEmail(
    EmailAccount account,
    String sourceMailbox,
    String targetMailbox,
    int uid,
  ) async {
    await connect(account);

    await _client!.selectMailboxByPath(sourceMailbox);
    final sequence = MessageSequence.fromId(uid, isUid: true);

    // Get target mailbox object
    final targetMb = await _client!.selectMailboxByPath(targetMailbox);
    await _client!.selectMailboxByPath(sourceMailbox);
    await _client!.uidMove(sequence, targetMailbox: targetMb);
  }

  /// Create a mailbox/folder on the server.
  Future<void> createMailbox(EmailAccount account, String mailboxPath) async {
    await connect(account);

    try {
      // ImapClient provides mailbox creation; create if not exists
      final mailboxes = await _client!.listMailboxes();
      final exists = mailboxes.any((mb) => mb.path == mailboxPath || mb.name == mailboxPath);
      if (!exists) {
        await _client!.createMailbox(mailboxPath);
      }
    } catch (e) {
      _logger.e('Failed to create mailbox $mailboxPath: $e');
      rethrow;
    }
  }

  /// Delete email (move to trash or permanent delete).
  Future<void> deleteEmail(
    EmailAccount account,
    String mailboxPath,
    int uid, {
    bool permanent = false,
  }) async {
    await connect(account);

    await _client!.selectMailboxByPath(mailboxPath);
    final sequence = MessageSequence.fromId(uid, isUid: true);

    if (permanent) {
      await _client!.uidStore(sequence, [MessageFlags.deleted]);
      await _client!.expunge();
    } else {
      // Try to find trash folder
      final mailboxes = await _client!.listMailboxes();
      final trashMailbox = mailboxes.firstWhere(
        (mb) =>
            mb.flags.contains(MailboxFlag.trash) ||
            mb.path.toLowerCase().contains('trash'),
        orElse: () => throw Exception('No trash folder found'),
      );

      await _client!.uidMove(sequence, targetMailbox: trashMailbox);
    }
  }

  /// Parse a MimeMessage into our domain model.
  EmailMessageModel? _parseMessage(
    String accountId,
    String mailboxPath,
    MimeMessage message, {
    bool fetchFullBody = false,
  }) {
    try {
      final fromAddress = message.from?.first;

      if (fromAddress == null) {
        _logger.w('Message has no from address, skipping');
        return null;
      }

      final flags = message.flags ?? [];
      final isRead = flags.contains(MessageFlags.seen);
      final isStarred = flags.contains(MessageFlags.flagged);
      final isDraft = flags.contains(MessageFlags.draft);

      // Get body content
      String? textBody;
      String? htmlBody;

      if (fetchFullBody) {
        // Try to decode HTML part first
        htmlBody = message.decodeTextHtmlPart();

        // Try to decode plain text part
        textBody = message.decodeTextPlainPart();

        // If both are null, try to get the raw body text
        if (htmlBody == null && textBody == null) {
          // Try getting body from the message directly
          final bodyText = message.decodeContentText();
          if (bodyText != null && bodyText.isNotEmpty) {
            // Check if it looks like HTML
            if (bodyText.contains('<html') ||
                bodyText.contains('<body') ||
                bodyText.contains('<div')) {
              htmlBody = bodyText;
            } else {
              textBody = bodyText;
            }
          }
        }

        _logger.d(
          'Parsed body - HTML: ${htmlBody?.length ?? 0} chars, Text: ${textBody?.length ?? 0} chars',
        );
      } else {
        // Just get a preview
        final plainText =
            message.decodeTextPlainPart() ?? message.decodeContentText();
        if (plainText != null && plainText.isNotEmpty) {
          textBody =
              plainText.length > 200 ? plainText.substring(0, 200) : plainText;
        }
      }

      // Check for attachments by looking at content info
      final hasAttachments = message.findContentInfo().any(
            (info) => info.fileName?.isNotEmpty ?? false,
          );

      return EmailMessageModel(
        id: _uuid.v4(),
        accountId: accountId,
        uid: message.uid ?? 0,
        mailboxName: mailboxPath,
        from: EmailAddress(
          address: fromAddress.email,
          displayName: fromAddress.personalName,
        ),
        to: message.to
                ?.map(
                  (addr) => EmailAddress(
                    address: addr.email,
                    displayName: addr.personalName,
                  ),
                )
                .toList() ??
            [],
        cc: message.cc
                ?.map(
                  (addr) => EmailAddress(
                    address: addr.email,
                    displayName: addr.personalName,
                  ),
                )
                .toList() ??
            [],
        subject: message.decodeSubject() ?? '(No Subject)',
        textBody: textBody,
        htmlBody: htmlBody,
        date: message.decodeDate() ?? DateTime.now(),
        isRead: isRead,
        isStarred: isStarred,
        isDraft: isDraft,
        hasAttachments: hasAttachments,
        messageId: message.getHeaderValue('message-id'),
        inReplyTo: message.getHeaderValue('in-reply-to'),
        references: message
                .getHeaderValue('references')
                ?.split(RegExp(r'\s+'))
                .where((s) => s.isNotEmpty)
                .toList() ??
            [],
        syncedAt: DateTime.now(),
        // Capture the raw MIME payload when we did a full fetch. Prefer
        // any raw/source bytes the `MimeMessage` object may expose (different
        // versions of the MIME parser expose different fields). Use a best-effort
        // extractor and fall back to `toString()` when nothing else is available.
        rawSource: fetchFullBody
            ? (_extractRawSource(message) ?? Uint8List.fromList(utf8.encode(message.toString())))
            : null,
      );
    } catch (e) {
      _logger.e('Error parsing message: $e');
      return null;
    }
  }

  /// Best-effort extractor for any raw/source content on `MimeMessage`.
  ///
  /// Some MIME parsers attach the original raw bytes/string under different
  /// property names; attempt a small set of commonly used ones and return the
  /// first non-null value as a `String`. If a candidate is a `List<int>` it
  /// will be decoded as UTF-8.
  Uint8List? _extractRawSource(MimeMessage message) {
    final dynamic m = message;
    final candidates = <String>[
      'raw',
      'rawMessage',
      'original',
      'source',
      'message',
      'data',
      'fullText',
    ];

    for (final name in candidates) {
      try {
        final value = (m as dynamic)[name];
        if (value == null) continue;
        if (value is Uint8List) return value;
        if (value is List<int>) return Uint8List.fromList(value);
        if (value is Iterable<int>) return Uint8List.fromList(value.toList());
        if (value is String) return Uint8List.fromList(utf8.encode(value));
      } catch (_) {
        // ignore and try next
      }
    }

    // Some implementations expose a `raw` getter method instead of an indexable field
    try {
      final dynamic maybe = m.raw;
      if (maybe != null) {
        if (maybe is Uint8List) return maybe;
        if (maybe is List<int>) return Uint8List.fromList(maybe);
        if (maybe is Iterable<int>) return Uint8List.fromList(maybe.toList());
        if (maybe is String) return Uint8List.fromList(utf8.encode(maybe));
      }
    } catch (_) {}

    return null;
  }
}
