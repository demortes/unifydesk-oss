# UnifyDesk: ChangeNotifier Implementation Examples

This document provides concrete code examples for the most complex refactoring scenarios.

---

## EXAMPLE 1: Basic ChangeNotifier Creation - OnboardingNotifier

### Step 1: Extract State Class

**File**: `lib/features/mail/presentation/notifiers/onboarding_state.dart`

```dart
import '../../domain/entities/email_account.dart';
import '../../../../core/constants/mail_providers.dart';

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
    this.isValidating = false,
    this.statusMessage,
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
  final bool isValidating;
  final String? statusMessage;
  final String? error;
  final List<EmailAccount> addedAccounts;

  ProviderConfig? get providerConfig {
    if (selectedProvider == null) return null;
    return MailProviderConfigs.getConfig(selectedProvider!);
  }

  bool get canSave {
    if (email.isEmpty) return false;
    if (selectedProvider == null) return false;
    if (selectedProvider!.usesOAuth) return true;
    if (password.isEmpty) return false;
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
    bool? isValidating,
    String? statusMessage,
    String? error,
    List<EmailAccount>? addedAccounts,
    bool clearError = false,
    bool clearStatus = false,
    bool clearProvider = false,
  }) {
    return OnboardingState(
      selectedProvider: clearProvider ? null : (selectedProvider ?? this.selectedProvider),
      email: email ?? this.email,
      password: password ?? this.password,
      displayName: displayName ?? this.displayName,
      imapHost: imapHost ?? this.imapHost,
      imapPort: imapPort ?? this.imapPort,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      useSsl: useSsl ?? this.useSsl,
      isLoading: isLoading ?? this.isLoading,
      isValidating: isValidating ?? this.isValidating,
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
      error: clearError ? null : (error ?? this.error),
      addedAccounts: addedAccounts ?? this.addedAccounts,
    );
  }

  OnboardingState resetForNewAccount() {
    return OnboardingState(addedAccounts: addedAccounts);
  }
}
```

### Step 2: Create ChangeNotifier Class

