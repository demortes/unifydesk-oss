import 'package:sqflite/sqflite.dart';

/// Database table definition for email messages.
class EmailsTable {
  EmailsTable._();

  static const String tableName = 'emails';

  // Column names
  static const String colId = 'id';
  static const String colAccountId = 'account_id';
  static const String colUid = 'uid';
  static const String colMailboxName = 'mailbox_name';
  static const String colFromAddress = 'from_address';
  static const String colFromName = 'from_name';
  static const String colToAddresses = 'to_addresses'; // JSON array
  static const String colCcAddresses = 'cc_addresses'; // JSON array
  static const String colBccAddresses = 'bcc_addresses'; // JSON array
  static const String colSubject = 'subject';
  static const String colTextBody = 'text_body';
  static const String colHtmlBody = 'html_body';
  static const String colDate = 'date';
  static const String colIsRead = 'is_read';
  static const String colIsStarred = 'is_starred';
  static const String colIsDraft = 'is_draft';
  static const String colHasAttachments = 'has_attachments';
  static const String colMessageId = 'message_id';
  static const String colInReplyTo = 'in_reply_to';
  static const String colReferences = 'email_references'; // JSON array
  static const String colSyncedAt = 'synced_at';

  /// Create the emails table.
  static Future<void> create(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        $colId TEXT PRIMARY KEY,
        $colAccountId TEXT NOT NULL,
        $colUid INTEGER NOT NULL,
        $colMailboxName TEXT NOT NULL,
        $colFromAddress TEXT NOT NULL,
        $colFromName TEXT,
        $colToAddresses TEXT DEFAULT '[]',
        $colCcAddresses TEXT DEFAULT '[]',
        $colBccAddresses TEXT DEFAULT '[]',
        $colSubject TEXT NOT NULL DEFAULT '',
        $colTextBody TEXT,
        $colHtmlBody TEXT,
        $colDate INTEGER NOT NULL,
        $colIsRead INTEGER NOT NULL DEFAULT 0,
        $colIsStarred INTEGER NOT NULL DEFAULT 0,
        $colIsDraft INTEGER NOT NULL DEFAULT 0,
        $colHasAttachments INTEGER NOT NULL DEFAULT 0,
        $colMessageId TEXT,
        $colInReplyTo TEXT,
        $colReferences TEXT DEFAULT '[]',
        $colSyncedAt INTEGER,
        FOREIGN KEY ($colAccountId) REFERENCES email_accounts(id) ON DELETE CASCADE,
        UNIQUE ($colAccountId, $colMailboxName, $colUid)
      )
    ''');

    // Indexes for common queries
    await db.execute('''
      CREATE INDEX idx_emails_account_mailbox
      ON $tableName ($colAccountId, $colMailboxName)
    ''');

    await db.execute('''
      CREATE INDEX idx_emails_date
      ON $tableName ($colDate DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_emails_unread
      ON $tableName ($colAccountId, $colMailboxName, $colIsRead)
    ''');

    await db.execute('''
      CREATE INDEX idx_emails_message_id
      ON $tableName ($colMessageId)
    ''');
  }
}
