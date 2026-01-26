import '../../../../core/security/secure_storage_service.dart';
import '../../domain/entities/email_account.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_local_datasource.dart';
import '../models/email_account_model.dart';

/// Implementation of [AccountRepository] using local database and secure storage.
class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl({
    AccountLocalDatasource? localDatasource,
    SecureStorageService? secureStorage,
  })  : _localDatasource = localDatasource ?? AccountLocalDatasource(),
        _secureStorage = secureStorage ?? SecureStorageService();

  final AccountLocalDatasource _localDatasource;
  final SecureStorageService _secureStorage;

  @override
  Future<List<EmailAccount>> getAllAccounts() async {
    final models = await _localDatasource.getAllAccounts();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<EmailAccount?> getAccount(String id) async {
    final model = await _localDatasource.getAccount(id);
    return model?.toEntity();
  }

  @override
  Future<EmailAccount?> getAccountByEmail(String email) async {
    final model = await _localDatasource.getAccountByEmail(email);
    return model?.toEntity();
  }

  @override
  Future<void> saveAccountWithPassword(
    EmailAccount account, {
    required String password,
  }) async {
    // Save account to database
    final model = EmailAccountModel.fromEntity(account);
    await _localDatasource.insertAccount(model);

    // Save password to secure storage
    await _secureStorage.savePassword(account.id, password);
  }

  @override
  Future<void> saveAccountWithOAuth(
    EmailAccount account, {
    required OAuthTokens tokens,
  }) async {
    // Save account to database
    final model = EmailAccountModel.fromEntity(account);
    await _localDatasource.insertAccount(model);

    // Save OAuth tokens to secure storage
    await _secureStorage.saveOAuthTokens(
      account.id,
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresAt: tokens.expiresAt,
    );
  }

  @override
  Future<void> updateAccount(EmailAccount account) async {
    final updated = account.copyWith(updatedAt: DateTime.now());
    final model = EmailAccountModel.fromEntity(updated);
    await _localDatasource.updateAccount(model);
  }

  @override
  Future<void> updatePassword(String accountId, String password) async {
    await _secureStorage.savePassword(accountId, password);
  }

  @override
  Future<void> updateOAuthTokens(String accountId, OAuthTokens tokens) async {
    await _secureStorage.saveOAuthTokens(
      accountId,
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresAt: tokens.expiresAt,
    );
  }

  @override
  Future<void> deleteAccount(String id) async {
    // Delete credentials first
    await _secureStorage.deleteAllCredentials(id);

    // Then delete account from database
    await _localDatasource.deleteAccount(id);
  }

  @override
  Future<bool> hasAccounts() async {
    return _localDatasource.hasAccounts();
  }

  @override
  Future<int> getAccountCount() async {
    return _localDatasource.getAccountCount();
  }
}
