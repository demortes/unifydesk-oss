import 'dart:typed_data';

import 'package:intl/intl.dart';

import '../../domain/entities/email_account.dart';
import '../../domain/entities/email_attachment.dart';
import '../../domain/entities/email_message.dart';
import '../../domain/entities/mailbox.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/repositories/email_repository.dart';
import '../datasources/email_local_datasource.dart';
import '../datasources/imap_remote_datasource.dart';
import '../services/attachment_extractor.dart';

/// Implementation of EmailRepository.
class EmailRepositoryImpl implements EmailRepository {
  EmailRepositoryImpl({
    required AccountRepository accountRepository,
    EmailLocalDataSource? localDataSource,
    ImapRemoteDataSource? remoteDataSource,
  })  : _accountRepository = accountRepository,
        _localDataSource = localDataSource ?? EmailLocalDataSource(),
        _remoteDataSource = remoteDataSource ?? ImapRemoteDataSource();

  final AccountRepository _accountRepository;
  final EmailLocalDataSource _localDataSource;
  final ImapRemoteDataSource _remoteDataSource;

  Future<EmailAccount> _getAccount(String accountId) async {
    final account = await _accountRepository.getAccount(accountId);
    if (account == null) {
      throw Exception('Account not found: $accountId');
    }
    return account;
  }

  @override
  Future<List<Mailbox>> syncMailboxes(String accountId) async {
    final account = await _getAccount(accountId);
    final remoteMailboxes = await _remoteDataSource.fetchMailboxes(account);

    // Save to local database
    await _localDataSource.upsertMailboxes(remoteMailboxes);

    // Remove mailboxes that no longer exist on server
    await _localDataSource.deleteMailboxesNotIn(
      accountId,
      remoteMailboxes.map((m) => m.path).toList(),
    );

    // Update message counts
    for (final mailbox in remoteMailboxes) {
      if (mailbox.isSelectable) {
        try {
          final status = await _remoteDataSource.fetchMailboxStatus(
            account,
            mailbox.path,
          );
          await _localDataSource.updateMailboxCounts(
            accountId,
            mailbox.path,
            totalMessages: status.total,
            unreadMessages: status.unread,
          );
        } catch (_) {
          // Ignore errors for individual mailboxes
        }
      }
    }

    return getMailboxes(accountId);
  }

  @override
  Future<List<Mailbox>> getMailboxes(String accountId) async {
    final mailboxes = await _localDataSource.getMailboxes(accountId);
    return mailboxes;
  }

  @override
  Future<List<EmailMessage>> syncEmails(
    String accountId,
    String mailboxPath, {
    bool fullSync = false,
  }) async {
    final account = await _getAccount(accountId);

    // Get highest UID we have locally for incremental sync
    int? sinceUid;
    if (!fullSync) {
      sinceUid = await _localDataSource.getHighestUid(accountId, mailboxPath);
    }

    // Fetch from server
    final remoteEmails = await _remoteDataSource.fetchEmails(
      account,
      mailboxPath,
      sinceUid: fullSync ? null : sinceUid,
      limit: fullSync ? 100 : 50,
    );

    // Save to local database
    if (remoteEmails.isNotEmpty) {
      await _localDataSource.upsertEmails(remoteEmails);
    }

    // Update mailbox counts
    try {
      final status = await _remoteDataSource.fetchMailboxStatus(
        account,
        mailboxPath,
      );
      await _localDataSource.updateMailboxCounts(
        accountId,
        mailboxPath,
        totalMessages: status.total,
        unreadMessages: status.unread,
      );
    } catch (_) {
      // Ignore count update errors
    }

    return getEmails(accountId, mailboxPath);
  }

