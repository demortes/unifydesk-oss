import 'dart:async';
import 'dart:io';

import 'package:enough_mail/enough_mail.dart';

/// Result of an IMAP connection test.
class ConnectionTestResult {
  const ConnectionTestResult._({
    required this.success,
    this.errorMessage,
    this.errorCode,
  });

  factory ConnectionTestResult.success() {
    return const ConnectionTestResult._(success: true);
  }

  factory ConnectionTestResult.failure(String message, {String? code}) {
    return ConnectionTestResult._(
      success: false,
      errorMessage: message,
      errorCode: code,
    );
  }

  final bool success;
  final String? errorMessage;
  final String? errorCode;
}

/// Service for testing IMAP connections.
class ImapConnectionService {
  /// Test IMAP connection with the provided credentials.
  ///
  /// Returns a [ConnectionTestResult] indicating success or failure.
  Future<ConnectionTestResult> testConnection({
    required String host,
    required int port,
    required String email,
    required String password,
    bool useSsl = true,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    ImapClient? client;

    try {
      // Create IMAP client
      client = ImapClient(isLogEnabled: false);

      // Connect with timeout
      await client
          .connectToServer(
            host,
            port,
            isSecure: useSsl,
          )
          .timeout(timeout);

      // Attempt login
      await client.login(email, password).timeout(timeout);

      // If we got here, connection and login succeeded
      // Logout gracefully
      try {
        await client.logout().timeout(const Duration(seconds: 5));
      } catch (_) {
        // Ignore logout errors
      }

      return ConnectionTestResult.success();
    } on TimeoutException {
      return ConnectionTestResult.failure(
        'Connection timed out. Please check your server settings.',
        code: 'timeout',
      );
    } on SocketException catch (e) {
      if (e.message.contains('Connection refused')) {
        return ConnectionTestResult.failure(
          'Could not connect to server. Please verify the host and port.',
          code: 'connection_refused',
        );
      }
      if (e.message.contains('No route to host') ||
          e.message.contains('Network is unreachable')) {
        return ConnectionTestResult.failure(
          'Network error. Please check your internet connection.',
          code: 'network_error',
        );
      }
      return ConnectionTestResult.failure(
        'Connection failed: ${e.message}',
        code: 'socket_error',
      );
    } on ImapException catch (e) {
      // Parse common IMAP errors
      final message = (e.message ?? '').toLowerCase();

      if (message.contains('invalid credentials') ||
          message.contains('authentication failed') ||
          message.contains('login failed') ||
          message.contains('authenticationfailed')) {
        return ConnectionTestResult.failure(
          'Invalid email or password. Please check your credentials.',
          code: 'auth_failed',
        );
      }

      if (message.contains('too many')) {
        return ConnectionTestResult.failure(
          'Too many login attempts. Please try again later.',
          code: 'rate_limited',
        );
      }

      return ConnectionTestResult.failure(
        'Authentication error: ${e.message ?? 'Unknown error'}',
        code: 'imap_error',
      );
    } on HandshakeException {
      return ConnectionTestResult.failure(
        'SSL/TLS handshake failed. Try toggling the SSL setting.',
        code: 'ssl_error',
      );
    } catch (e) {
      return ConnectionTestResult.failure(
        'Connection failed: $e',
        code: 'unknown',
      );
    } finally {
      // Ensure client is closed
      try {
        if (client?.isConnected ?? false) {
          await client?.disconnect();
        }
      } catch (_) {
        // Ignore disconnect errors
      }
    }
  }
}
