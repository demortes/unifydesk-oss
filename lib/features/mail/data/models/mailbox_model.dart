import 'dart:convert';

import '../../../../core/database/tables/mailboxes_table.dart';
import '../../domain/entities/mailbox.dart';

/// Data model for mailboxes with database serialization.
class MailboxModel extends Mailbox {
  const MailboxModel({
    required super.accountId,
    required super.name,
    required super.path,
    super.delimiter = '/',
    super.flags = const [],
    super.totalMessages = 0,
    super.unreadMessages = 0,
    super.isSelectable = true,
    super.isSubscribed = true,
  });

  /// Create from database map.
  factory MailboxModel.fromMap(Map<String, dynamic> map) {
    return MailboxModel(
      accountId: map[MailboxesTable.colAccountId] as String,
      name: map[MailboxesTable.colName] as String,
      path: map[MailboxesTable.colPath] as String,
      delimiter: map[MailboxesTable.colDelimiter] as String? ?? '/',
      flags: _parseStringList(map[MailboxesTable.colFlags] as String?),
      totalMessages: map[MailboxesTable.colTotalMessages] as int? ?? 0,
      unreadMessages: map[MailboxesTable.colUnreadMessages] as int? ?? 0,
      isSelectable: (map[MailboxesTable.colIsSelectable] as int?) == 1,
      isSubscribed: (map[MailboxesTable.colIsSubscribed] as int?) == 1,
    );
  }

  /// Create from domain entity.
  factory MailboxModel.fromEntity(Mailbox entity) {
    return MailboxModel(
      accountId: entity.accountId,
      name: entity.name,
      path: entity.path,
      delimiter: entity.delimiter,
      flags: entity.flags,
      totalMessages: entity.totalMessages,
      unreadMessages: entity.unreadMessages,
      isSelectable: entity.isSelectable,
      isSubscribed: entity.isSubscribed,
    );
  }

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      MailboxesTable.colAccountId: accountId,
      MailboxesTable.colName: name,
      MailboxesTable.colPath: path,
      MailboxesTable.colDelimiter: delimiter,
      MailboxesTable.colFlags: jsonEncode(flags),
      MailboxesTable.colTotalMessages: totalMessages,
      MailboxesTable.colUnreadMessages: unreadMessages,
      MailboxesTable.colIsSelectable: isSelectable ? 1 : 0,
      MailboxesTable.colIsSubscribed: isSubscribed ? 1 : 0,
      MailboxesTable.colSyncedAt: DateTime.now().millisecondsSinceEpoch,
    };
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
}