  @override
  Future<List<EmailMessage>> getEmails(
    String accountId,
    String mailboxPath, {
    int limit = 50,
    int offset = 0,
  }) async {
    return _localDataSource.getEmailsByMailbox(
      accountId,
      mailboxPath,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<EmailMessage?> getEmailById(String id) async {
    return _localDataSource.getEmailById(id);
  }

  @override
  Future<EmailMessage?> fetchFullEmail(
    String accountId,
    String mailboxPath,
    int uid,
  ) async {
    final account = await _getAccount(accountId);
    final email = await _remoteDataSource.fetchEmail(
      account,
      mailboxPath,
      uid,
    );

    if (email != null) {
      await _localDataSource.upsertEmail(email);

      // Parse and persist attachment metadata from raw source
      if (email.hasAttachments && email.rawSource != null) {
        final attachments = AttachmentExtractor.parseAttachmentMetadata(
          email.id,
          email.rawSource!,
        );
        if (attachments.isNotEmpty) {
          // Clear old attachments and insert fresh ones
          await _localDataSource.deleteAttachmentsByEmailId(email.id);
          await _localDataSource.upsertAttachments(attachments);
        }
      }
    }

    return email;
  }

  @override
  Future<void> setReadStatus(
    String accountId,
    String mailboxPath,
    String emailId,
    int uid, {
    required bool isRead,
  }) async {
    // Update locally first for responsiveness
    await _localDataSource.updateReadStatus(emailId, isRead: isRead);

    // Then sync to server
    final account = await _getAccount(accountId);
    await _remoteDataSource.setReadStatus(
      account,
      mailboxPath,
      uid,
      isRead: isRead,
    );
  }

  @override
  Future<void> setStarredStatus(
    String accountId,
    String mailboxPath,
    String emailId,
    int uid, {
    required bool isStarred,
  }) async {
    // Update locally first
    await _localDataSource.updateStarredStatus(emailId, isStarred: isStarred);

    // Then sync to server
    final account = await _getAccount(accountId);
    await _remoteDataSource.setStarredStatus(
      account,
      mailboxPath,
      uid,
      isStarred: isStarred,
    );
  }

  @override
  Future<void> moveEmail(
    String accountId,
    String sourceMailbox,
    String targetMailbox,
    String emailId,
    int uid,
  ) async {
    final account = await _getAccount(accountId);

    // Move on server
    await _remoteDataSource.moveEmail(
      account,
      sourceMailbox,
      targetMailbox,
      uid,
    );

    // Delete locally (will be re-synced in new location)
    await _localDataSource.deleteEmail(emailId);
  }

  @override
  Future<void> createMailbox(String accountId, String mailboxPath) async {
    final account = await _getAccount(accountId);
    // Try a set of name variants to accommodate localization and server naming
    final locale = Intl.getCurrentLocale();
    final lang = locale.split('_').first.toLowerCase();

    final Map<String, String> localePreferred = {
      'en': 'Archive',
      'es': 'Archivo',
      'fr': 'Archive',
      'de': 'Archiv',
      'it': 'Archivio',
      'pt': 'Arquivo',
      'nl': 'Archief',
      'sv': 'Arkiv',
      'fi': 'Arkisto',
      'ru': 'Архив',
      'uk': 'Архів',
      'tr': 'Arşiv',
    };

    final defaultCandidates = [
      localePreferred[lang] ?? 'Archive',
      'Archive',
      'Archives',
      'Archived',
      'Archiv',
      'Archief',
      'Archivo',
      'Archivio',
      'Arquivo',
      'Arkiv',
      'Arkisto',
      'Архив',
      'Архів',
      'Arşiv',
    ];

    // Attempt to create each candidate until one succeeds
    for (final candidate in defaultCandidates) {
      try {
        await _remoteDataSource.createMailbox(account, candidate);
        // Refresh local mailbox list after successful creation
        await syncMailboxes(accountId);
        return;
      } catch (_) {
        // Ignore and try next candidate
      }
    }

    // If all attempts failed, still refresh mailboxes to pick up any server-side changes
    try {
      await syncMailboxes(accountId);
    } catch (_) {
      // ignore
    }
  }

  @override
  Future<void> deleteEmail(
    String accountId,
    String mailboxPath,
    String emailId,
    int uid, {
    bool permanent = false,
  }) async {
    final account = await _getAccount(accountId);

    // Delete on server
    await _remoteDataSource.deleteEmail(
      account,
      mailboxPath,
      uid,
      permanent: permanent,
    );

    // Delete locally
    await _localDataSource.deleteEmail(emailId);
  }

  @override
  Future<List<EmailAttachment>> getAttachments(String emailId) async {
    final models = await _localDataSource.getAttachmentsByEmailId(emailId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Uint8List?> getAttachmentData(
    String emailId,
    String attachmentId,
  ) async {
    // Get the attachment record for partIndex
    final attachments = await _localDataSource.getAttachmentsByEmailId(emailId);
    final attachment = attachments.where((a) => a.id == attachmentId).firstOrNull;
    if (attachment == null) return null;

    // Get the email for rawSource
    final email = await _localDataSource.getEmailById(emailId);
    if (email == null || email.rawSource == null) return null;

    // Extract binary data from raw MIME source
    return AttachmentExtractor.extractAttachmentData(
      email.rawSource!,
      attachment.partIndex,
    );
  }

  @override
  Future<int> getUnreadCount(String accountId, String mailboxPath) async {
    return _localDataSource.getUnreadCount(accountId, mailboxPath);
  }

  @override
  Future<void> disconnect() async {
    await _remoteDataSource.disconnect();
  }
}
