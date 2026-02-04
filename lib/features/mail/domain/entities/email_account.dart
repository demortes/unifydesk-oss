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
    this.signature,
    this.replyTo,
    this.imapHost,
    this.imapPort,
    this.smtpHost,
    this.smtpPort,
    this.useSsl = true,
    this.syncFrequencyMinutes = 15,
    this.isActive = true,
    this.prefetchEnabled = true,
    this.prefetchCount = 3,
    this.updatedAt,
  });

  /// Unique identifier for this account.
  final String id;

  /// Email address for this account.
  final String email;

  /// Display name shown in the UI and outgoing emails.
  final String? displayName;

  /// Email signature appended to outgoing messages.
  final String? signature;

  /// Reply-to email address (if different from account email).
  final String? replyTo;

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

  /// How often to sync emails (in minutes).
  final int syncFrequencyMinutes;

  /// Whether this account is active (enabled for sync).
  final bool isActive;
  /// Whether background prefetching is enabled for this account.
  final bool prefetchEnabled;
  /// How many recent messages per mailbox to prefetch full bodies for.
  final int prefetchCount;

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
    String? signature,
    String? replyTo,
    MailProvider? providerType,
    AuthType? authType,
    String? imapHost,
    int? imapPort,
    String? smtpHost,
    int? smtpPort,
    bool? useSsl,
    int? syncFrequencyMinutes,
    bool? isActive,
    bool? prefetchEnabled,
    int? prefetchCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearDisplayName = false,
    bool clearSignature = false,
    bool clearReplyTo = false,
  }) {
    return EmailAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: clearDisplayName ? null : (displayName ?? this.displayName),
      signature: clearSignature ? null : (signature ?? this.signature),
      replyTo: clearReplyTo ? null : (replyTo ?? this.replyTo),
      providerType: providerType ?? this.providerType,
      authType: authType ?? this.authType,
      imapHost: imapHost ?? this.imapHost,
      imapPort: imapPort ?? this.imapPort,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      useSsl: useSsl ?? this.useSsl,
      syncFrequencyMinutes: syncFrequencyMinutes ?? this.syncFrequencyMinutes,
      isActive: isActive ?? this.isActive,
      prefetchEnabled: prefetchEnabled ?? this.prefetchEnabled,
      prefetchCount: prefetchCount ?? this.prefetchCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        signature,
        replyTo,
        providerType,
        authType,
        imapHost,
        imapPort,
        smtpHost,
        smtpPort,
        useSsl,
        syncFrequencyMinutes,
        isActive,
        prefetchEnabled,
        prefetchCount,
        createdAt,
        updatedAt,
      ];
}
