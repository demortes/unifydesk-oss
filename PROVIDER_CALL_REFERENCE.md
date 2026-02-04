# UnifyDesk: Provider Call Reference Map

This document provides a detailed cross-reference of every `ref.watch()`, `ref.read()`, and `ref.invalidate()` call in the codebase.

---

## PART A: ref.watch() Calls (State Subscription)

### A.1 hasAccountsProvider Watchers

| File | Class | Method | Line | Pattern | Purpose |
|------|-------|--------|------|---------|---------|
| `lib/main.dart` | `_AppShellState` | `build()` | 74 | `ref.watch(hasAccountsProvider)` | Check if user has accounts to decide routing (onboarding vs inbox) |

**AsyncValue Handling**:
- `AsyncValue.loading()` → show loading spinner
- `AsyncValue.error()` → show error dialog
- `AsyncValue.data()` → check `value == true` for routing decision

---

### A.2 allAccountsProvider Watchers

| File | Class | Method | Line | Pattern | Purpose |
|------|-------|--------|------|---------|---------|
| `lib/features/mail/presentation/pages/inbox_page.dart` | `_InboxPageState` | `build()` | Line ~37 | `ref.watch(allAccountsProvider)` | Get list of accounts for sidebar account switcher |

**Usage Context**:
```dart
final accounts = ref.watch(allAccountsProvider);
// Use accounts.value ?? [] to build account selector dropdown
```

---

### A.3 onboardingProvider Watchers

| File | Class | Method | Line | Pattern | Purpose |
|------|-------|--------|------|---------|---------|
| `lib/features/mail/presentation/pages/provider_selection_page.dart` | `ProviderSelectionPage` | `build()` | 19 | `ref.watch(onboardingProvider)` | Watch onboarding state for visual feedback on provider selection |
| `lib/features/mail/presentation/pages/imap_config_page.dart` | `_ImapConfigPageState` | `build()` | 99 | `ref.watch(onboardingProvider)` | Watch state to display provider config (host/port prefill) |
| `lib/features/mail/presentation/pages/account_summary_page.dart` | `AccountSummaryPage` | `build()` | 20 | `ref.watch(onboardingProvider)` | Watch `addedAccounts` list to display summary of added accounts |

**State Fields Used**:
- `selectedProvider` - for UI visual indicator
- `imapHost`, `imapPort`, `smtpHost`, `smtpPort` - for server config display
- `addedAccounts` - to show list of accounts being added
- `isLoading`, `isValidating`, `error` - for form state feedback

---

### A.4 inboxProvider Watchers

| File | Class | Method | Line | Pattern | Purpose |
|------|-------|--------|------|---------|---------|
| `lib/features/mail/presentation/pages/inbox_page.dart` | `_InboxPageState` | `build()` | Line ~32 | `ref.watch(inboxProvider)` | Subscribe to inbox state (emails, mailboxes, selected email, loading, error) |

**State Fields Used**:
- `emails` - render email list
- `mailboxes` - render mailbox sidebar
- `selectedMailboxPath` - highlight current mailbox
- `selectedEmailId` - highlight selected email
- `isLoading`, `isSyncing` - show loading indicators
- `error` - display error messages
- `selectedEmail` (computed) - used to display detail pane

---

### A.5 accountsListProvider Watchers

| File | Class | Method | Line | Pattern | Purpose |
|------|-------|--------|------|---------|---------|
| `lib/features/mail/presentation/pages/settings_page.dart` | `SettingsPage` | `build()` | 17 | `ref.watch(accountsListProvider)` | Load and display list of accounts in settings page |

**AsyncValue Handling**:
- `AsyncValue.data()` → list accounts in settings
- `AsyncValue.loading()` → show skeleton/spinner
- `AsyncValue.error()` → show error card

---

### A.6 storageInfoProvider Watchers

| File | Class | Method | Line | Pattern | Purpose |
|------|-------|--------|------|---------|---------|
| `lib/features/mail/presentation/pages/storage_settings_page.dart` | `_StorageSettingsPageState` | `build()` | 295 | `ref.watch(storageInfoProvider)` | Display storage usage breakdown (cache, attachments, emails) |

