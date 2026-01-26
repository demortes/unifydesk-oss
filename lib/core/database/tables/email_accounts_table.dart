import 'package:sqflite/sqflite.dart';

/// Email accounts table schema and operations.
///
/// Note: Credentials (passwords, OAuth tokens) are NOT stored in this table.
/// They are stored separately in secure storage (Keychain/Keystore).
class EmailAccountsTable {
  EmailAccountsTable._();

  /// Table name.
  static const String tableName = 'email_accounts';

  /// Column names.
  static const String columnId = 'id';
  static const String columnEmail = 'email';
  static const String columnDisplayName = 'display_name';
  static const String columnProviderType = 'provider_type';
  static const String columnAuthType = 'auth_type';
  static const String columnImapHost = 'imap_host';
  static const String columnImapPort = 'imap_port';
  static const String columnSmtpHost = 'smtp_host';
  static const String columnSmtpPort = 'smtp_port';
  static const String columnUseSsl = 'use_ssl';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  /// Create the table.
  static Future<void> create(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        $columnId TEXT PRIMARY KEY,
        $columnEmail TEXT NOT NULL,
        $columnDisplayName TEXT,
        $columnProviderType TEXT NOT NULL,
        $columnAuthType TEXT NOT NULL,
        $columnImapHost TEXT,
        $columnImapPort INTEGER,
        $columnSmtpHost TEXT,
        $columnSmtpPort INTEGER,
        $columnUseSsl INTEGER DEFAULT 1,
        $columnCreatedAt INTEGER NOT NULL,
        $columnUpdatedAt INTEGER NOT NULL
      )
    ''');

    // Create index on email for faster lookups
    await db.execute('''
      CREATE INDEX idx_${tableName}_email ON $tableName ($columnEmail)
    ''');
  }

  /// Drop the table.
  static Future<void> drop(Database db) async {
    await db.execute('DROP TABLE IF EXISTS $tableName');
  }
}
