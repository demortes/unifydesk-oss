/// Mail provider configuration constants and auto-discovery settings.
library;

/// Supported mail providers with auto-configuration.
enum MailProvider {
  gmail('Gmail', 'gmail.com'),
  yahoo('Yahoo Mail', 'yahoo.com'),
  icloud('iCloud', 'icloud.com'),
  outlook('Outlook.com', 'outlook.com'),
  aol('AOL', 'aol.com'),
  custom('Other', '');

  const MailProvider(this.displayName, this.domain);

  final String displayName;
  final String domain;

  /// Get provider icon name for display.
  String get iconAsset {
    return switch (this) {
      MailProvider.gmail => 'assets/icons/gmail.png',
      MailProvider.yahoo => 'assets/icons/yahoo.png',
      MailProvider.icloud => 'assets/icons/icloud.png',
      MailProvider.outlook => 'assets/icons/outlook.png',
      MailProvider.aol => 'assets/icons/aol.png',
      MailProvider.custom => 'assets/icons/email.png',
    };
  }

  /// Check if this provider uses OAuth authentication.
  bool get usesOAuth => this == MailProvider.gmail;

  /// Check if this provider has auto-configuration.
  bool get hasAutoConfig => this != MailProvider.custom;
}

/// Authentication type for email accounts.
enum AuthType {
  oauth('OAuth 2.0'),
  password('App Password');

  const AuthType(this.displayName);

  final String displayName;
}

/// Connection security type.
enum ConnectionSecurity {
  ssl('SSL/TLS'),
  starttls('STARTTLS'),
  none('None (not recommended)');

  const ConnectionSecurity(this.displayName);

  final String displayName;
}

/// Server configuration for a mail provider.
class ServerConfig {
  const ServerConfig({
    required this.host,
    required this.port,
    this.security = ConnectionSecurity.ssl,
  });

  final String host;
  final int port;
  final ConnectionSecurity security;
}

/// Complete configuration for a mail provider.
class ProviderConfig {
  const ProviderConfig({
    required this.provider,
    required this.authType,
    required this.imap,
    required this.smtp,
    this.oauthScopes,
    this.helpUrl,
  });

  final MailProvider provider;
  final AuthType authType;
  final ServerConfig imap;
  final ServerConfig smtp;
  final List<String>? oauthScopes;
  final String? helpUrl;
}

/// Predefined configurations for supported mail providers.
class MailProviderConfigs {
  MailProviderConfigs._();

  static const gmail = ProviderConfig(
    provider: MailProvider.gmail,
    authType: AuthType.oauth,
    imap: ServerConfig(host: 'imap.gmail.com', port: 993),
    smtp: ServerConfig(host: 'smtp.gmail.com', port: 465),
    oauthScopes: [
      'https://mail.google.com/',
      'https://www.googleapis.com/auth/userinfo.email',
    ],
    helpUrl: 'https://support.google.com/mail/answer/7126229',
  );

  static const yahoo = ProviderConfig(
    provider: MailProvider.yahoo,
    authType: AuthType.password,
    imap: ServerConfig(host: 'imap.mail.yahoo.com', port: 993),
    smtp: ServerConfig(host: 'smtp.mail.yahoo.com', port: 465),
    helpUrl: 'https://help.yahoo.com/kb/generate-app-password-sln15241.html',
  );

  static const icloud = ProviderConfig(
    provider: MailProvider.icloud,
    authType: AuthType.password,
    imap: ServerConfig(host: 'imap.mail.me.com', port: 993),
    smtp: ServerConfig(
      host: 'smtp.mail.me.com',
      port: 587,
      security: ConnectionSecurity.starttls,
    ),
    helpUrl: 'https://support.apple.com/en-us/HT204397',
  );

  static const outlook = ProviderConfig(
    provider: MailProvider.outlook,
    authType: AuthType.password,
    imap: ServerConfig(host: 'outlook.office365.com', port: 993),
    smtp: ServerConfig(
      host: 'smtp.office365.com',
      port: 587,
      security: ConnectionSecurity.starttls,
    ),
    helpUrl: 'https://support.microsoft.com/en-us/account-billing/using-app-passwords-with-apps-that-don-t-support-two-step-verification-5896ed9b-4263-e681-128a-a6f2979a7944',
  );

  static const aol = ProviderConfig(
    provider: MailProvider.aol,
    authType: AuthType.password,
    imap: ServerConfig(host: 'imap.aol.com', port: 993),
    smtp: ServerConfig(host: 'smtp.aol.com', port: 465),
    helpUrl: 'https://help.aol.com/articles/Create-and-manage-app-password',
  );

  /// Get configuration for a provider.
  static ProviderConfig? getConfig(MailProvider provider) {
    return switch (provider) {
      MailProvider.gmail => gmail,
      MailProvider.yahoo => yahoo,
      MailProvider.icloud => icloud,
      MailProvider.outlook => outlook,
      MailProvider.aol => aol,
      MailProvider.custom => null,
    };
  }

  /// Try to detect provider from email address.
  static MailProvider detectFromEmail(String email) {
    final domain = email.split('@').lastOrNull?.toLowerCase() ?? '';

    if (domain.contains('gmail') || domain.contains('googlemail')) {
      return MailProvider.gmail;
    }
    if (domain.contains('yahoo')) {
      return MailProvider.yahoo;
    }
    if (domain.contains('icloud') || domain.contains('me.com') || domain.contains('mac.com')) {
      return MailProvider.icloud;
    }
    if (domain.contains('outlook') || domain.contains('hotmail') || domain.contains('live.com') || domain.contains('msn.com')) {
      return MailProvider.outlook;
    }
    if (domain.contains('aol')) {
      return MailProvider.aol;
    }

    return MailProvider.custom;
  }

  /// All providers in display order.
  static const List<MailProvider> allProviders = [
    MailProvider.gmail,
    MailProvider.outlook,
    MailProvider.yahoo,
    MailProvider.icloud,
    MailProvider.aol,
    MailProvider.custom,
  ];
}