**AsyncValue Handling**:
- `AsyncValue.data(info)` → display storage stats and clear buttons
- `AsyncValue.loading()` → show spinner
- `AsyncValue.error()` → show error message

---

## PART B: ref.read() Calls (One-Time Access)

### B.1 Provider.notifier Reads for Mutation

#### onboardingProvider.notifier Reads

| File | Class | Method | Line | Usage Pattern |
|------|-------|--------|------|---------------|
| `lib/features/mail/presentation/pages/imap_config_page.dart` | `_ImapConfigPageState` | `_submit()` | 66 | `ref.read(onboardingProvider.notifier)` |
| `lib/features/mail/presentation/pages/imap_config_page.dart` | `_ImapConfigPageState` | `_submit()` | 66-79 | Chain calls: `.setEmail()`, `.setPassword()`, etc. |
| `lib/features/mail/presentation/pages/provider_selection_page.dart` | `ProviderSelectionPage` | `build()` | 53 | `ref.read(onboardingProvider.notifier).selectProvider(provider)` |
| `lib/features/mail/presentation/pages/account_summary_page.dart` | `AccountSummaryPage` | `build()` | 103 | `ref.read(onboardingProvider.notifier).startNewAccount()` |

**Method Chains**:
```dart
// In _submit():
final notifier = ref.read(onboardingProvider.notifier)
  ..setEmail(_emailController.text)
  ..setPassword(_passwordController.text)
  ..setDisplayName(_displayNameController.text);

if (selectedProvider == MailProvider.custom) {
  notifier
    ..setImapHost(_imapHostController.text)
    ..setImapPort(int.tryParse(_imapPortController.text) ?? 993);
}

await notifier.saveAccountWithPassword();
```

#### inboxProvider.notifier Reads

| File | Class | Method | Line | Usage Pattern |
|------|-------|--------|------|---------------|
| `lib/features/mail/presentation/pages/inbox_page.dart` | `_InboxPageState` | `initState()` | ~30 | `ref.read(inboxProvider.notifier).initialize()` |
| `lib/features/mail/presentation/pages/inbox_page.dart` | `_MailSidebar` | `build()` (in callback) | ~80 | `ref.read(inboxProvider.notifier).selectMailbox(path)` |
| `lib/features/mail/presentation/pages/inbox_page.dart` | `_MailSidebar` | `build()` (in callback) | ~90 | `ref.read(inboxProvider.notifier).selectAccount(id)` |
| `lib/features/mail/presentation/pages/inbox_page.dart` | `_EmailListPane` | `build()` (in callback) | ~120 | `ref.read(inboxProvider.notifier).selectEmail(email.id)` |
| `lib/features/mail/presentation/pages/inbox_page.dart` | `_EmailListPane` | `build()` (in callback) | ~130 | `ref.read(inboxProvider.notifier).refresh()` |
| `lib/features/mail/presentation/pages/inbox_page.dart` | `_EmailListPane` | `build()` (in callback) | ~140 | `ref.read(inboxProvider.notifier).clearError()` |
| `lib/features/mail/presentation/pages/inbox_page.dart` | `_EmailDetailPane` | `build()` (in callback) | ~145 | `ref.read(inboxProvider.notifier).clearSelection()` |
| `lib/features/mail/presentation/pages/inbox_page.dart` | `_EmailDetailPane` | `build()` (in callback) | ~150 | `ref.read(inboxProvider.notifier).toggleStarred(email)` |
| `lib/features/mail/presentation/pages/inbox_page.dart` | `_EmailDetailPane` | `build()` (in callback) | ~155 | `ref.read(inboxProvider.notifier).deleteEmail(email)` |
| `lib/features/mail/presentation/pages/inbox_page.dart` | `_EmailDetailPane` | `build()` (in callback) | ~165 | `ref.read(inboxProvider.notifier).archiveEmail(email)` |
| `lib/features/mail/presentation/pages/inbox_page.dart` | `_EmailDetailPane` | `build()` (in callback) | ~175 | `ref.read(inboxProvider.notifier).markAsUnread(email)` |
| `lib/features/mail/presentation/pages/inbox_page.dart` | `_InboxPageState` | `_navigateToAddAccount()` | ~195 | `ref.read(inboxProvider.notifier).initialize()` |

