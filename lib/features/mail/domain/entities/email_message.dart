import 'package:equatable/equatable.dart';

/// Represents an email address with optional display name.
class EmailAddress extends Equatable {
  const EmailAddress({
    required this.address,
    this.displayName,
  });

  final String address;
  final String? displayName;

  /// Returns display name if available, otherwise the email address.
  String get display => displayName ?? address;

  @override
  List<Object?> get props => [address, displayName];

  @override
  String toString() =>
      displayName != null ? '$displayName <$address>' : address;
}

/// Email message entity representing a single email.
///
/// This is the domain entity - it contains no database or serialization logic.
class EmailMessage extends Equatable {
  const EmailMessage({
    required this.id,
    required this.accountId,
    required this.uid,
    required this.mailboxName,
    required this.from,
    required this.subject,
    required this.date,
    this.to = const [],
    this.cc = const [],
    this.bcc = const [],
    this.textBody,
    this.htmlBody,
    this.isRead = false,
    this.isStarred = false,
    this.isDraft = false,
    this.hasAttachments = false,
    this.messageId,
    this.inReplyTo,
    this.references = const [],
    this.syncedAt,
  });

  /// Local unique identifier.
  final String id;

  /// Account this message belongs to.
  final String accountId;

  /// IMAP UID for this message.
  final int uid;

  /// Mailbox/folder name (e.g., "INBOX", "Sent").
  final String mailboxName;

  /// Sender email address.
  final EmailAddress from;

  /// Recipients.
  final List<EmailAddress> to;

  /// CC recipients.
  final List<EmailAddress> cc;

  /// BCC recipients.
  final List<EmailAddress> bcc;

  /// Email subject.
  final String subject;

  /// Plain text body.
  final String? textBody;

  /// HTML body.
  final String? htmlBody;

  /// Date the email was sent/received.
  final DateTime date;

  /// Whether the email has been read.
  final bool isRead;

  /// Whether the email is starred/flagged.
  final bool isStarred;

  /// Whether this is a draft.
  final bool isDraft;

  /// Whether this email has attachments.
  final bool hasAttachments;

  /// Message-ID header for threading.
  final String? messageId;

  /// In-Reply-To header for threading.
  final String? inReplyTo;

  /// References header for threading.
  final List<String> references;

  /// When this message was last synced from server.
  final DateTime? syncedAt;

  /// Get a preview of the email body (first 100 chars of text).
  String get preview {
    final text = textBody ?? '';
    if (text.isEmpty) return '';
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.length > 100 ? '${cleaned.substring(0, 100)}...' : cleaned;
  }

  /// Create a copy with updated fields.
  EmailMessage copyWith({
    String? id,
    String? accountId,
    int? uid,
    String? mailboxName,
    EmailAddress? from,
    List<EmailAddress>? to,
    List<EmailAddress>? cc,
    List<EmailAddress>? bcc,
    String? subject,
    String? textBody,
    String? htmlBody,
    DateTime? date,
    bool? isRead,
    bool? isStarred,
    bool? isDraft,
    bool? hasAttachments,
    String? messageId,
    String? inReplyTo,
    List<String>? references,
    DateTime? syncedAt,
  }) {
    return EmailMessage(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      uid: uid ?? this.uid,
      mailboxName: mailboxName ?? this.mailboxName,
      from: from ?? this.from,
      to: to ?? this.to,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      subject: subject ?? this.subject,
      textBody: textBody ?? this.textBody,
      htmlBody: htmlBody ?? this.htmlBody,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
      isStarred: isStarred ?? this.isStarred,
      isDraft: isDraft ?? this.isDraft,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      messageId: messageId ?? this.messageId,
      inReplyTo: inReplyTo ?? this.inReplyTo,
      references: references ?? this.references,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        accountId,
        uid,
        mailboxName,
        from,
        to,
        cc,
        bcc,
        subject,
        textBody,
        htmlBody,
        date,
        isRead,
        isStarred,
        isDraft,
        hasAttachments,
        messageId,
        inReplyTo,
        references,
        syncedAt,
      ];
}
