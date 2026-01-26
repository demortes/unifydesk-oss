import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/mail_providers.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../domain/entities/email_account.dart';
import '../../domain/repositories/account_repository.dart';

/// Provider for account repository.
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepositoryImpl();
});

/// Provider to check if user has any accounts.
final hasAccountsProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.hasAccounts();
});

/// Provider for all accounts.
final allAccountsProvider = FutureProvider<List<EmailAccount>>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.getAllAccounts();
});

/// State for the onboarding flow.
class OnboardingState {
  const OnboardingState({
    this.selectedProvider,
    this.email = '',
    this.password = '',
    this.displayName = '',
    this.imapHost = '',
    this.imapPort = 993,
    this.smtpHost = '',
    this.smtpPort = 465,
    this.useSsl = true,
    this.isLoading = false,
    this.error,
    this.addedAccounts = const [],
  });

  final MailProvider? selectedProvider;
  final String email;
  final String password;
  final String displayName;
  final String imapHost;
  final int imapPort;
  final String smtpHost;
  final int smtpPort;
  final bool useSsl;
  final bool isLoading;
  final String? error;
  final List<EmailAccount> addedAccounts;

  /// Get the provider config for the selected provider.
  ProviderConfig? get providerConfig {
    if (selectedProvider == null) return null;
    return MailProviderConfigs.getConfig(selectedProvider!);
  }

  /// Check if we have enough info to attempt saving.
  bool get canSave {
    if (email.isEmpty) return false;
    if (selectedProvider == null) return false;

    // OAuth providers don't need password
    if (selectedProvider!.usesOAuth) return true;

    // Password providers need password
    if (password.isEmpty) return false;

    // Custom providers need server config
    if (selectedProvider == MailProvider.custom) {
      return imapHost.isNotEmpty && smtpHost.isNotEmpty;
    }

    return true;
  }

  OnboardingState copyWith({
    MailProvider? selectedProvider,
    String? email,
    String? password,
    String? displayName,
    String? imapHost,
    int? imapPort,
    String? smtpHost,
    int? smtpPort,
    bool? useSsl,
    bool? isLoading,
    String? error,
    List<EmailAccount>? addedAccounts,
    bool clearError = false,
    bool clearProvider = false,
  }) {
    return OnboardingState(
      selectedProvider:
          clearProvider ? null : (selectedProvider ?? this.selectedProvider),
      email: email ?? this.email,
      password: password ?? this.password,
      displayName: displayName ?? this.displayName,
      imapHost: imapHost ?? this.imapHost,
      imapPort: imapPort ?? this.imapPort,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      useSsl: useSsl ?? this.useSsl,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      addedAccounts: addedAccounts ?? this.addedAccounts,
    );
  }

  /// Reset for adding another account.
  OnboardingState resetForNewAccount() {
    return OnboardingState(
      addedAccounts: addedAccounts,
    );
  }
}

/// Notifier for managing onboarding state.
class OnboardingNotifier extends Notifier<OnboardingState> {
  late final AccountRepository _repository;
  final _uuid = const Uuid();

  @override
  OnboardingState build() {
    _repository = ref.watch(accountRepositoryProvider);
    return const OnboardingState();
  }

  /// Select a mail provider.
  void selectProvider(MailProvider provider) {
    final config = MailProviderConfigs.getConfig(provider);

    state = state.copyWith(
      selectedProvider: provider,
      clearError: true,
      // Pre-fill server config for known providers
      imapHost: config?.imap.host ?? '',
      imapPort: config?.imap.port ?? 993,
      smtpHost: config?.smtp.host ?? '',
      smtpPort: config?.smtp.port ?? 465,
    );
  }

  /// Update email address.
  void setEmail(String email) {
    state = state.copyWith(email: email, clearError: true);
  }

  /// Update password.
  void setPassword(String password) {
    state = state.copyWith(password: password, clearError: true);
  }

  /// Update display name.
  void setDisplayName(String name) {
    state = state.copyWith(displayName: name);
  }

  /// Update IMAP host.
  void setImapHost(String host) {
    state = state.copyWith(imapHost: host, clearError: true);
  }

  /// Update IMAP port.
  void setImapPort(int port) {
    state = state.copyWith(imapPort: port);
  }

  /// Update SMTP host.
  void setSmtpHost(String host) {
    state = state.copyWith(smtpHost: host, clearError: true);
  }

  /// Update SMTP port.
  void setSmtpPort(int port) {
    state = state.copyWith(smtpPort: port);
  }

  /// Toggle SSL.
  void setUseSsl({required bool useSsl}) {
    state = state.copyWith(useSsl: useSsl);
  }

  /// Save account with password authentication.
  Future<bool> saveAccountWithPassword() async {
    if (!state.canSave) {
      state = state.copyWith(error: 'Please fill in all required fields');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final account = _createAccount();

      await _repository.saveAccountWithPassword(
        account,
        password: state.password,
      );

      // Add to list of added accounts
      state = state.copyWith(
        isLoading: false,
        addedAccounts: [...state.addedAccounts, account],
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save account: $e',
      );
      return false;
    }
  }

  /// Save account with OAuth tokens.
  Future<bool> saveAccountWithOAuth({
    required String email,
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, email: email);

    try {
      final account = _createAccount(isOAuth: true);

      await _repository.saveAccountWithOAuth(
        account,
        tokens: OAuthTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresAt: expiresAt,
        ),
      );

      // Add to list of added accounts
      state = state.copyWith(
        isLoading: false,
        addedAccounts: [...state.addedAccounts, account],
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save account: $e',
      );
      return false;
    }
  }

  /// Reset state to add another account.
  void startNewAccount() {
    state = state.resetForNewAccount();
  }

  /// Clear any error.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  EmailAccount _createAccount({bool isOAuth = false}) {
    final provider = state.selectedProvider ?? MailProvider.custom;
    final config = MailProviderConfigs.getConfig(provider);

    return EmailAccount(
      id: _uuid.v4(),
      email: state.email.toLowerCase().trim(),
      displayName: state.displayName.isNotEmpty ? state.displayName : null,
      providerType: provider,
      authType: isOAuth ? AuthType.oauth : AuthType.password,
      imapHost:
          provider == MailProvider.custom ? state.imapHost : config?.imap.host,
      imapPort:
          provider == MailProvider.custom ? state.imapPort : config?.imap.port,
      smtpHost:
          provider == MailProvider.custom ? state.smtpHost : config?.smtp.host,
      smtpPort:
          provider == MailProvider.custom ? state.smtpPort : config?.smtp.port,
      useSsl: state.useSsl,
      createdAt: DateTime.now(),
    );
  }
}

/// Provider for onboarding state.
final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
        OnboardingNotifier.new,);