#### storageServiceProvider Reads

| File | Class | Method | Line | Usage Pattern |
|------|-------|--------|------|---------------|
| `lib/features/mail/presentation/pages/storage_settings_page.dart` | `_StorageSettingsPageState` | `_clearCache()` | 46 | `ref.read(storageServiceProvider).clearCache()` |
| `lib/features/mail/presentation/pages/storage_settings_page.dart` | `_StorageSettingsPageState` | `_clearAttachments()` | 87 | `ref.read(storageServiceProvider).clearAttachments()` |
| `lib/features/mail/presentation/pages/storage_settings_page.dart` | `_StorageSettingsPageState` | `_clearEmailData()` | 131 | `ref.read(storageServiceProvider).clearEmailData()` |
| `lib/features/mail/presentation/pages/storage_settings_page.dart` | `_StorageSettingsPageState` | `_clearAllData()` | 184 | `ref.read(storageServiceProvider).clearAllData()` |

---

### B.2 State Reads (One-Time Access)

| File | Class | Method | Line | Usage Pattern | Purpose |
|------|-------|--------|------|---------------|---------|
| `lib/features/mail/presentation/pages/imap_config_page.dart` | `_ImapConfigPageState` | `initState()` | 39 | `ref.read(onboardingProvider)` | Get initial state to populate text controllers |
| `lib/features/mail/presentation/pages/imap_config_page.dart` | `_ImapConfigPageState` | `_submit()` | 73 | `ref.read(onboardingProvider)` | Check if custom provider to set server fields |
| `lib/features/mail/presentation/pages/imap_config_page.dart` | `_ImapConfigPageState` | `_openHelpUrl()` | 90 | `ref.read(onboardingProvider)` | Get provider config to get help URL |

---

### B.3 Dependency Reads in Notifiers

#### In OnboardingNotifier.build()

```dart
@override
OnboardingState build() {
  _repository = ref.watch(accountRepositoryProvider);  // ref.watch in build
  _connectionService = ref.watch(imapConnectionServiceProvider);  // ref.watch in build
  return const OnboardingState();
}
```

#### In InboxNotifier.build()

```dart
@override
InboxState build() {
  _repository = ref.watch(emailRepositoryProvider);  // ref.watch in build
  // ... lifecycle observer setup
  return const InboxState();
}
```

#### In InboxNotifier.removeAccount()

```dart
Future<bool> removeAccount(String accountId) async {
  // ...
  final accountRepo = ref.read(accountRepositoryProvider);
  ref.invalidate(allAccountsProvider);
  ref.invalidate(hasAccountsProvider);
  final remainingAccounts = await ref.read(allAccountsProvider.future);
  // ...
}
```

#### In InboxNotifier.prefetchCommonMailboxes()

```dart
Future<void> prefetchCommonMailboxes() async {
  // ...
  final isMetered = await ref.read(networkMeteredServiceProvider).isActiveNetworkMetered();
  if (isMetered) {
    _logger.d('Metered network detected — skipping prefetch');
    break;
  }
  // ...
}
```

#### In AccountSettingsNotifier Constructor

```dart
AccountRepository get _repository => _ref.read(accountRepositoryProvider);
ImapConnectionService get _connectionService =>
  _ref.read(imapConnectionServiceProvider);
```

---

## PART C: ref.invalidate() Calls (Cache Invalidation)

### C.1 hasAccountsProvider Invalidations

| File | Class | Method | Line | Trigger Context |
|------|-------|--------|------|-----------------|
| `lib/features/mail/presentation/pages/inbox_page.dart` | `_InboxPageState` | `_confirmRemoveAccount()` | ~220 | After last account removed, trigger navigation back to onboarding |

**Code Context**:
```dart
if (!hasRemainingAccounts && context.mounted) {
  ref.invalidate(hasAccountsProvider);  // Trigger AppShell re-evaluation
}
```

---

### C.2 allAccountsProvider Invalidations

