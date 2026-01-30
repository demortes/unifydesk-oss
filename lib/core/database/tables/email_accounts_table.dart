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
  static const String columnSignature = 'signature';
  static const String columnReplyTo = 'reply_to';
  static const String columnProviderType = 'provider_type';
  static const String columnAuthType = 'auth_type';
  static const String columnImapHost = 'imap_host';
  static const String columnImapPort = 'imap_port';
  static const String columnSmtpHost = 'smtp_host';
  static const String columnSmtpPort = 'smtp_port';
  static const String columnUseSsl = 'use_ssl';
  static const String columnSyncFrequencyMinutes = 'sync_frequency_minutes';
  static const String columnIsActive = 'is_active';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  /// Create the table.
  static Future<void> create(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        $columnId TEXT PRIMARY KEY,
        $columnEmail TEXT NOT NULL,
        $columnDisplayName TEXT,
        $columnSignature TEXT,
        $columnReplyTo TEXT,
        $columnProviderType TEXT NOT NULL,
        $columnAuthType TEXT NOT NULL,
        $columnImapHost TEXT,
        $columnImapPort INTEGER,
        $columnSmtpHost TEXT,
        $columnSmtpPort INTEGER,
        $columnUseSsl INTEGER DEFAULT 1,
        $columnSyncFrequencyMinutes INTEGER DEFAULT 15,
        $columnIsActive INTEGER DEFAULT 1,
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

  /// Migrate from version 1 to version 2 (add settings columns).
  static Future<void> migrateV1ToV2(Database db) async {
    // Add new columns for settings
    await db.execute(
      'ALTER TABLE $tableName ADD COLUMN $columnSignature TEXT',
    );
    await db.execute(
      'ALTER TABLE $tableName ADD COLUMN $columnReplyTo TEXT',
    );
    await db.execute(
      'ALTER TABLE $tableName ADD COLUMN $columnSyncFrequencyMinutes INTEGER DEFAULT 15',
    );
    await db.execute(
      'ALTER TABLE $tableName ADD COLUMN $columnIsActive INTEGER DEFAULT 1',
    );
  }
}