**File**: `lib/features/mail/presentation/notifiers/onboarding_notifier.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/mail_providers.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/services/imap_connection_service.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../domain/entities/email_account.dart';
import '../../domain/repositories/account_repository.dart';
import 'onboarding_state.dart';

/// Notifier for managing onboarding flow state
class OnboardingNotifier extends ChangeNotifier {
  OnboardingNotifier({
    required AccountRepository accountRepository,
    required ImapConnectionService imapConnectionService,
  }) : _repository = accountRepository,
       _connectionService = imapConnectionService;

  late final AccountRepository _repository;
  late final ImapConnectionService _connectionService;
  final _uuid = const Uuid();

  OnboardingState _state = const OnboardingState();

  /// Current state
  OnboardingState get state => _state;

  /// Update state and notify listeners
  void _setState(OnboardingState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Select a mail provider
  void selectProvider(MailProvider provider) {
    final config = MailProviderConfigs.getConfig(provider);

    _setState(_state.copyWith(
      selectedProvider: provider,
      clearError: true,
      imapHost: config?.imap.host ?? '',
      imapPort: config?.imap.port ?? 993,
      smtpHost: config?.smtp.host ?? '',
      smtpPort: config?.smtp.port ?? 465,
    ));
  }

  /// Update email address
  void setEmail(String email) {
    _setState(_state.copyWith(email: email, clearError: true));
  }

  /// Update password
  void setPassword(String password) {
    _setState(_state.copyWith(password: password, clearError: true));
  }

  /// Update display name
  void setDisplayName(String name) {
    _setState(_state.copyWith(displayName: name));
  }

  /// Update IMAP host
  void setImapHost(String host) {
    _setState(_state.copyWith(imapHost: host, clearError: true));
  }

  /// Update IMAP port
  void setImapPort(int port) {
    _setState(_state.copyWith(imapPort: port));
  }

  /// Update SMTP host
  void setSmtpHost(String host) {
    _setState(_state.copyWith(smtpHost: host, clearError: true));
  }

  /// Update SMTP port
  void setSmtpPort(int port) {
    _setState(_state.copyWith(smtpPort: port));
  }

  /// Toggle SSL
  void setUseSsl({required bool useSsl}) {
    _setState(_state.copyWith(useSsl: useSsl));
  }

  /// Validate credentials and save account with password authentication
  Future<bool> saveAccountWithPassword() async {
    if (!_state.canSave) {
      _setState(_state.copyWith(error: 'Please fill in all required fields'));
      return false;
    }

    final provider = _state.selectedProvider ?? MailProvider.custom;
    final config = MailProviderConfigs.getConfig(provider);
    final imapHost = provider == MailProvider.custom
        ? _state.imapHost
        : config?.imap.host ?? '';
    final imapPort = provider == MailProvider.custom
        ? _state.imapPort
        : config?.imap.port ?? 993;

    // Start validation
    _setState(_state.copyWith(
      isValidating: true,
      isLoading: true,
      statusMessage: 'Verifying credentials...',
      clearError: true,
    ));

    // Test IMAP connection
    final result = await _connectionService.testConnection(
      host: imapHost,
      port: imapPort,
      email: _state.email,
      password: _state.password,
      useSsl: _state.useSsl,
    );

    if (!result.success) {
      _setState(_state.copyWith(
        isValidating: false,
        isLoading: false,
        clearStatus: true,
        error: result.errorMessage ?? 'Connection failed',
      ));
      return false;
    }

    // Connection successful, now save
    _setState(_state.copyWith(
      isValidating: false,
      statusMessage: 'Saving account...',
    ));

    try {
      final account = _createAccount();
      await _repository.saveAccountWithPassword(
        account,
        password: _state.password,
      );

      _setState(_state.copyWith(
        isLoading: false,
        clearStatus: true,
        addedAccounts: [..._state.addedAccounts, account],
      ));

      return true;
    } catch (e) {
      _setState(_state.copyWith(
        isLoading: false,
        clearStatus: true,
        error: 'Failed to save account: $e',
      ));
      return false;
    }
  }

  /// Save account with OAuth tokens
  Future<bool> saveAccountWithOAuth({
    required String email,
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) async {
    _setState(_state.copyWith(isLoading: true, clearError: true, email: email));

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

      _setState(_state.copyWith(
        isLoading: false,
        addedAccounts: [..._state.addedAccounts, account],
      ));

      return true;
    } catch (e) {
      _setState(_state.copyWith(
        isLoading: false,
        error: 'Failed to save account: $e',
      ));
      return false;
    }
  }

  /// Reset state to add another account
  void startNewAccount() {
    _setState(_state.resetForNewAccount());
  }

  /// Clear any error
  void clearError() {
    _setState(_state.copyWith(clearError: true));
  }

  /// Create account entity from current state
  EmailAccount _createAccount({bool isOAuth = false}) {
    final provider = _state.selectedProvider ?? MailProvider.custom;
    final config = MailProviderConfigs.getConfig(provider);

    return EmailAccount(
      id: _uuid.v4(),
      email: _state.email.toLowerCase().trim(),
      displayName: _state.displayName.isNotEmpty ? _state.displayName : null,
      providerType: provider,
      authType: isOAuth ? AuthType.oauth : AuthType.password,
      imapHost: provider == MailProvider.custom ? _state.imapHost : config?.imap.host,
      imapPort: provider == MailProvider.custom ? _state.imapPort : config?.imap.port,
      smtpHost: provider == MailProvider.custom ? _state.smtpHost : config?.smtp.host,
      smtpPort: provider == MailProvider.custom ? _state.smtpPort : config?.smtp.port,
      useSsl: _state.useSsl,
      createdAt: DateTime.now(),
    );
  }
}
```

---

## EXAMPLE 2: Complex ChangeNotifier - InboxNotifier

### Step 1: Create Notifier with Dependencies