| File | Class | Method | Line | Trigger Context |
|------|-------|--------|------|-----------------|
| `lib/features/mail/presentation/pages/inbox_page.dart` | `_InboxPageState` | `_navigateToAddAccount()` | ~200 | After adding account via onboarding modal |
| `lib/features/mail/presentation/pages/inbox_page.dart` | `_InboxPageState` | `_navigateToSettings()` | ~210 | After returning from settings page |
| `lib/features/mail/presentation/pages/inbox_page.dart` | `InboxNotifier` | `removeAccount()` | ~850 | After deleting an account |

**Code Context**:
```dart
// After adding account
ref.invalidate(allAccountsProvider);
ref.read(inboxProvider.notifier).initialize();

// After returning from settings
ref.invalidate(allAccountsProvider);

// In notifier after delete
ref
  ..invalidate(allAccountsProvider)
  ..invalidate(hasAccountsProvider);
```

---

### C.3 accountsListProvider Invalidations

| File | Class | Method | Line | Trigger Context |
|------|-------|--------|------|-----------------|
| `lib/features/mail/presentation/pages/settings_page.dart` | `SettingsPage` | `_openAccountSettings().then()` | 243 | After returning from account settings page |

**Code Context**:
```dart
Navigator.of(context).push(route).then((_) {
  ref.invalidate(accountsListProvider);  // Refresh account list
});
```

---

### C.4 storageInfoProvider Invalidations

| File | Class | Method | Line | Trigger Context |
|------|-------|--------|------|-----------------|
| `lib/features/mail/presentation/pages/storage_settings_page.dart` | `_StorageSettingsPageState` | `_clearCache()` | 48 | After clearing cache successfully |
| `lib/features/mail/presentation/pages/storage_settings_page.dart` | `_StorageSettingsPageState` | `_clearAttachments()` | 89 | After clearing attachments successfully |
| `lib/features/mail/presentation/pages/storage_settings_page.dart` | `_StorageSettingsPageState` | `_clearEmailData()` | 133 | After clearing email data successfully |
| `lib/features/mail/presentation/pages/storage_settings_page.dart` | `_StorageSettingsPageState` | `_clearAllData()` | 186 | After clearing all data successfully |
| `lib/features/mail/presentation/pages/storage_settings_page.dart` | `StorageSettingsPage.build()` | `_clearButton.onPressed()` | 347 | Manual button to refresh stats |

**Code Context**:
```dart
try {
  await service.clearCache();
  ref.invalidate(storageInfoProvider);  // Refresh storage stats
  showSnackBar('Cache cleared');
} catch (e) {
  showSnackBar('Failed: $e');
}
```

---

## PART D: Provider Dependencies Graph

### D.1 Dependency Chains

```
hasAccountsProvider
  ↓ depends on
accountRepositoryProvider

allAccountsProvider
  ↓ depends on
accountRepositoryProvider

inboxProvider
  ↓ depends on
  ├─ emailRepositoryProvider
  │  ├─ accountRepositoryProvider
  │  ├─ EmailLocalDataSource
  │  └─ ImapRemoteDataSource
  ├─ accountRepositoryProvider (for removeAccount)
  ├─ allAccountsProvider (in selectAccount, syncMailboxes, etc)
  └─ networkMeteredServiceProvider (in prefetchCommonMailboxes)

onboardingProvider
  ├─ accountRepositoryProvider
  └─ imapConnectionServiceProvider

accountSettingsNotifierProvider(String accountId)
  ├─ accountRepositoryProvider
  └─ imapConnectionServiceProvider

accountsListProvider
  └─ accountRepositoryProvider

storageInfoProvider
  └─ storageServiceProvider

selectedEmailProvider
  ├─ inboxProvider.selectedEmail (current state)
  └─ emailRepositoryProvider (for fetchFullEmail)
```

---

## PART E: Conversion Mapping Table

For each `ref.watch()`, `ref.read()`, or `ref.invalidate()` call, here's the conversion:

### E.1 Complete Conversion Table

