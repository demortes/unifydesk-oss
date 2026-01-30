import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/imap_connection_service.dart';
import '../../domain/entities/email_account.dart';
import '../../domain/repositories/account_repository.dart';
import 'onboarding_provider.dart';

/// State for account settings editing.
class AccountSettingsState {
  const AccountSettingsState({
    this.account,
    this.displayName = '',
    this.signature = '',
    this.replyTo = '',
    this.syncFrequencyMinutes = 15,
    this.isActive = true,
    this.isLoading = false,
    this.isSaving = false,
    this.isValidatingPassword = false,
    this.statusMessage,
    this.error,
    this.successMessage,
  });

  final EmailAccount? account;
  final String displayName;
  final String signature;
  final String replyTo;
  final int syncFrequencyMinutes;
  final bool isActive;
  final bool isLoading;
  final bool isSaving;
  final bool isValidatingPassword;
  final String? statusMessage;
  final String? error;
  final String? successMessage;

  /// Check if there are unsaved changes.
  bool get hasChanges {
    if (account == null) return false;
    return displayName != (account!.displayName ?? '') ||
        signature != (account!.signature ?? '') ||
        replyTo != (account!.replyTo ?? '') ||
        syncFrequencyMinutes != account!.syncFrequencyMinutes ||
        isActive != account!.isActive;
  }

  AccountSettingsState copyWith({
    EmailAccount? account,
    String? displayName,
    String? signature,
    String? replyTo,
    int? syncFrequencyMinutes,
    bool? isActive,
    bool? isLoading,
    bool? isSaving,
    bool? isValidatingPassword,
    String? statusMessage,
    String? error,
    String? successMessage,
    bool clearStatus = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AccountSettingsState(
      account: account ?? this.account,
      displayName: displayName ?? this.displayName,
      signature: signature ?? this.signature,
      replyTo: replyTo ?? this.replyTo,
      syncFrequencyMinutes: syncFrequencyMinutes ?? this.syncFrequencyMinutes,
      isActive: isActive ?? this.isActive,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isValidatingPassword: isValidatingPassword ?? this.isValidatingPassword,
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

/// Notifier for managing account settings.
/// Uses a simple Provider pattern with account ID.
class AccountSettingsNotifier {
  AccountSettingsNotifier(this._ref, this._accountId);

  final Ref _ref;
  final String _accountId;
  AccountSettingsState _state = const AccountSettingsState(isLoading: true);
  final _listeners = <void Function(AccountSettingsState)>[];

  AccountRepository get _repository => _ref.read(accountRepositoryProvider);
  ImapConnectionService get _connectionService =>
      _ref.read(imapConnectionServiceProvider);

  AccountSettingsState get state => _state;

  void addListener(void Function(AccountSettingsState) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(AccountSettingsState) listener) {
    _listeners.remove(listener);
  }

  void _notify() {
    for (final listener in _listeners) {
      listener(_state);
    }
  }

  void _updateState(AccountSettingsState newState) {
    _state = newState;
    _notify();
  }

  Future<void> loadAccount() async {
    try {
      final account = await _repository.getAccount(_accountId);
      if (account != null) {
        _updateState(_state.copyWith(
          account: account,
          displayName: account.displayName ?? '',
          signature: account.signature ?? '',
          replyTo: account.replyTo ?? '',
          syncFrequencyMinutes: account.syncFrequencyMinutes,
          isActive: account.isActive,
          isLoading: false,
        ));
      } else {
        _updateState(_state.copyWith(
          isLoading: false,
          error: 'Account not found',
        ));
      }
    } catch (e) {
      _updateState(_state.copyWith(
        isLoading: false,
        error: 'Failed to load account: $e',
      ));
    }
  }

  void setDisplayName(String value) {
    _updateState(_state.copyWith(displayName: value, clearError: true));
  }

  void setSignature(String value) {
    _updateState(_state.copyWith(signature: value, clearError: true));
  }

  void setReplyTo(String value) {
    _updateState(_state.copyWith(replyTo: value, clearError: true));
  }

  void setSyncFrequency(int minutes) {
    _updateState(
        _state.copyWith(syncFrequencyMinutes: minutes, clearError: true));
  }

  void setActive(bool value) {
    _updateState(_state.copyWith(isActive: value, clearError: true));
  }

  Future<bool> saveChanges() async {
    if (_state.account == null) return false;

    _updateState(_state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final updatedAccount = _state.account!.copyWith(
        displayName:
            _state.displayName.isNotEmpty ? _state.displayName : null,
        signature: _state.signature.isNotEmpty ? _state.signature : null,
        replyTo: _state.replyTo.isNotEmpty ? _state.replyTo : null,
        syncFrequencyMinutes: _state.syncFrequencyMinutes,
        isActive: _state.isActive,
        updatedAt: DateTime.now(),
        clearDisplayName: _state.displayName.isEmpty,
        clearSignature: _state.signature.isEmpty,
        clearReplyTo: _state.replyTo.isEmpty,
      );

      await _repository.updateAccount(updatedAccount);

      _updateState(_state.copyWith(
        account: updatedAccount,
        isSaving: false,
        successMessage: 'Settings saved successfully',
      ));

      return true;
    } catch (e) {
      _updateState(_state.copyWith(
        isSaving: false,
        error: 'Failed to save settings: $e',
      ));
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    if (_state.account == null) return false;

    final account = _state.account!;
    final imapConfig = account.effectiveImapConfig;

    _updateState(_state.copyWith(
      isValidatingPassword: true,
      statusMessage: 'Verifying new password...',
      clearError: true,
      clearSuccess: true,
    ));

    final result = await _connectionService.testConnection(
      host: imapConfig.host,
      port: imapConfig.port,
      email: account.email,
      password: newPassword,
      useSsl: account.useSsl,
    );

    if (!result.success) {
      _updateState(_state.copyWith(
        isValidatingPassword: false,
        clearStatus: true,
        error: result.errorMessage ?? 'Password validation failed',
      ));
      return false;
    }

    _updateState(_state.copyWith(statusMessage: 'Saving password...'));

    try {
      await _repository.updatePassword(account.id, newPassword);

      _updateState(_state.copyWith(
        isValidatingPassword: false,
        clearStatus: true,
        successMessage: 'Password updated successfully',
      ));
      return true;
    } catch (e) {
      _updateState(_state.copyWith(
        isValidatingPassword: false,
        clearStatus: true,
        error: 'Failed to save password: $e',
      ));
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    if (_state.account == null) return false;

    _updateState(_state.copyWith(
      isSaving: true,
      clearError: true,
    ));

    try {
      await _repository.deleteAccount(_state.account!.id);
      _updateState(_state.copyWith(isSaving: false));
      return true;
    } catch (e) {
      _updateState(_state.copyWith(
        isSaving: false,
        error: 'Failed to delete account: $e',
      ));
      return false;
    }
  }

  void clearMessages() {
    _updateState(_state.copyWith(clearError: true, clearSuccess: true));
  }
}

/// Provider for account settings notifier.
/// Creates a notifier for each account ID.
final accountSettingsNotifierProvider =
    Provider.autoDispose.family<AccountSettingsNotifier, String>(
  (ref, accountId) {
    final notifier = AccountSettingsNotifier(ref, accountId);
    notifier.loadAccount();
    return notifier;
  },
);

/// Provider for all accounts list (for settings page).
final accountsListProvider = FutureProvider<List<EmailAccount>>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);
  return repository.getAllAccounts();
});