**File**: `lib/features/mail/presentation/notifiers/inbox_notifier.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'dart:async';

import '../../domain/entities/email_message.dart';
import '../../domain/entities/mailbox.dart';
import '../../domain/repositories/email_repository.dart';
import '../../domain/repositories/account_repository.dart';
import '../../../../core/services/network_metered_service.dart';
import 'inbox_state.dart';

/// Callback signature for account list changes
typedef OnAccountsChanged = Future<void> Function();

/// Notifier for managing inbox state
class InboxNotifier extends ChangeNotifier {
  InboxNotifier({
    required EmailRepository emailRepository,
    required AccountRepository accountRepository,
    required NetworkMeteredService networkMeteredService,
    this.onAccountsChanged,
  }) : _emailRepository = emailRepository,
       _accountRepository = accountRepository,
       _networkMeteredService = networkMeteredService;

  late final EmailRepository _emailRepository;
  late final AccountRepository _accountRepository;
  late final NetworkMeteredService _networkMeteredService;
  final Logger _logger = Logger();
  
  bool _isLifecycleObserverAttached = false;
  bool _isAppActive = true;
  
  /// Optional callback when accounts change
  final OnAccountsChanged? onAccountsChanged;

  InboxState _state = const InboxState();

  /// Current state
  InboxState get state => _state;

  /// Update state and notify listeners
  void _setState(InboxState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Initialize inbox with the first account
  Future<void> initialize() async {
    final accounts = await _accountRepository.getAllAccounts();
    if (accounts.isEmpty) return;

    // Default to unified view
    await selectAccount(null);
    unawaited(prefetchCommonMailboxes());
  }

  /// Select an account and load its mailboxes
  Future<void> selectAccount(String? accountId) async {
    _setState(_state.copyWith(
      selectedAccountId: accountId,
      isLoading: true,
      clearError: true,
    ));

    try {
      if (accountId == null) {
        // Load unified view across all accounts
        final accounts = await _accountRepository.getAllAccounts();

        // Aggregate mailboxes
        final Map<String, Mailbox> aggregated = {};
        for (final acc in accounts) {
          final cachedMailboxes = await _emailRepository.getMailboxes(acc.id);
          for (final m in cachedMailboxes) {
            final key = _getMailboxKey(m);
            final existing = aggregated[key];
            if (existing == null) {
              aggregated[key] = _createAggregatedMailbox(m, key);
            } else {
              aggregated[key] = existing.copyWith(
                totalMessages: existing.totalMessages + m.totalMessages,
                unreadMessages: existing.unreadMessages + m.unreadMessages,
              );
            }
          }
        }

        // Ensure common folders exist
        _ensureCommonMailboxes(aggregated);
        final ordered = _orderMailboxes(aggregated);

        _setState(_state.copyWith(
          mailboxes: ordered,
          selectedMailboxPath: 'INBOX',
        ));

        // Load emails
        final List<EmailMessage> allEmails = [];
        for (final acc in accounts) {
          try {
            final cachedEmails = await _emailRepository.getEmails(acc.id, 'INBOX');
            allEmails.addAll(cachedEmails);
          } catch (e) {
            _logger.w('Failed to load emails for ${acc.email}: $e');
          }
        }
        allEmails.sort((a, b) => b.date.compareTo(a.date));

        _setState(_state.copyWith(emails: allEmails, isLoading: false));

        // Sync in background
        await syncMailboxes();
        unawaited(prefetchCommonMailboxes());
        return;
      }

      // Single-account flow
      final cachedMailboxes = await _emailRepository.getMailboxes(accountId);
      final cachedEmails = await _emailRepository.getEmails(accountId, 'INBOX');

      _setState(_state.copyWith(
        mailboxes: cachedMailboxes,
        emails: cachedEmails,
        isLoading: false,
      ));

      await syncMailboxes();
      unawaited(prefetchCommonMailboxes());
    } catch (e) {
      _setState(_state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Prefetch common mailboxes
  Future<void> prefetchCommonMailboxes({int fullEmailPrefetchCount = 3}) async {
    await Future.delayed(const Duration(seconds: 2));

    try {
      final accounts = await _accountRepository.getAllAccounts();
      final commonKeys = ['INBOX', 'SENT', 'DRAFTS', 'JUNK', 'TRASH', 'ARCHIVE'];

      for (final acc in accounts) {
        if (!acc.prefetchEnabled) continue;

        try {
          final accountMailboxes = await _emailRepository.getMailboxes(acc.id);
          final paths = <String>[];

          for (final key in commonKeys) {
            final path = _resolveMailboxPathForAccount(key, accountMailboxes);
            if (path != null && !paths.contains(path)) paths.add(path);
          }

          // Fetch messages with limited concurrency
          const concurrency = 3;
          for (var i = 0; i < paths.length; i += concurrency) {
            final chunk = paths.sublist(
              i,
              (i + concurrency) > paths.length ? paths.length : i + concurrency,
            );
            await Future.wait(
              chunk.map((p) => _emailRepository.syncEmails(acc.id, p)),
            );
          }

          // Prefetch full bodies if not metered
          final isMetered = await _networkMeteredService.isActiveNetworkMetered();
          if (isMetered) {
            _logger.d('Metered network - skipping prefetch');
            continue;
          }

          for (final p in paths) {
            try {
              final emails = await _emailRepository.getEmails(
                acc.id,
                p,
                limit: acc.prefetchCount,
              );

              int success = 0;
              for (final e in emails.take(acc.prefetchCount)) {
                if (!_isAppActive) break;

                try {
                  await _emailRepository.fetchFullEmail(acc.id, p, e.uid);
                  success++;
                } catch (err) {
                  _logger.w('Prefetch failed: $err');
                }
              }

              if (success > 0) {
                _setState(_state.copyWith(
                  prefetchSuccessCount: _state.prefetchSuccessCount + success,
                ));
              }
            } catch (_) {}
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Sync mailboxes from server
  Future<void> syncMailboxes() async {
    _setState(_state.copyWith(isSyncing: true, clearError: true));

    try {
      if (_state.selectedAccountId == null) {
        // Aggregate across accounts
        final accounts = await _accountRepository.getAllAccounts();
        final Map<String, Mailbox> aggregated = {};

        for (final acc in accounts) {
          final mailboxes = await _emailRepository.syncMailboxes(acc.id);
          for (final m in mailboxes) {
            final key = _getMailboxKey(m);
            final existing = aggregated[key];
            if (existing == null) {
              aggregated[key] = _createAggregatedMailbox(m, key);
            } else {
              aggregated[key] = existing.copyWith(
                totalMessages: existing.totalMessages + m.totalMessages,
                unreadMessages: existing.unreadMessages + m.unreadMessages,
              );
            }
          }
        }

        _ensureCommonMailboxes(aggregated);
        final ordered = _orderMailboxes(aggregated);

        _setState(_state.copyWith(
          mailboxes: ordered,
          isSyncing: false,
          selectedMailboxPath: 'INBOX',
        ));

        await syncEmails(fullSync: true);
        return;
      }

      // Single account
      final mailboxes = await _emailRepository.syncMailboxes(
        _state.selectedAccountId!,
      );
      _setState(_state.copyWith(mailboxes: mailboxes, isSyncing: false));
      await syncEmails();
    } catch (e) {
      _setState(_state.copyWith(
        isSyncing: false,
        error: 'Sync failed: $e',
      ));
    }
  }

  /// Sync emails from current mailbox
  Future<void> syncEmails({bool fullSync = false}) async {
    _setState(_state.copyWith(isSyncing: true, clearError: true));

    try {
      if (_state.selectedAccountId == null) {
        // Aggregate emails across accounts
        final accounts = await _accountRepository.getAllAccounts();
        final List<EmailMessage> allEmails = [];

        for (final acc in accounts) {
          try {
            final emails = await _emailRepository.syncEmails(
              acc.id,
              _state.selectedMailboxPath,
              fullSync: fullSync,
            );
            allEmails.addAll(emails);
          } catch (e) {
            _logger.w('Failed to sync for ${acc.email}: $e');
          }
        }

        allEmails.sort((a, b) => b.date.compareTo(a.date));
        _setState(_state.copyWith(emails: allEmails, isSyncing: false));
        return;
      }

      // Single account
      final emails = await _emailRepository.syncEmails(
        _state.selectedAccountId!,
        _state.selectedMailboxPath,
        fullSync: fullSync,
      );
      _setState(_state.copyWith(emails: emails, isSyncing: false));
    } catch (e) {
      _setState(_state.copyWith(
        isSyncing: false,
        error: 'Email sync failed: $e',
      ));
    }
  }

  /// Select a mailbox
  Future<void> selectMailbox(String mailboxPath) async {
    _setState(_state.copyWith(
      selectedMailboxPath: mailboxPath,
      isLoading: true,
      clearSelectedEmail: true,
    ));

    try {
      final cachedEmails = await _emailRepository.getEmails(
        _state.selectedAccountId ?? '', // Handle null case
        mailboxPath,
      );
      _setState(_state.copyWith(emails: cachedEmails, isLoading: false));

      await syncEmails();
    } catch (e) {
      _setState(_state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Select an email
  Future<void> selectEmail(String emailId) async {
    _setState(_state.copyWith(selectedEmailId: emailId));

    final email = _state.selectedEmail;
    if (email != null && !email.isRead) {
      await markAsRead(email);
    }
  }

  /// Clear email selection
  void clearSelection() {
    _setState(_state.copyWith(clearSelectedEmail: true));
  }

  /// Mark email as read
  Future<void> markAsRead(EmailMessage email) async {
    try {
      await _emailRepository.setReadStatus(
        email.accountId,
        email.mailboxName,
        email.id,
        email.uid,
        isRead: true,
      );

      final updatedEmails = _state.emails.map((e) {
        if (e.id == email.id) return e.copyWith(isRead: true);
        return e;
      }).toList();

      _setState(_state.copyWith(emails: updatedEmails));
    } catch (e) {
      _setState(_state.copyWith(error: 'Failed to mark as read: $e'));
    }
  }

  /// Mark email as unread
  Future<void> markAsUnread(EmailMessage email) async {
    try {
      await _emailRepository.setReadStatus(
        email.accountId,
        email.mailboxName,
        email.id,
        email.uid,
        isRead: false,
      );

      final updatedEmails = _state.emails.map((e) {
        if (e.id == email.id) return e.copyWith(isRead: false);
        return e;
      }).toList();

      _setState(_state.copyWith(emails: updatedEmails));
    } catch (e) {
      _setState(_state.copyWith(error: 'Failed to mark as unread: $e'));
    }
  }

  /// Toggle email starred status
  Future<void> toggleStarred(EmailMessage email) async {
    try {
      await _emailRepository.setStarredStatus(
        email.accountId,
        email.mailboxName,
        email.id,
        email.uid,
        isStarred: !email.isStarred,
      );

      final updatedEmails = _state.emails.map((e) {
        if (e.id == email.id) return e.copyWith(isStarred: !email.isStarred);
        return e;
      }).toList();

      _setState(_state.copyWith(emails: updatedEmails));
    } catch (e) {
      _setState(_state.copyWith(error: 'Failed to update starred status: $e'));
    }
  }

  /// Delete or archive email
  Future<void> deleteEmail(EmailMessage email) async {
    try {
      Mailbox? archiveMailbox;
      try {
        final accountMailboxes = await _emailRepository.getMailboxes(email.accountId);
        try {
          archiveMailbox = accountMailboxes.firstWhere((m) => m.isArchive);
        } catch (_) {
          try {
            archiveMailbox = accountMailboxes.firstWhere((m) => m.isTrash);
          } catch (_) {}
        }
      } catch (_) {}

      if (archiveMailbox != null && archiveMailbox.path != email.mailboxName) {
        await _emailRepository.moveEmail(
          email.accountId,
          email.mailboxName,
          archiveMailbox.path,
          email.id,
          email.uid,
        );
      } else {
        await _emailRepository.deleteEmail(
          email.accountId,
          email.mailboxName,
          email.id,
          email.uid,
        );
      }

      final updatedEmails = _state.emails.where((e) => e.id != email.id).toList();
      _setState(_state.copyWith(
        emails: updatedEmails,
        clearSelectedEmail: _state.selectedEmailId == email.id,
      ));
    } catch (e) {
      _setState(_state.copyWith(error: 'Failed to delete email: $e'));
    }
  }

  /// Archive email
  Future<void> archiveEmail(EmailMessage email) async {
    try {
      Mailbox? archiveMailbox;
      try {
        final accountMailboxes = await _emailRepository.getMailboxes(email.accountId);
        try {
          archiveMailbox = accountMailboxes.firstWhere((m) => m.isArchive);
        } catch (_) {
          try {
            archiveMailbox = accountMailboxes.firstWhere((m) => m.isTrash);
          } catch (_) {}
        }
      } catch (_) {}

      if (archiveMailbox == null) {
        try {
          await _emailRepository.createMailbox(email.accountId, 'Archive');
          final refreshed = await _emailRepository.getMailboxes(email.accountId);
          try {
            archiveMailbox = refreshed.firstWhere((m) => m.isArchive);
          } catch (_) {}
        } catch (_) {}
      }

      if (archiveMailbox == null || archiveMailbox.path == email.mailboxName) return;

      await _emailRepository.moveEmail(
        email.accountId,
        email.mailboxName,
        archiveMailbox.path,
        email.id,
        email.uid,
      );

      final updatedEmails = _state.emails.where((e) => e.id != email.id).toList();
      _setState(_state.copyWith(
        emails: updatedEmails,
        clearSelectedEmail: _state.selectedEmailId == email.id,
      ));
    } catch (e) {
      _setState(_state.copyWith(error: 'Failed to archive email: $e'));
    }
  }

  /// Refresh inbox
  Future<void> refresh() async {
    await syncEmails(fullSync: true);
  }

  /// Clear error
  void clearError() {
    _setState(_state.copyWith(clearError: true));
  }

  /// Remove an account
  Future<bool> removeAccount(String accountId) async {
    try {
      await _accountRepository.deleteAccount(accountId);

      if (_state.selectedAccountId == accountId) {
        await _emailRepository.disconnect();
      }

      // Notify parent if callback provided
      await onAccountsChanged?.call();

      final remainingAccounts = await _accountRepository.getAllAccounts();

      if (remainingAccounts.isEmpty) {
        _setState(const InboxState());
        return false;
      }

      if (_state.selectedAccountId == accountId) {
        await selectAccount(remainingAccounts.first.id);
      }

      return true;
    } catch (e) {
      _setState(_state.copyWith(error: 'Failed to remove account: $e'));
      return true;
    }
  }

  // ===== Helper Methods =====

  String _getMailboxKey(Mailbox m) {
    if (m.isInbox) return 'INBOX';
    if (m.isSent) return 'SENT';
    if (m.isDrafts) return 'DRAFTS';
    if (m.isTrash) return 'TRASH';
    if (m.isJunk) return 'JUNK';
    if (m.isArchive) return 'ARCHIVE';
    return m.path;
  }

  Mailbox _createAggregatedMailbox(Mailbox m, String key) {
    return Mailbox(
      accountId: '',
      name: m.name,
      path: key,
      delimiter: m.delimiter,
      flags: m.flags,
      totalMessages: m.totalMessages,
      unreadMessages: m.unreadMessages,
      isSelectable: m.isSelectable,
      isSubscribed: m.isSubscribed,
    );
  }

  void _ensureCommonMailboxes(Map<String, Mailbox> aggregated) {
    final commonKeys = {
      'INBOX': 'Inbox',
      'SENT': 'Sent',
      'DRAFTS': 'Drafts',
      'JUNK': 'Spam',
      'TRASH': 'Trash',
      'ARCHIVE': 'Archive',
    };
    for (final key in commonKeys.keys) {
      if (!aggregated.containsKey(key)) {
        aggregated[key] = Mailbox(
          accountId: '',
          name: commonKeys[key]!,
          path: key,
        );
      }
    }
  }

  List<Mailbox> _orderMailboxes(Map<String, Mailbox> aggregated) {
    final ordered = <Mailbox>[];
    for (final key in ['INBOX', 'SENT', 'DRAFTS', 'JUNK', 'TRASH', 'ARCHIVE']) {
      if (aggregated.containsKey(key)) ordered.add(aggregated[key]!);
    }
    final remaining = aggregated.keys
        .where((k) =>
            !['INBOX', 'SENT', 'DRAFTS', 'JUNK', 'TRASH', 'ARCHIVE'].contains(k))
        .toList()
      ..sort();
    for (final k in remaining) {
      ordered.add(aggregated[k]!);
    }
    return ordered;
  }

  String? _resolveMailboxPathForAccount(String mailboxKey, List<Mailbox> accountMailboxes) {
    const special = ['INBOX', 'SENT', 'DRAFTS', 'JUNK', 'TRASH', 'ARCHIVE'];
    if (!special.contains(mailboxKey)) return mailboxKey;

    try {
      if (mailboxKey == 'INBOX') {
        return accountMailboxes.firstWhere((m) => m.isInbox).path;
      }
    } catch (_) {}

    try {
      if (mailboxKey == 'SENT') {
        return accountMailboxes.firstWhere((m) => m.isSent).path;
      }
    } catch (_) {}

    // ... repeat for other special keys ...

    return null;
  }
}
```