| Original | File | Context | Conversion to ChangeNotifier |
|----------|------|---------|------------------------------|
| `ref.watch(hasAccountsProvider)` | main.dart | AppShell build | `_accountListNotifier.state.hasAccounts` with listener |
| `ref.watch(allAccountsProvider)` | inbox_page.dart | InboxPage build | `_accountListNotifier.state.accounts` with listener |
| `ref.watch(onboardingProvider)` | provider_selection_page.dart | build() | `ListenableBuilder(listenable: notifier, ...)` |
| `ref.watch(onboardingProvider)` | imap_config_page.dart | build() | `ListenableBuilder(listenable: notifier, ...)` |
| `ref.watch(onboardingProvider)` | account_summary_page.dart | build() | `ListenableBuilder(listenable: notifier, ...)` |
| `ref.watch(inboxProvider)` | inbox_page.dart | build() | `_inboxNotifier.state` with listener |
| `ref.watch(accountsListProvider)` | settings_page.dart | build() | `ListenableBuilder(listenable: notifier, ...)` |
| `ref.watch(storageInfoProvider)` | storage_settings_page.dart | build() | `ListenableBuilder(listenable: notifier, ...)` |
| `ref.read(onboardingProvider.notifier)` | imap_config_page.dart | _submit() | `widget.onboardingNotifier` |
| `ref.read(onboardingProvider.notifier)` | provider_selection_page.dart | build() | `widget.onboardingNotifier` |
| `ref.read(onboardingProvider.notifier)` | account_summary_page.dart | build() | `widget.onboardingNotifier` |
| `ref.read(inboxProvider.notifier)` | inbox_page.dart | multiple callbacks | `_inboxNotifier` |
| `ref.read(storageServiceProvider)` | storage_settings_page.dart | clear* methods | `_storageService` or `_storageInfoNotifier` |
| `ref.invalidate(hasAccountsProvider)` | inbox_page.dart | removeAccount context | `_accountListNotifier.refreshAccounts()` |
| `ref.invalidate(allAccountsProvider)` | inbox_page.dart | multiple locations | `_accountListNotifier.refreshAccounts()` |
| `ref.invalidate(accountsListProvider)` | settings_page.dart | navigation | `_accountListNotifier.refreshAccounts()` |
| `ref.invalidate(storageInfoProvider)` | storage_settings_page.dart | after clear* | `_storageInfoNotifier.refreshStorageInfo()` |

---

## PART F: Widget Constructor Parameter Changes

### F.1 Pages Requiring Notifier Injection

```dart
// BEFORE (Riverpod)
class ImapConfigPage extends ConsumerStatefulWidget {
  const ImapConfigPage({
    required this.onSuccess,
    required this.onCancel,
    super.key,
  });
  // Access notifier via ref.read(onboardingProvider.notifier)
}

// AFTER (ChangeNotifier)
class ImapConfigPage extends StatefulWidget {
  const ImapConfigPage({
    required this.onboardingNotifier,  // NEW: injected
    required this.onSuccess,
    required this.onCancel,
    super.key,
  });
  
  final OnboardingNotifier onboardingNotifier;  // NEW field
}
```

### F.2 Sidebar/Detail Pane Callbacks

```dart
// BEFORE (Riverpod)
class _MailSidebar extends StatelessWidget {
  // Uses callbacks that implicitly call ref.read()
  void onMailboxSelected(String path) {
    ref.read(inboxProvider.notifier).selectMailbox(path);
  }
}

// AFTER (ChangeNotifier)
class _MailSidebar extends StatelessWidget {
  const _MailSidebar({
    required this.inboxNotifier,  // NEW: injected
    // ... other params
  });
  
  final InboxNotifier inboxNotifier;
  
  void onMailboxSelected(String path) {
    inboxNotifier.selectMailbox(path);  // Direct call
  }
}
```

---

## Summary Statistics

- **Total ref.watch() calls**: 8
- **Total ref.read() calls**: 18+ (many in notifier callbacks)
- **Total ref.invalidate() calls**: 7+
- **Providers involved**: 9 (6 main providers + 3 derived)
- **Pages affected**: 7
- **Notifiers to create**: 5 new + 1 to convert

This mapping ensures no provider call is missed during migration.
