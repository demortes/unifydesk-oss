import 'package:sqflite/sqflite.dart';

/// Database table definition for mailboxes/folders.
class MailboxesTable {
  MailboxesTable._();

  static const String tableName = 'mailboxes';

  // Column names
  static const String colAccountId = 'account_id';
  static const String colName = 'name';
  static const String colPath = 'path';
  static const String colDelimiter = 'delimiter';
  static const String colFlags = 'flags'; // JSON array
  static const String colTotalMessages = 'total_messages';
  static const String colUnreadMessages = 'unread_messages';
  static const String colIsSelectable = 'is_selectable';
  static const String colIsSubscribed = 'is_subscribed';
  static const String colSyncedAt = 'synced_at';

  /// Create the mailboxes table.
  static Future<void> create(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        $colAccountId TEXT NOT NULL,
        $colPath TEXT NOT NULL,
        $colName TEXT NOT NULL,
        $colDelimiter TEXT DEFAULT '/',
        $colFlags TEXT DEFAULT '[]',
        $colTotalMessages INTEGER DEFAULT 0,
        $colUnreadMessages INTEGER DEFAULT 0,
        $colIsSelectable INTEGER NOT NULL DEFAULT 1,
        $colIsSubscribed INTEGER NOT NULL DEFAULT 1,
        $colSyncedAt INTEGER,
        PRIMARY KEY ($colAccountId, $colPath),
        FOREIGN KEY ($colAccountId) REFERENCES email_accounts(id) ON DELETE CASCADE
      )
    ''');
  }
}