---

## EXAMPLE 3: StatefulWidget with ChangeNotifier - InboxPage

**File**: `lib/features/mail/presentation/pages/inbox_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/email_message.dart';
import '../../domain/entities/mailbox.dart';
import '../notifiers/inbox_notifier.dart';
import '../notifiers/account_list_notifier.dart';
import '../notifiers/onboarding_provider.dart'; // Remove this import
import 'onboarding_page.dart';
import 'settings_page.dart';

/// Main inbox page
class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  late InboxNotifier _inboxNotifier;
  late AccountListNotifier _accountListNotifier;

  @override
  void initState() {
    super.initState();
    
    // Get notifiers from service locator
    final getIt = GetIt.instance;
    _accountListNotifier = getIt<AccountListNotifier>();
    
    // Create inbox notifier with callback
    _inboxNotifier = InboxNotifier(
      emailRepository: getIt.get(),
      accountRepository: getIt.get(),
      networkMeteredService: getIt.get(),
      onAccountsChanged: _onAccountsChanged,
    );
    
    // Initialize inbox
    _inboxNotifier.initialize();
    
    // Add listeners
    _inboxNotifier.addListener(_onInboxChanged);
    _accountListNotifier.addListener(_onAccountsChanged);
  }

  void _onInboxChanged() {
    setState(() {}); // Rebuild when inbox changes
  }

  void _onAccountsChanged() {
    setState(() {}); // Rebuild when accounts change
  }

  @override
  void dispose() {
    _inboxNotifier.removeListener(_onInboxChanged);
    _accountListNotifier.removeListener(_onAccountsChanged);
    _inboxNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inboxState = _inboxNotifier.state;
    final accountList = _accountListNotifier.state;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _MailSidebar(
            mailboxes: inboxState.mailboxes,
            selectedMailboxPath: inboxState.selectedMailboxPath,
            onMailboxSelected: (path) => _inboxNotifier.selectMailbox(path),
            accounts: accountList.accounts,
            selectedAccountId: inboxState.selectedAccountId,
            onAccountSelected: (id) => _inboxNotifier.selectAccount(id),
            onAddAccount: () => _navigateToAddAccount(context),
            onRemoveAccount: (id) => _confirmRemoveAccount(context, id),
            onSettings: () => _navigateToSettings(context),
          ),
          // Divider and rest of UI...
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant,
          ),
          // Email list pane
          Expanded(
            flex: 2,
            child: _EmailListPane(
              emails: inboxState.emails,
              selectedEmailId: inboxState.selectedEmailId,
              isLoading: inboxState.isLoading,
              isSyncing: inboxState.isSyncing,
              error: inboxState.error,
              onEmailSelected: (email) => _inboxNotifier.selectEmail(email.id),
              onRefresh: () => _inboxNotifier.refresh(),
              onErrorDismiss: () => _inboxNotifier.clearError(),
              mailboxPath: inboxState.selectedMailboxPath,
            ),
          ),
          // Detail pane
          if (isWide && inboxState.selectedEmail != null) ...[
            VerticalDivider(width: 1, thickness: 1, color: colorScheme.outlineVariant),
            Expanded(
              flex: 3,
              child: _EmailDetailPane(
                email: inboxState.selectedEmail!,
                onClose: () => _inboxNotifier.clearSelection(),
                onToggleStar: () {
                  final email = inboxState.selectedEmail;
                  if (email != null) _inboxNotifier.toggleStarred(email);
                },
                onDelete: () {
                  final email = inboxState.selectedEmail;
                  if (email != null) _inboxNotifier.deleteEmail(email);
                },
                onArchive: () {
                  final email = inboxState.selectedEmail;
                  if (email != null) _inboxNotifier.archiveEmail(email);
                },
                onMarkUnread: () {
                  final email = inboxState.selectedEmail;
                  if (email != null) _inboxNotifier.markAsUnread(email);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToAddAccount(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => OnboardingPage(
          onComplete: () {
            Navigator.of(context).pop();
            _accountListNotifier.refreshAccounts();
            _inboxNotifier.initialize();
          },
        ),
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const SettingsPage(),
      ),
    ).then((_) {
      _accountListNotifier.refreshAccounts();
    });
  }

  Future<void> _confirmRemoveAccount(BuildContext context, String accountId) async {
    final accounts = _accountListNotifier.state.accounts;
    final account = accounts.where((a) => a.id == accountId).firstOrNull;

    if (account == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Account'),
        content: Text(
          'Are you sure you want to remove "${account.email}"?\n\n'
          'This will delete all locally cached emails for this account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      final hasRemainingAccounts = await _inboxNotifier.removeAccount(accountId);

      if (!hasRemainingAccounts && context.mounted) {
        // Navigate back to onboarding
        Navigator.of(context).pushReplacementNamed('/');
      }
    }
  }
}

// Sidebar and other widgets remain similar but use injected notifiers
```

