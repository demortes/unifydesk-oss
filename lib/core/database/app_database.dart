import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'tables/email_accounts_table.dart';
import 'tables/emails_table.dart';
import 'tables/mailboxes_table.dart';

/// Application database manager using SQLite.
///
/// Handles database initialization, migrations, and provides access
/// to the underlying database instance.
class AppDatabase {
  AppDatabase._();

  static AppDatabase? _instance;
  static Database? _database;

  /// Singleton instance of the database manager.
  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  /// Current database version for migrations.
  static const int _version = 2;

  /// Database file name.
  static const String _databaseName = 'unifydesk.db';

  /// Get the database instance, initializing if necessary.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the database.
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = '${documentsDirectory.path}/$_databaseName';

    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Configure the database connection.
  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Create database tables on first run.
  Future<void> _onCreate(Database db, int version) async {
    await EmailAccountsTable.create(db);
    await MailboxesTable.create(db);
    await EmailsTable.create(db);
  }

  /// Handle database migrations.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await MailboxesTable.create(db);
      await EmailsTable.create(db);
    }
  }

  /// Close the database connection.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Delete the database file. Use with caution!
  Future<void> deleteDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = '${documentsDirectory.path}/$_databaseName';

    await close();
    await databaseFactory.deleteDatabase(path);
  }
}
