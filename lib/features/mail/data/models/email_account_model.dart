import '../../../../core/constants/mail_providers.dart';
import '../../../../core/database/tables/email_accounts_table.dart';
import '../../domain/entities/email_account.dart';

/// Data model for email accounts with database serialization.
class EmailAccountModel {
  const EmailAccountModel({
    required this.id,
    required this.email,
    required this.providerType,
    required this.authType,
    required this.createdAt,
    required this.updatedAt,
    this.displayName,
    this.imapHost,
    this.imapPort,
    this.smtpHost,
    this.smtpPort,
    this.useSsl = true,
  });

  /// Create from database row.
  factory EmailAccountModel.fromMap(Map<String, dynamic> map) {
    return EmailAccountModel(
      id: map[EmailAccountsTable.columnId] as String,
      email: map[EmailAccountsTable.columnEmail] as String,
      displayName: map[EmailAccountsTable.columnDisplayName] as String?,
      providerType: _parseProvider(map[EmailAccountsTable.columnProviderType] as String),
      authType: _parseAuthType(map[EmailAccountsTable.columnAuthType] as String),
      imapHost: map[EmailAccountsTable.columnImapHost] as String?,
      imapPort: map[EmailAccountsTable.columnImapPort] as int?,
      smtpHost: map[EmailAccountsTable.columnSmtpHost] as String?,
      smtpPort: map[EmailAccountsTable.columnSmtpPort] as int?,
      useSsl: (map[EmailAccountsTable.columnUseSsl] as int?) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[EmailAccountsTable.columnCreatedAt] as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map[EmailAccountsTable.columnUpdatedAt] as int,
      ),
    );
  }

  /// Create from domain entity.
  factory EmailAccountModel.fromEntity(EmailAccount entity) {
    return EmailAccountModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      providerType: entity.providerType,
      authType: entity.authType,
      imapHost: entity.imapHost,
      imapPort: entity.imapPort,
      smtpHost: entity.smtpHost,
      smtpPort: entity.smtpPort,
      useSsl: entity.useSsl,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt ?? entity.createdAt,
    );
  }

  final String id;
  final String email;
  final String? displayName;
  final MailProvider providerType;
  final AuthType authType;
  final String? imapHost;
  final int? imapPort;
  final String? smtpHost;
  final int? smtpPort;
  final bool useSsl;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Convert to database map.
  Map<String, dynamic> toMap() {
    return {
      EmailAccountsTable.columnId: id,
      EmailAccountsTable.columnEmail: email,
      EmailAccountsTable.columnDisplayName: displayName,
      EmailAccountsTable.columnProviderType: providerType.name,
      EmailAccountsTable.columnAuthType: authType.name,
      EmailAccountsTable.columnImapHost: imapHost,
      EmailAccountsTable.columnImapPort: imapPort,
      EmailAccountsTable.columnSmtpHost: smtpHost,
      EmailAccountsTable.columnSmtpPort: smtpPort,
      EmailAccountsTable.columnUseSsl: useSsl ? 1 : 0,
      EmailAccountsTable.columnCreatedAt: createdAt.millisecondsSinceEpoch,
      EmailAccountsTable.columnUpdatedAt: updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Convert to domain entity.
  EmailAccount toEntity() {
    return EmailAccount(
      id: id,
      email: email,
      displayName: displayName,
      providerType: providerType,
      authType: authType,
      imapHost: imapHost,
      imapPort: imapPort,
      smtpHost: smtpHost,
      smtpPort: smtpPort,
      useSsl: useSsl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static MailProvider _parseProvider(String value) {
    return MailProvider.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MailProvider.custom,
    );
  }

  static AuthType _parseAuthType(String value) {
    return AuthType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AuthType.password,
    );
  }
}
