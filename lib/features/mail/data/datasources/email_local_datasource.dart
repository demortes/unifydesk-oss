import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/emails_table.dart';
import '../../../../core/database/tables/mailboxes_table.dart';
import '../models/email_message_model.dart';
import '../models/mailbox_model.dart';

/// Local data source for email operations.
class EmailLocalDataSource {
  EmailLocalDataSource({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  // ============ Email Operations ============

  /// Get emails for a specific mailbox.
  Future<List<EmailMessageModel>> getEmailsByMailbox(
    String accountId,
    String mailboxName, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _database.database;
    final results = await db.query(
      EmailsTable.tableName,
      where:
          '${EmailsTable.colAccountId} = ? AND ${EmailsTable.colMailboxName} = ?',
      whereArgs: [accountId, mailboxName],
      orderBy: '${EmailsTable.colDate} DESC',
      limit: limit,
      offset: offset,
    );
    return results.map(EmailMessageModel.fromMap).toList();
  }

  /// Get all emails for an account.
  Future<List<EmailMessageModel>> getEmailsByAccount(
    String accountId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _database.database;
    final results = await db.query(
      EmailsTable.tableName,
      where: '${EmailsTable.colAccountId} = ?',
      whereArgs: [accountId],
      orderBy: '${EmailsTable.colDate} DESC',
      limit: limit,
      offset: offset,
    );
    return results.map(EmailMessageModel.fromMap).toList();
  }

  /// Get unread emails count for a mailbox.
  Future<int> getUnreadCount(String accountId, String mailboxName) async {
    final db = await _database.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM ${EmailsTable.tableName}
      WHERE ${EmailsTable.colAccountId} = ?
        AND ${EmailsTable.colMailboxName} = ?
        AND ${EmailsTable.colIsRead} = 0
      ''',
      [accountId, mailboxName],
    );
    return result.first['count'] as int? ?? 0;
  }

  /// Get a single email by ID.
  Future<EmailMessageModel?> getEmailById(String id) async {
    final db = await _database.database;
    final results = await db.query(
      EmailsTable.tableName,
      where: '${EmailsTable.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return EmailMessageModel.fromMap(results.first);
  }

  /// Get the highest UID for a mailbox (for incremental sync).
  Future<int> getHighestUid(String accountId, String mailboxName) async {
    final db = await _database.database;
    final result = await db.rawQuery(
      '''
      SELECT MAX(${EmailsTable.colUid}) as max_uid FROM ${EmailsTable.tableName}
      WHERE ${EmailsTable.colAccountId} = ?
        AND ${EmailsTable.colMailboxName} = ?
      ''',
      [accountId, mailboxName],
    );
    return result.first['max_uid'] as int? ?? 0;
  }

  /// Insert or update an email.
  Future<void> upsertEmail(EmailMessageModel email) async {
    final db = await _database.database;
    await db.insert(
      EmailsTable.tableName,
      email.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert or update multiple emails.
  Future<void> upsertEmails(List<EmailMessageModel> emails) async {
    if (emails.isEmpty) return;

    final db = await _database.database;
    final batch = db.batch();

    for (final email in emails) {
      batch.insert(
        EmailsTable.tableName,
        email.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Update email read status.
  Future<void> updateReadStatus(String id, {required bool isRead}) async {
    final db = await _database.database;
    await db.update(
      EmailsTable.tableName,
      {EmailsTable.colIsRead: isRead ? 1 : 0},
      where: '${EmailsTable.colId} = ?',
      whereArgs: [id],
    );
  }

  /// Update email starred status.
  Future<void> updateStarredStatus(String id, {required bool isStarred}) async {
    final db = await _database.database;
    await db.update(
      EmailsTable.tableName,
      {EmailsTable.colIsStarred: isStarred ? 1 : 0},
      where: '${EmailsTable.colId} = ?',
      whereArgs: [id],
    );
  }

  /// Delete an email.
  Future<void> deleteEmail(String id) async {
    final db = await _database.database;
    await db.delete(
      EmailsTable.tableName,
      where: '${EmailsTable.colId} = ?',
      whereArgs: [id],
    );
  }

  /// Delete emails by UIDs (for sync).
  Future<void> deleteEmailsByUids(
    String accountId,
    String mailboxName,
    List<int> uids,
  ) async {
    if (uids.isEmpty) return;

    final db = await _database.database;
    final placeholders = List.filled(uids.length, '?').join(',');
    await db.delete(
      EmailsTable.tableName,
      where: '''
        ${EmailsTable.colAccountId} = ?
        AND ${EmailsTable.colMailboxName} = ?
        AND ${EmailsTable.colUid} IN ($placeholders)
      ''',
      whereArgs: [accountId, mailboxName, ...uids],
    );
  }

  // ============ Mailbox Operations ============

  /// Get all mailboxes for an account.
  Future<List<MailboxModel>> getMailboxes(String accountId) async {
    final db = await _database.database;
    final results = await db.query(
      MailboxesTable.tableName,
      where: '${MailboxesTable.colAccountId} = ?',
      whereArgs: [accountId],
      orderBy: '${MailboxesTable.colPath} ASC',
    );
    return results.map(MailboxModel.fromMap).toList();
  }

  /// Get a single mailbox.
  Future<MailboxModel?> getMailbox(String accountId, String path) async {
    final db = await _database.database;
    final results = await db.query(
      MailboxesTable.tableName,
      where:
          '${MailboxesTable.colAccountId} = ? AND ${MailboxesTable.colPath} = ?',
      whereArgs: [accountId, path],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return MailboxModel.fromMap(results.first);
  }

  /// Insert or update a mailbox.
  Future<void> upsertMailbox(MailboxModel mailbox) async {
    final db = await _database.database;
    await db.insert(
      MailboxesTable.tableName,
      mailbox.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert or update multiple mailboxes.
  Future<void> upsertMailboxes(List<MailboxModel> mailboxes) async {
    if (mailboxes.isEmpty) return;

    final db = await _database.database;
    final batch = db.batch();

    for (final mailbox in mailboxes) {
      batch.insert(
        MailboxesTable.tableName,
        mailbox.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Update mailbox message counts.
  Future<void> updateMailboxCounts(
    String accountId,
    String path, {
    required int totalMessages,
    required int unreadMessages,
  }) async {
    final db = await _database.database;
    await db.update(
      MailboxesTable.tableName,
      {
        MailboxesTable.colTotalMessages: totalMessages,
        MailboxesTable.colUnreadMessages: unreadMessages,
        MailboxesTable.colSyncedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where:
          '${MailboxesTable.colAccountId} = ? AND ${MailboxesTable.colPath} = ?',
      whereArgs: [accountId, path],
    );
  }

  /// Delete mailboxes that no longer exist on server.
  Future<void> deleteMailboxesNotIn(
    String accountId,
    List<String> paths,
  ) async {
    if (paths.isEmpty) return;

    final db = await _database.database;
    final placeholders = List.filled(paths.length, '?').join(',');
    await db.delete(
      MailboxesTable.tableName,
      where: '''
        ${MailboxesTable.colAccountId} = ?
        AND ${MailboxesTable.colPath} NOT IN ($placeholders)
      ''',
      whereArgs: [accountId, ...paths],
    );
  }
}