---

## EXAMPLE 4: StatelessWidget with ListenableBuilder - ProviderSelectionPage

**File**: `lib/features/mail/presentation/pages/provider_selection_page.dart`

```dart
import 'package:flutter/material.dart';

import '../../../../core/constants/mail_providers.dart';
import '../notifiers/onboarding_notifier.dart';
import '../widgets/provider_card.dart';

/// Page for selecting an email provider
class ProviderSelectionPage extends StatelessWidget {
  const ProviderSelectionPage({
    required this.onboardingNotifier,
    required this.onProviderSelected,
    super.key,
  });

  final OnboardingNotifier onboardingNotifier;
  final void Function(MailProvider provider) onProviderSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Email Account'),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: onboardingNotifier,
        builder: (context, _) {
          final state = onboardingNotifier.state;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Choose your email provider',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select your email service to get started.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Provider grid
                  ProviderCardList(
                    providers: MailProviderConfigs.allProviders,
                    selectedProvider: state.selectedProvider,
                    onProviderSelected: (provider) {
                      onboardingNotifier.selectProvider(provider);
                      onProviderSelected(provider);
                    },
                  ),

                  const SizedBox(height: 32),

                  // Privacy note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your credentials are stored securely on this device.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

---

## EXAMPLE 5: Service Locator Setup

**File**: `lib/core/di/service_locator.dart`

```dart
import 'package:get_it/get_it.dart';

