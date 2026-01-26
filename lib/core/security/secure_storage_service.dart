import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing sensitive credentials.
///
/// Uses platform-specific secure storage:
/// - iOS: Keychain
/// - Android: Keystore
/// - Windows: Windows Credential Manager
/// - macOS: Keychain
/// - Linux: libsecret
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  final FlutterSecureStorage _storage;

  // Key prefixes for different credential types
  static const _passwordPrefix = 'password_';
  static const _oauthTokensPrefix = 'oauth_tokens_';

  /// Save a password credential for an account.
  Future<void> savePassword(String accountId, String password) async {
    await _storage.write(
      key: '$_passwordPrefix$accountId',
      value: password,
    );
  }

  /// Get a password credential for an account.
  Future<String?> getPassword(String accountId) async {
    return _storage.read(key: '$_passwordPrefix$accountId');
  }

  /// Delete a password credential for an account.
  Future<void> deletePassword(String accountId) async {
    await _storage.delete(key: '$_passwordPrefix$accountId');
  }

  /// Save OAuth tokens for an account.
  Future<void> saveOAuthTokens(
    String accountId, {
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) async {
    final tokens = OAuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
    await _storage.write(
      key: '$_oauthTokensPrefix$accountId',
      value: jsonEncode(tokens.toJson()),
    );
  }

  /// Get OAuth tokens for an account.
  Future<OAuthTokens?> getOAuthTokens(String accountId) async {
    final json = await _storage.read(key: '$_oauthTokensPrefix$accountId');
    if (json == null) return null;

    try {
      return OAuthTokens.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Delete OAuth tokens for an account.
  Future<void> deleteOAuthTokens(String accountId) async {
    await _storage.delete(key: '$_oauthTokensPrefix$accountId');
  }

  /// Delete all credentials for an account.
  Future<void> deleteAllCredentials(String accountId) async {
    await Future.wait([
      deletePassword(accountId),
      deleteOAuthTokens(accountId),
    ]);
  }

  /// Check if an account has stored credentials.
  Future<bool> hasCredentials(String accountId) async {
    final password = await getPassword(accountId);
    if (password != null) return true;

    final tokens = await getOAuthTokens(accountId);
    return tokens != null;
  }

  /// Clear all stored credentials. Use with caution!
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

/// OAuth tokens with expiration tracking.
class OAuthTokens {
  const OAuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory OAuthTokens.fromJson(Map<String, dynamic> json) {
    return OAuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int),
    );
  }

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  /// Check if the access token is expired or about to expire.
  bool get isExpired => DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 5)));

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
    };
  }
}
