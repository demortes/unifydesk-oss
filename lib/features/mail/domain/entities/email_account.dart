import 'package:equatable/equatable.dart';

import '../../../../core/constants/mail_providers.dart';

/// Email account entity representing a configured mail account.
///
/// This is the domain entity - it contains no database or serialization logic.
/// Credentials are not stored here; they are managed by SecureStorageService.
class EmailAccount extends Equatable {
  const EmailAccount({
    required this.id,
    required this.email,
    required this.providerType,
    required this.authType,
    required this.createdAt,
    this.displayName,
    this.imapHost,
    this.imapPort,
    this.smtpHost,
    this.smtpPort,
    this.useSsl = true,
    this.updatedAt,
  });

  /// Unique identifier for this account.
  final String id;

  /// Email address for this account.
  final String email;

  /// Display name shown in the UI.
  final String? displayName;

  /// Mail provider type (gmail, yahoo, etc.).
  final MailProvider providerType;

  /// Authentication type (oauth or password).
  final AuthType authType;

  /// IMAP server hostname.
  final String? imapHost;

  /// IMAP server port.
  final int? imapPort;

  /// SMTP server hostname.
  final String? smtpHost;

  /// SMTP server port.
  final int? smtpPort;

  /// Whether to use SSL/TLS for connections.
  final bool useSsl;

  /// When this account was created.
  final DateTime createdAt;

  /// When this account was last updated.
  final DateTime? updatedAt;

  /// Get the display name or email if no display name is set.
  String get displayLabel => displayName ?? email;

  /// Get the effective IMAP configuration.
  /// Uses provider defaults if not explicitly set.
  ({String host, int port}) get effectiveImapConfig {
    final config = MailProviderConfigs.getConfig(providerType);
    return (
      host: imapHost ?? config?.imap.host ?? '',
      port: imapPort ?? config?.imap.port ?? 993,
    );
  }

  /// Get the effective SMTP configuration.
  /// Uses provider defaults if not explicitly set.
  ({String host, int port}) get effectiveSmtpConfig {
    final config = MailProviderConfigs.getConfig(providerType);
    return (
      host: smtpHost ?? config?.smtp.host ?? '',
      port: smtpPort ?? config?.smtp.port ?? 465,
    );
  }

  /// Create a copy with updated fields.
  EmailAccount copyWith({
    String? id,
    String? email,
    String? displayName,
    MailProvider? providerType,
    AuthType? authType,
    String? imapHost,
    int? imapPort,
    String? smtpHost,
    int? smtpPort,
    bool? useSsl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmailAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      providerType: providerType ?? this.providerType,
      authType: authType ?? this.authType,
      imapHost: imapHost ?? this.imapHost,
      imapPort: imapPort ?? this.imapPort,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      useSsl: useSsl ?? this.useSsl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        providerType,
        authType,
        imapHost,
        imapPort,
        smtpHost,
        smtpPort,
        useSsl,
        createdAt,
        updatedAt,
      ];
}