import '../../features/mail/data/datasources/email_local_datasource.dart';
import '../../features/mail/data/datasources/imap_remote_datasource.dart';
import '../../features/mail/data/repositories/account_repository_impl.dart';
import '../../features/mail/data/repositories/email_repository_impl.dart';
import '../../features/mail/domain/repositories/account_repository.dart';
import '../../features/mail/domain/repositories/email_repository.dart';
import '../../features/mail/presentation/notifiers/account_list_notifier.dart';
import '../../features/mail/presentation/notifiers/inbox_notifier.dart';
import '../../features/mail/presentation/notifiers/onboarding_notifier.dart';
import '../../features/mail/presentation/notifiers/storage_info_notifier.dart';
import '../services/imap_connection_service.dart';
import '../services/network_metered_service.dart';
import '../services/storage_service.dart';

final getIt = GetIt.instance;

/// Setup service locator with all dependencies
void setupServiceLocator() {
  // ===== Repositories =====
  getIt.registerSingleton<AccountRepository>(
    AccountRepositoryImpl(),
  );

  getIt.registerSingleton<EmailRepository>(
    EmailRepositoryImpl(
      accountRepository: getIt<AccountRepository>(),
      localDataSource: EmailLocalDataSource(),
      remoteDataSource: ImapRemoteDataSource(),
    ),
  );

  // ===== Services =====
  getIt.registerSingleton<ImapConnectionService>(
    ImapConnectionService(),
  );

  getIt.registerSingleton<NetworkMeteredService>(
    NetworkMeteredService(),
  );

  getIt.registerSingleton<StorageService>(
    StorageService(),
  );

  // ===== Notifiers (Singletons for shared state) =====
  getIt.registerSingleton<AccountListNotifier>(
    AccountListNotifier(
      accountRepository: getIt<AccountRepository>(),
    ),
  );

  getIt.registerSingleton<OnboardingNotifier>(
    OnboardingNotifier(
      accountRepository: getIt<AccountRepository>(),
      imapConnectionService: getIt<ImapConnectionService>(),
    ),
  );

  getIt.registerSingleton<StorageInfoNotifier>(
    StorageInfoNotifier(
      storageService: getIt<StorageService>(),
    ),
  );

  // InboxNotifier is created per-page (not singleton)
  // because different pages might need different instances
}
```

---

## EXAMPLE 6: Updated main.dart

**File**: `lib/main.dart`

```dart
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/di/service_locator.dart';
import 'features/mail/presentation/pages/inbox_page.dart';
import 'features/mail/presentation/pages/onboarding_page.dart';
import 'features/mail/presentation/notifiers/account_list_notifier.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database factory for desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Setup service locator BEFORE running app
  setupServiceLocator();

  runApp(
    const UnifyDeskApp(), // No ProviderScope needed!
  );
}

