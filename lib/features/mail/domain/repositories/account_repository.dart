import '../../../../core/security/secure_storage_service.dart';
import '../entities/email_account.dart';

/// Repository interface for email account operations.
///
/// This is the domain contract - implementations handle the actual
/// database and secure storage operations.
abstract class AccountRepository {
  /// Get all configured email accounts.
  Future<List<EmailAccount>> getAllAccounts();

  /// Get a specific account by ID.
  Future<EmailAccount?> getAccount(String id);

  /// Get an account by email address.
  Future<EmailAccount?> getAccountByEmail(String email);

  /// Save a new account with password authentication.
  ///
  /// The password is stored securely, not in the database.
  Future<void> saveAccountWithPassword(
    EmailAccount account, {
    required String password,
  });

  /// Save a new account with OAuth authentication.
  ///
  /// OAuth tokens are stored securely, not in the database.
  Future<void> saveAccountWithOAuth(
    EmailAccount account, {
    required OAuthTokens tokens,
  });

  /// Update an existing account.
  ///
  /// Does not update credentials - use [updatePassword] or [updateOAuthTokens].
  Future<void> updateAccount(EmailAccount account);

  /// Update the password for an account.
  Future<void> updatePassword(String accountId, String password);

  /// Update OAuth tokens for an account.
  Future<void> updateOAuthTokens(String accountId, OAuthTokens tokens);

  /// Delete an account and its credentials.
  Future<void> deleteAccount(String id);

  /// Check if any accounts exist.
  Future<bool> hasAccounts();

  /// Get the number of configured accounts.
  Future<int> getAccountCount();
}
