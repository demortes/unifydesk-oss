import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/email_accounts_table.dart';
import '../models/email_account_model.dart';

/// Local data source for email account database operations.
class AccountLocalDatasource {
  AccountLocalDatasource({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  /// Get all accounts from the database.
  Future<List<EmailAccountModel>> getAllAccounts() async {
    final db = await _database.database;
    final maps = await db.query(
      EmailAccountsTable.tableName,
      orderBy: '${EmailAccountsTable.columnCreatedAt} ASC',
    );
    return maps.map(EmailAccountModel.fromMap).toList();
  }

  /// Get a single account by ID.
  Future<EmailAccountModel?> getAccount(String id) async {
    final db = await _database.database;
    final maps = await db.query(
      EmailAccountsTable.tableName,
      where: '${EmailAccountsTable.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return EmailAccountModel.fromMap(maps.first);
  }

  /// Get an account by email address.
  Future<EmailAccountModel?> getAccountByEmail(String email) async {
    final db = await _database.database;
    final maps = await db.query(
      EmailAccountsTable.tableName,
      where: '${EmailAccountsTable.columnEmail} = ?',
      whereArgs: [email.toLowerCase()],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return EmailAccountModel.fromMap(maps.first);
  }

  /// Insert a new account.
  Future<void> insertAccount(EmailAccountModel account) async {
    final db = await _database.database;
    await db.insert(
      EmailAccountsTable.tableName,
      account.toMap(),
    );
  }

  /// Update an existing account.
  Future<void> updateAccount(EmailAccountModel account) async {
    final db = await _database.database;
    await db.update(
      EmailAccountsTable.tableName,
      account.toMap(),
      where: '${EmailAccountsTable.columnId} = ?',
      whereArgs: [account.id],
    );
  }

  /// Delete an account by ID.
  Future<void> deleteAccount(String id) async {
    final db = await _database.database;
    await db.delete(
      EmailAccountsTable.tableName,
      where: '${EmailAccountsTable.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// Check if any accounts exist.
  Future<bool> hasAccounts() async {
    final count = await getAccountCount();
    return count > 0;
  }

  /// Get the number of accounts.
  Future<int> getAccountCount() async {
    final db = await _database.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${EmailAccountsTable.tableName}',
    );
    return result.first['count'] as int? ?? 0;
  }
}