class UnifyDeskApp extends StatelessWidget {
  const UnifyDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UnifyDesk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(),
        ),
      ),
      home: const AppShell(),
    );
  }
}

/// Main app shell for routing
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late AccountListNotifier _accountListNotifier;

  @override
  void initState() {
    super.initState();
    _accountListNotifier = getIt<AccountListNotifier>();
    _accountListNotifier.loadAccounts();
    _accountListNotifier.addListener(_onAccountsChanged);
  }

  void _onAccountsChanged() {
    setState(() {}); // Rebuild when accounts change
  }

  @override
  void dispose() {
    _accountListNotifier.removeListener(_onAccountsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsState = _accountListNotifier.state;

    if (accountsState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (accountsState.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error initializing app',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(accountsState.error ?? 'Unknown error'),
            ],
          ),
        ),
      );
    }

    // Route based on whether user has accounts
    if (!accountsState.hasAccounts) {
      return OnboardingPage(
        onComplete: () => _accountListNotifier.refreshAccounts(),
      );
    }

    return const InboxPage();
  }
}
```

---

## Summary

These examples show:

1. **Extracting state classes** into separate files
2. **Converting Notifiers** from Riverpod's `Notifier` to `extends ChangeNotifier`
3. **Using `_setState()` helper** to update state and notify listeners
4. **Handling async operations** with proper error handling
5. **Setting up StatefulWidget** with listener management
6. **Using `ListenableBuilder`** in stateless widgets
7. **Service Locator pattern** with GetIt for dependency injection
8. **Proper lifecycle management** with dispose

All patterns are production-ready and handle the complex requirements of the UnifyDesk application.
