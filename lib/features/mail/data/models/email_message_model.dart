import 'dart:convert';

import '../../../../core/database/tables/emails_table.dart';
import '../../domain/entities/email_message.dart';

/// Data model for email messages with database serialization.
class EmailMessageModel extends EmailMessage {
  const EmailMessageModel({
    required super.id,
    required super.accountId,
    required super.uid,
    required super.mailboxName,
    required super.from,
    required super.subject,
    required super.date,
    super.to = const [],
    super.cc = const [],
    super.bcc = const [],
    super.textBody,
    super.htmlBody,
    super.isRead = false,
    super.isStarred = false,
    super.isDraft = false,
    super.hasAttachments = false,
    super.messageId,
    super.inReplyTo,
    super.references = const [],
    super.syncedAt,
  });

  /// Create from database map.
  factory EmailMessageModel.fromMap(Map<String, dynamic> map) {
    return EmailMessageModel(
      id: map[EmailsTable.colId] as String,
      accountId: map[EmailsTable.colAccountId] as String,
      uid: map[EmailsTable.colUid] as int,
      mailboxName: map[EmailsTable.colMailboxName] as String,
      from: EmailAddress(
        address: map[EmailsTable.colFromAddress] as String,
        displayName: map[EmailsTable.colFromName] as String?,
      ),
      to: _parseAddressList(map[EmailsTable.colToAddresses] as String?),
      cc: _parseAddressList(map[EmailsTable.colCcAddresses] as String?),
      bcc: _parseAddressList(map[EmailsTable.colBccAddresses] as String?),
      subject: map[EmailsTable.colSubject] as String? ?? '',
      textBody: map[EmailsTable.colTextBody] as String?,
      htmlBody: map[EmailsTable.colHtmlBody] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(
        map[EmailsTable.colDate] as int,
      ),
      isRead: (map[EmailsTable.colIsRead] as int) == 1,
      isStarred: (map[EmailsTable.colIsStarred] as int) == 1,
      isDraft: (map[EmailsTable.colIsDraft] as int) == 1,
      hasAttachments: (map[EmailsTable.colHasAttachments] as int) == 1,
      messageId: map[EmailsTable.colMessageId] as String?,
      inReplyTo: map[EmailsTable.colInReplyTo] as String?,
      references: _parseStringList(map[EmailsTable.colReferences] as String?),
      syncedAt: map[EmailsTable.colSyncedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[EmailsTable.colSyncedAt] as int,
            )
          : null,
    );
  }

  /// Create from domain entity.
  factory EmailMessageModel.fromEntity(EmailMessage entity) {
    return EmailMessageModel(
      id: entity.id,
      accountId: entity.accountId,
      uid: entity.uid,
      mailboxName: entity.mailboxName,
      from: entity.from,
      to: entity.to,
      cc: entity.cc,
      bcc: entity.bcc,
      subject: entity.subject,
      textBody: entity.textBody,
      htmlBody: entity.htmlBody,
      date: entity.date,
      isRead: entity.isRead,
      isStarred: entity.isStarred,
      isDraft: entity.isDraft,
      hasAttachments: entity.hasAttachments,
      messageId: entity.messageId,
      inReplyTo: entity.inReplyTo,
      references: entity.references,
      syncedAt: entity.syncedAt,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      EmailsTable.colId: id,
      EmailsTable.colAccountId: accountId,
      EmailsTable.colUid: uid,
      EmailsTable.colMailboxName: mailboxName,
      EmailsTable.colFromAddress: from.address,
      EmailsTable.colFromName: from.displayName,
      EmailsTable.colToAddresses: _encodeAddressList(to),
      EmailsTable.colCcAddresses: _encodeAddressList(cc),
      EmailsTable.colBccAddresses: _encodeAddressList(bcc),
      EmailsTable.colSubject: subject,
      EmailsTable.colTextBody: textBody,
      EmailsTable.colHtmlBody: htmlBody,
      EmailsTable.colDate: date.millisecondsSinceEpoch,
      EmailsTable.colIsRead: isRead ? 1 : 0,
      EmailsTable.colIsStarred: isStarred ? 1 : 0,
      EmailsTable.colIsDraft: isDraft ? 1 : 0,
      EmailsTable.colHasAttachments: hasAttachments ? 1 : 0,
      EmailsTable.colMessageId: messageId,
      EmailsTable.colInReplyTo: inReplyTo,
      EmailsTable.colReferences: jsonEncode(references),
      EmailsTable.colSyncedAt: syncedAt?.millisecondsSinceEpoch,
    };
  }

  static List<EmailAddress> _parseAddressList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((item) {
        if (item is Map<String, dynamic>) {
          return EmailAddress(
            address: item['address'] as String? ?? '',
            displayName: item['name'] as String?,
          );
        }
        return EmailAddress(address: item.toString());
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static List<String> _parseStringList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  static String _encodeAddressList(List<EmailAddress> addresses) {
    return jsonEncode(
      addresses
          .map((a) => {
                'address': a.address,
                'name': a.displayName,
              })
          .toList(),
    );
  }
}
