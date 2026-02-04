# UnifyDesk: Riverpod to ChangeNotifier Migration Plan

## Executive Summary

This document provides a comprehensive refactoring plan to migrate the UnifyDesk Flutter application from **flutter_riverpod** to **ChangeNotifier** pattern. The analysis covers all 14 specified files with detailed provider mappings, state management structures, and widget refactoring requirements.

---

## PART 1: PROVIDER CATALOG & STATE MAPPING

### 1.1 Service Providers (Stateless/Pure Service Providers)

#### Service 1: `imapConnectionServiceProvider`
- **Type**: `Provider<ImapConnectionService>`
- **Location**: `lib/features/mail/presentation/providers/onboarding_provider.dart`
- **Purpose**: Provides IMAP connection testing and validation service
- **Replacement Strategy**: Create `ImapConnectionService` as singleton via static factory or Service Locator (GetIt)
- **Methods Exposed**:
  - `testConnection()` - validates IMAP credentials
- **Watched By**:
  - `OnboardingNotifier.build()` - reads via `ref.watch()`
  - AccountSettingsPage (indirectly via settings notifier)

#### Service 2: `accountRepositoryProvider`
- **Type**: `Provider<AccountRepository>`
- **Location**: `lib/features/mail/presentation/providers/onboarding_provider.dart`
- **Purpose**: Data access layer for email accounts
- **Replacement Strategy**: Create `AccountRepository` as singleton via Service Locator
- **Methods Exposed**:
  - `hasAccounts()`, `getAllAccounts()`, `getAccount()`, `saveAccountWithPassword()`, `saveAccountWithOAuth()`, `deleteAccount()`, `updateAccount()`, `updatePassword()`
- **Watched By**:
  - `OnboardingNotifier.build()`
  - `InboxNotifier.build()`
  - `AccountSettingsNotifier` (via `_repository` member)
  - All onboarding-related pages

#### Service 3: `emailRepositoryProvider`
- **Type**: `Provider<EmailRepository>`
- **Location**: `lib/features/mail/presentation/providers/inbox_provider.dart`
- **Purpose**: Data access layer for emails and mailboxes
- **Replacement Strategy**: Create `EmailRepository` as singleton via Service Locator
- **Dependencies**: `accountRepositoryProvider`, local/remote data sources
- **Methods Exposed**:
  - `hasAccounts()`, `getMailboxes()`, `getEmails()`, `syncMailboxes()`, `syncEmails()`, `selectMailbox()`, `selectEmail()`, `markAsRead()`, `markAsUnread()`, `setReadStatus()`, `setStarredStatus()`, `toggleStarred()`, `deleteEmail()`, `moveEmail()`, `archiveEmail()`, `createMailbox()`, `disconnect()`, `fetchFullEmail()`
- **Watched By**:
  - `InboxNotifier.build()`

#### Service 4: `networkMeteredServiceProvider`
- **Type**: `Provider<NetworkMeteredService>`
- **Location**: `lib/core/services/network_metered_service.dart`
- **Purpose**: Detects if active network is metered (mobile/limited data)
- **Replacement Strategy**: Create `NetworkMeteredService` as singleton
- **Methods Exposed**:
  - `isActiveNetworkMetered()` - async method
- **Watched By**:
  - `InboxNotifier.prefetchCommonMailboxes()` - reads via `ref.read()`

#### Service 5: `storageServiceProvider`
- **Type**: `Provider<StorageService>`
- **Location**: `lib/features/mail/presentation/pages/storage_settings_page.dart`
- **Purpose**: Local storage management (cache, attachments, email data)
- **Replacement Strategy**: Create `StorageService` as singleton
- **Methods Exposed**:
  - `getStorageInfo()`, `clearCache()`, `clearAttachments()`, `clearEmailData()`
- **Watched By**:
  - `StorageSettingsPage` - reads via `ref.read()` for mutations

---

### 1.2 Future Providers (Async Data Providers)

#### FutureProvider 1: `hasAccountsProvider`
- **Type**: `FutureProvider<bool>`
- **Location**: `lib/features/mail/presentation/providers/onboarding_provider.dart`
- **Purpose**: Check if user has any saved email accounts
- **State Type**: `AsyncValue<bool>`
- **Computation**: `repository.hasAccounts()`
- **Watched By**:
  - `AppShell._AppShellState.build()` - watches via `ref.watch()`
  - `InboxPage._InboxPageState._navigateToAddAccount()` - invalidates
  - `InboxPage._InboxPageState._confirmRemoveAccount()` - invalidates
- **Invalidation Triggers**:
  - When account added in onboarding
  - When account removed from inbox
- **Replacement Strategy**: Create computed property in `AccountListNotifier` or use stream-based provider

#### FutureProvider 2: `allAccountsProvider`
- **Type**: `FutureProvider<List<EmailAccount>>`
- **Location**: `lib/features/mail/presentation/providers/onboarding_provider.dart`
- **Purpose**: Load all user's email accounts
- **State Type**: `AsyncValue<List<EmailAccount>>`
- **Computation**: `repository.getAllAccounts()`
- **Watched By**:
  - `InboxPage._InboxPageState.build()` - watches via `ref.watch()`
  - `InboxPage._InboxPageState._navigateToSettings()` - invalidates
  - `InboxNotifier.initialize()` - reads via `ref.read()`
  - `InboxNotifier.selectAccount()` - reads via `ref.read()`
  - `InboxNotifier.syncMailboxes()` - reads via `ref.read()`
  - `InboxNotifier.syncEmails()` - reads via `ref.read()`
  - `InboxNotifier.selectMailbox()` - reads via `ref.read()`
  - `InboxNotifier.removeAccount()` - invalidates
  - `SettingsPage.build()` - watches `accountsListProvider` (similar)
- **Invalidation Triggers**:
  - After account added/removed/updated
  - When returning from settings
- **Replacement Strategy**: Create `AccountListNotifier(ChangeNotifier)` that manages account list state

#### FutureProvider 3: `accountsListProvider`
- **Type**: `FutureProvider<List<EmailAccount>>`
- **Location**: `lib/features/mail/presentation/providers/settings_provider.dart`
- **Purpose**: Load all accounts for settings page display
- **State Type**: `AsyncValue<List<EmailAccount>>`
- **Computation**: `repository.getAllAccounts()`
- **Watched By**:
  - `SettingsPage.build()` - watches via `ref.watch()`
  - `SettingsPage._openAccountSettings()` - invalidates after closing
- **Replacement Strategy**: Use same `AccountListNotifier` from `allAccountsProvider`

#### FutureProvider 4: `storageInfoProvider`
- **Type**: `FutureProvider<StorageInfo>`
- **Location**: `lib/features/mail/presentation/pages/storage_settings_page.dart`
- **Purpose**: Get storage usage information
- **State Type**: `AsyncValue<StorageInfo>`
- **Computation**: `storageService.getStorageInfo()`
- **Watched By**:
  - `StorageSettingsPage.build()` - watches via `ref.watch()`
- **Invalidation Triggers**:
  - After clearing cache, attachments, or email data
  - Multiple calls to `ref.invalidate(storageInfoProvider)`
- **Replacement Strategy**: Create `StorageInfoNotifier(ChangeNotifier)` with refresh method

#### FutureProvider 5: `selectedEmailProvider`
- **Type**: `FutureProvider<EmailMessage?>`
- **Location**: `lib/features/mail/presentation/providers/inbox_provider.dart`
- **Purpose**: Fetch full email content (HTML/text body) for selected email
- **State Type**: `AsyncValue<EmailMessage?>`
- **Computation**: 
  - Returns cached email if full body already available
  - Otherwise fetches from server via `repository.fetchFullEmail()`
- **Watched By**: Not explicitly watched in current code, but computed based on `inboxProvider.selectedEmail`
- **Replacement Strategy**: Move to `InboxNotifier` as lazy-loaded property or separate method

---

### 1.3 Notifier Providers (State Management)

#### StateNotifier 1: `onboardingProvider`
- **Type**: `NotifierProvider<OnboardingNotifier, OnboardingState>`
- **Location**: `lib/features/mail/presentation/providers/onboarding_provider.dart`
- **State Class**: `OnboardingState`
  - Fields: `selectedProvider`, `email`, `password`, `displayName`, `imapHost`, `imapPort`, `smtpHost`, `smtpPort`, `useSsl`, `isLoading`, `isValidating`, `statusMessage`, `error`, `addedAccounts`
  - Computed: `providerConfig`, `canSave`, `resetForNewAccount()`
- **Notifier Class**: `OnboardingNotifier extends Notifier<OnboardingState>`
  - Dependencies: `accountRepositoryProvider`, `imapConnectionServiceProvider`
  - Methods:
    - `selectProvider(MailProvider)` - updates selected provider & pre-fills server config
    - `setEmail(String)`, `setPassword(String)`, `setDisplayName(String)`
    - `setImapHost(String)`, `setImapPort(int)`, `setSmtpHost(String)`, `setSmtpPort(int)`
    - `setUseSsl(bool)` - via `setUseSsl({required bool useSsl})`
    - `saveAccountWithPassword()` - async: validates IMAP connection, saves account
    - `saveAccountWithOAuth()` - async: saves OAuth tokens
    - `startNewAccount()` - resets state for adding another account
    - `clearError()` - clears error messages
- **Watched By**:
  - `ProviderSelectionPage.build()` - watches state, reads notifier
  - `ImapConfigPage._ImapConfigPageState.initState()` - reads state
  - `ImapConfigPage._ImapConfigPageState._submit()` - reads state, reads notifier
  - `ImapConfigPage._ImapConfigPageState._openHelpUrl()` - reads state
  - `ImapConfigPage.build()` - watches state
  - `OAuthPage` - no direct usage (placeholder implementation)
  - `AccountSummaryPage.build()` - watches state, reads notifier
  - `OnboardingPage` - no direct provider access (orchestrates child pages)
- **Invalidation**: Not explicitly invalidated; state persists or reset via `startNewAccount()`
- **Replacement Strategy**: Create `OnboardingNotifier extends ChangeNotifier` with same methods

#### StateNotifier 2: `inboxProvider`
- **Type**: `NotifierProvider<InboxNotifier, InboxState>`
- **Location**: `lib/features/mail/presentation/providers/inbox_provider.dart`
- **State Class**: `InboxState`
  - Fields: `selectedAccountId`, `selectedMailboxPath`, `emails`, `mailboxes`, `isLoading`, `isSyncing`, `error`, `selectedEmailId`, `prefetchSuccessCount`, `prefetchFailureCount`
  - Computed: `selectedEmail`, `inboxMailbox`, `totalUnread`
- **Notifier Class**: `InboxNotifier extends Notifier<InboxState>`
  - Dependencies: `emailRepositoryProvider`, lifecycle observer
  - Methods:
    - `initialize()` - async: loads first account or unified view
    - `selectAccount(String?)` - async: switches account, loads mailboxes/emails
    - `prefetchCommonMailboxes()` - async: background prefetch with metered network detection
    - `syncMailboxes()` - async: syncs mailbox list from server
    - `syncEmails({bool fullSync})` - async: syncs email list for current mailbox
    - `selectMailbox(String)` - async: loads emails for mailbox
    - `selectEmail(String)` - async: marks as read if needed
    - `clearSelection()` - clears selected email
    - `markAsRead(EmailMessage)` - async: marks as read, updates local state
    - `markAsUnread(EmailMessage)` - async: marks as unread
    - `toggleStarred(EmailMessage)` - async: toggles starred flag
    - `deleteEmail(EmailMessage)` - async: archives or deletes
    - `archiveEmail(EmailMessage)` - async: moves to archive
    - `refresh()` - async: full sync
    - `clearError()` - clears error
    - `removeAccount(String)` - async: deletes account, returns bool for remaining accounts
- **Watched By**:
  - `InboxPage._InboxPageState.build()` - watches state
  - `InboxPage._InboxPageState.initState()` - reads notifier for `initialize()`
  - `InboxPage._MailSidebar._build()` - receives state as parameter
  - `InboxPage._EmailListPane._build()` - receives state as parameter
  - Sidebar: reads notifier for `selectMailbox()`, `selectAccount()`, etc.
  - Email list: reads notifier for `selectEmail()`, `refresh()`, etc.
- **Invalidation**: `ref.invalidate(allAccountsProvider)` called when accounts change
- **Replacement Strategy**: Create `InboxNotifier extends ChangeNotifier` with same methods, handle invalidations via notification callbacks

#### StateNotifier 3: `accountSettingsNotifierProvider`
- **Type**: `Provider.autoDispose.family<AccountSettingsNotifier, String>`
- **Location**: `lib/features/mail/presentation/providers/settings_provider.dart`
- **Factory Argument**: Account ID (String)
- **State Class**: `AccountSettingsState`
  - Fields: `account`, `displayName`, `signature`, `replyTo`, `syncFrequencyMinutes`, `isActive`, `isLoading`, `isSaving`, `isValidatingPassword`, `statusMessage`, `error`, `successMessage`
  - Computed: `hasChanges` - compares current values with original account
- **Notifier Class**: `AccountSettingsNotifier` (custom implementation, not extends Notifier)
  - Pattern: Manual listener management, not using Riverpod's Notifier base
  - Dependencies: `accountRepositoryProvider`, `imapConnectionServiceProvider` (injected via Ref)
  - Methods:
    - `loadAccount()` - async: loads account from repository
    - `setDisplayName(String)`, `setSignature(String)`, `setReplyTo(String)`
    - `setSyncFrequency(int)`, `setActive(bool)`
    - `saveChanges()` - async: validates and updates account
    - `updatePassword(String)` - async: validates new password then saves
    - `deleteAccount()` - async: deletes account
    - `clearMessages()` - clears status/error/success messages
    - `addListener(Function)`, `removeListener(Function)` - manual listener management
  - State Getter: `get state` returns current `AccountSettingsState`
- **Watched By**:
  - `AccountSettingsPage._AccountSettingsPageState.didChangeDependencies()` - reads notifier
  - `AccountSettingsPage._AccountSettingsPageState._onStateChanged()` - listener callback
  - Manual state subscription via `_notifier.addListener()`
- **Invalidation**: None (not using Riverpod's invalidation)
- **Replacement Strategy**: Convert to `extends ChangeNotifier` directly, replace manual listener with `notifyListeners()`

---

## PART 2: WIDGET REFACTORING MAPPING

### 2.1 ConsumerStatefulWidget → StatefulWidget Refactoring

| Widget | File | Consumer Usage | Refactoring Tasks |
|--------|------|----------------|-------------------|
| **AppShell** | `lib/main.dart` | `ConsumerState` watching `hasAccountsProvider` | 1. Wrap with provider listener 2. Move `ref.watch()` to listener callback 3. Trigger navigation based on state changes |
| **InboxPage** | `lib/features/mail/presentation/pages/inbox_page.dart` | `ConsumerState` watching `inboxProvider`, `allAccountsProvider` | 1. Add `InboxNotifier` & `AccountListNotifier` to build context 2. Watch changes via listeners 3. Remove `ref.watch()`, `ref.read()` calls 4. Pass notifiers to child widgets |
| **OnboardingPage** | `lib/features/mail/presentation/pages/onboarding_page.dart` | `ConsumerStatefulWidget` managing navigation | No direct provider dependency, but orchestrates child pages that use providers |
| **ImapConfigPage** | `lib/features/mail/presentation/pages/imap_config_page.dart` | `ConsumerState` with `onboardingProvider` reads | 1. Inject `OnboardingNotifier` 2. Replace `ref.read(onboardingProvider)` with direct notifier calls 3. Remove Riverpod imports |
| **OAuthPage** | `lib/features/mail/presentation/pages/oauth_page.dart` | `ConsumerStatefulWidget` (not using providers currently) | No changes needed (placeholder) |
| **AccountSettingsPage** | `lib/features/mail/presentation/pages/account_settings_page.dart` | `ConsumerState` reading `accountSettingsNotifierProvider` | 1. Inject `AccountSettingsNotifier` via factory parameter 2. Already using manual listener pattern 3. Remove `ref.read()`, switch to direct notifier |
| **StorageSettingsPage** | `lib/features/mail/presentation/pages/storage_settings_page.dart` | `ConsumerStatefulWidget` with manual state | 1. Inject `StorageService` 2. Create `StorageInfoNotifier` 3. Replace `ref.read()` and `ref.invalidate()` with notifier methods |

### 2.2 ConsumerWidget → StatelessWidget Refactoring

| Widget | File | Consumer Usage | Refactoring Tasks |
|--------|------|----------------|-------------------|
| **SettingsPage** | `lib/features/mail/presentation/pages/settings_page.dart` | `ConsumerWidget` watching `accountsListProvider` | 1. Wrap child in `Selector` or `Consumer` using `AccountListNotifier` 2. Move `ref.watch(accountsListProvider)` to listener 3. Update account list when returning from child |
| **ProviderSelectionPage** | `lib/features/mail/presentation/pages/provider_selection_page.dart` | `ConsumerWidget` watching `onboardingProvider` | 1. Inject `OnboardingNotifier` 2. Watch state via `ListenableBuilder` 3. Replace `ref.watch()`, `ref.read()` with notifier calls |
| **AccountSummaryPage** | `lib/features/mail/presentation/pages/account_summary_page.dart` | `ConsumerWidget` watching `onboardingProvider` | 1. Inject `OnboardingNotifier` 2. Watch via `ListenableBuilder` 3. Replace `ref.watch()`, `ref.read()` with notifier calls |

---

## PART 3: DETAILED REFACTORING TASKS

### 3.1 Create ChangeNotifier Services/Notifiers

#### Task 3.1.1: Create `OnboardingNotifier` (ChangeNotifier)
```
File: lib/features/mail/presentation/notifiers/onboarding_notifier.dart
```
**Changes**:
- Extract state class to separate file
- Convert `Notifier<OnboardingState>` to `extends ChangeNotifier`
- Replace `state = state.copyWith(...)` with `state = state.copyWith(...); notifyListeners()`
- Keep all methods identical
- Constructor: accept `AccountRepository` and `ImapConnectionService` as parameters
- Remove `ref.watch()` dependencies; inject via constructor

#### Task 3.1.2: Create `InboxNotifier` (ChangeNotifier)
```
File: lib/features/mail/presentation/notifiers/inbox_notifier.dart
```
**Changes**:
- Extract state class to separate file
- Convert `Notifier<InboxState>` to `extends ChangeNotifier`
- Replace `state = state.copyWith(...)` with `state = state.copyWith(...); notifyListeners()`
- Keep lifecycle observer pattern
- Constructor: accept `EmailRepository` and other dependencies
- Handle `ref.read(allAccountsProvider.future)` → need `AccountListNotifier` to provide this
- Handle `ref.read(networkMeteredServiceProvider)` → inject `NetworkMeteredService`
- Handle `ref.invalidate(allAccountsProvider)` → call callback on `AccountListNotifier`
- Handle `ref.invalidate(hasAccountsProvider)` → callback to parent widget

#### Task 3.1.3: Create `AccountListNotifier` (ChangeNotifier)
```
File: lib/features/mail/presentation/notifiers/account_list_notifier.dart
```
**Purpose**: Consolidate `hasAccountsProvider` and `allAccountsProvider` functionality
**State**:
```
class AccountListState {
  final List<EmailAccount> accounts;
  final bool isLoading;
  final String? error;
  
  bool get hasAccounts => accounts.isNotEmpty;
}
```
**Methods**:
- `loadAccounts()` - async, fetches from repository
- `refreshAccounts()` - async, forcefully reloads
- Constructor: inject `AccountRepository`

#### Task 3.1.4: Create `StorageInfoNotifier` (ChangeNotifier)
```
File: lib/features/mail/presentation/notifiers/storage_info_notifier.dart
```
**State**:
```
class StorageState {
  final StorageInfo? info;
  final bool isLoading;
  final String? error;
}
```
**Methods**:
- `loadStorageInfo()` - async
- `refreshStorageInfo()` - async
- Constructor: inject `StorageService`

#### Task 3.1.5: Convert `AccountSettingsNotifier`
```
File: lib/features/mail/presentation/notifiers/account_settings_notifier.dart
```
**Changes**:
- Already has custom listener pattern; convert to `extends ChangeNotifier`
- Replace manual `_listeners` list with `notifyListeners()`
- Keep factory pattern for account ID parameterization
- Constructor: inject `Ref`, `String accountId`, `AccountRepository`, `ImapConnectionService`

---

### 3.2 Update App Shell & Root Widget

#### Task 3.2.1: Modify `AppShell` in `lib/main.dart`
**Current**:
```dart
class AppShell extends ConsumerStatefulWidget { ... }
class _AppShellState extends ConsumerState<AppShell> {
  Widget build(BuildContext context) {
    final hasAccountsAsync = ref.watch(hasAccountsProvider);
```

**Target**:
```dart
class AppShell extends StatefulWidget { ... }
class _AppShellState extends State<AppShell> {
  late AccountListNotifier _accountListNotifier;
  
  @override
  void initState() {
    _accountListNotifier = AccountListNotifier(accountRepository);
    _accountListNotifier.loadAccounts();
    _accountListNotifier.addListener(_onAccountsChanged);
    super.initState();
  }
  
  void _onAccountsChanged() {
    setState(() {}); // Rebuild on account changes
  }
  
  Widget build(BuildContext context) {
    final hasAccounts = _accountListNotifier.state.hasAccounts;
    if (_accountListNotifier.state.isLoading) {
      return loadingScaffold();
    }
    // Navigate to onboarding or inbox based on hasAccounts
```

---

### 3.3 Update Pages Using Providers

#### Task 3.3.1: Update `InboxPage`
**Changes**:
1. Change `extends ConsumerStatefulWidget` → `extends StatefulWidget`
2. Create notifier instances in `initState()`:
   ```dart
   late InboxNotifier _inboxNotifier;
   late AccountListNotifier _accountListNotifier;
   
   @override
   void initState() {
     _accountListNotifier = AccountListNotifier(accountRepository);
     _inboxNotifier = InboxNotifier(emailRepository, _accountListNotifier);
     _inboxNotifier.initialize();
     _inboxNotifier.addListener(_onInboxChanged);
     _accountListNotifier.addListener(_onAccountsChanged);
     super.initState();
   }
   ```
3. Replace `ref.watch(inboxProvider)` → `_inboxNotifier.state`
4. Replace `ref.watch(allAccountsProvider)` → `_accountListNotifier.state.accounts`
5. Replace `ref.read(inboxProvider.notifier).method()` → `_inboxNotifier.method()`
6. Replace `ref.invalidate(allAccountsProvider)` → `_accountListNotifier.refreshAccounts()`
7. Pass notifier to sidebar/email list widgets:
   ```dart
   _MailSidebar(
     onMailboxSelected: (path) => _inboxNotifier.selectMailbox(path),
     onAccountSelected: (id) => _inboxNotifier.selectAccount(id),
   )
   ```

#### Task 3.3.2: Update `SettingsPage`
**Changes**:
1. Change `extends ConsumerWidget` → `extends StatefulWidget`
2. Or keep as `StatelessWidget` and wrap in `ListenableBuilder`:
   ```dart
   @override
   Widget build(BuildContext context) {
     return ListenableBuilder(
       listenable: _accountListNotifier,
       builder: (context, child) {
         final accountsAsync = _accountListNotifier.state;
         // Rest of build
   ```
3. Replace `ref.watch(accountsListProvider)` with notifier state
4. When returning from account settings, call `_accountListNotifier.refreshAccounts()`

#### Task 3.3.3: Update `ImapConfigPage`
**Changes**:
1. Change `extends ConsumerStatefulWidget` → `extends StatefulWidget`
2. Accept `OnboardingNotifier` in constructor parameter
3. In `initState()`:
   ```dart
   final state = widget.onboardingNotifier.state;
   _emailController = TextEditingController(text: state.email);
   ```
4. In `_submit()`:
   ```dart
   final notifier = widget.onboardingNotifier;
   await notifier.saveAccountWithPassword();
   ```

#### Task 3.3.4: Update `ProviderSelectionPage`
**Changes**:
1. Change `extends ConsumerWidget` → `extends StatelessWidget`
2. Accept `OnboardingNotifier` in constructor
3. Replace `ref.watch(onboardingProvider)` with `ListenableBuilder`:
   ```dart
   ListenableBuilder(
     listenable: widget.onboardingNotifier,
     builder: (context, _) {
       final state = widget.onboardingNotifier.state;
       return ...; // UI
   ```
4. Replace `ref.read(onboardingProvider.notifier).selectProvider()` with direct call

#### Task 3.3.5: Update `AccountSummaryPage`
**Changes**:
1. Change `extends ConsumerWidget` → `extends StatelessWidget`
2. Accept `OnboardingNotifier` in constructor
3. Replace `ref.watch(onboardingProvider)` with `ListenableBuilder`
4. Replace `ref.read(onboardingProvider.notifier).startNewAccount()` with direct call

#### Task 3.3.6: Update `AccountSettingsPage`
**Changes**:
1. Change `extends ConsumerStatefulWidget` → `extends StatefulWidget`
2. Accept `AccountSettingsNotifier` in constructor
3. In `didChangeDependencies()`:
   ```dart
   _notifier = widget.accountSettingsNotifier; // Remove ref.read()
   _notifier.addListener(_onStateChanged);
   ```
4. Replace `ref.read(accountSettingsNotifierProvider(accountId))` with injected notifier
5. No invalidation needed

#### Task 3.3.7: Update `StorageSettingsPage`
**Changes**:
1. Keep or convert to `StatefulWidget`
2. Create `StorageInfoNotifier` in `initState()`
3. Replace `ref.read(storageServiceProvider)` with injected service
4. Replace `ref.invalidate(storageInfoProvider)` with `_storageInfoNotifier.refreshStorageInfo()`
5. In `build()`, replace `ref.watch(storageInfoProvider)` with notifier state

---

## PART 4: DEPENDENCY INJECTION & SERVICE LOCATOR SETUP

### 4.1 Service Locator Pattern with GetIt

```
File: lib/core/di/service_locator.dart
```

**Setup**:
```dart
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // Repositories
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
  
  // Services
  getIt.registerSingleton<ImapConnectionService>(
    ImapConnectionService(),
  );
  
  getIt.registerSingleton<NetworkMeteredService>(
    NetworkMeteredService(),
  );
  
  getIt.registerSingleton<StorageService>(
    StorageService(),
  );
  
  // Notifiers (may be singletons or create new per page)
  // Some notifiers should be created per page/screen to maintain
  // separate state for multiple instances (e.g., AccountSettingsNotifier)
}
```

**In `main.dart`**:
```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator(); // Initialize before runApp
  
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    const UnifyDeskApp(), // Remove ProviderScope
  );
}
```

---

## PART 5: WIDGET TREE & PROVIDER CONSUMER MAPPING

### 5.1 Provider Usage by Widget

```
AppShell (ConsumerStatefulWidget)
├─ hasAccountsProvider (watches) → AccountListNotifier
├─ Conditional Routing:
│  ├─ If !hasAccounts: OnboardingPage
│  └─ If hasAccounts: InboxPage
│
OnboardingPage (StatefulWidget - no providers, orchestrator)
├─ ProviderSelectionPage (ConsumerWidget)
│  └─ onboardingProvider (watches) → OnboardingNotifier
├─ ImapConfigPage (ConsumerStatefulWidget)
│  └─ onboardingProvider (reads notifier) → OnboardingNotifier
├─ OAuthPage (ConsumerStatefulWidget)
│  └─ (no provider usage currently)
└─ AccountSummaryPage (ConsumerWidget)
   └─ onboardingProvider (watches) → OnboardingNotifier

InboxPage (ConsumerStatefulWidget)
├─ inboxProvider (watches) → InboxNotifier
├─ allAccountsProvider (watches) → AccountListNotifier
├─ _MailSidebar (widget)
│  └─ calls inboxProvider.notifier methods
├─ _EmailListPane (widget)
│  └─ calls inboxProvider.notifier methods
└─ _EmailDetailPane (widget)
   └─ calls inboxProvider.notifier methods

SettingsPage (ConsumerWidget)
├─ accountsListProvider (watches) → AccountListNotifier
└─ AccountSettingsPage (ConsumerStatefulWidget)
   └─ accountSettingsNotifierProvider (reads) → AccountSettingsNotifier

StorageSettingsPage (ConsumerStatefulWidget)
├─ storageServiceProvider (reads) → StorageService
├─ storageInfoProvider (watches) → StorageInfoNotifier
└─ Clears cache/attachments/emails (invalidates)
```

---

## PART 6: INVALIDATION & STATE REFRESH MAPPING

### 6.1 Current Riverpod Invalidations → ChangeNotifier Callbacks

| Current Pattern | Location | Target Provider | New Pattern |
|-----------------|----------|-----------------|-------------|
| `ref.invalidate(hasAccountsProvider)` | `AppShell`, `InboxPage` | bool state | `_accountListNotifier.refreshAccounts()` |
| `ref.invalidate(allAccountsProvider)` | `InboxPage`, multiple | `List<EmailAccount>` | `_accountListNotifier.refreshAccounts()` |
| `ref.invalidate(accountsListProvider)` | `SettingsPage` | `List<EmailAccount>` | `_accountListNotifier.refreshAccounts()` |
| `ref.invalidate(storageInfoProvider)` | `StorageSettingsPage` | `StorageInfo` | `_storageInfoNotifier.refreshStorageInfo()` |

### 6.2 Callback Pattern for Cross-Notifier Communication

**Example: InboxNotifier needs to notify AccountListNotifier of changes**

```dart
class InboxNotifier extends ChangeNotifier {
  final EmailRepository _repository;
  final VoidCallback onAccountsChanged; // Callback to refresh account list
  
  Future<bool> removeAccount(String accountId) async {
    // ... remove account logic
    onAccountsChanged(); // Trigger parent to refresh
  }
}
```

**In InboxPage initialization**:
```dart
_inboxNotifier = InboxNotifier(
  emailRepository,
  onAccountsChanged: () => _accountListNotifier.refreshAccounts(),
);
```

---

## PART 7: MIGRATION CHECKLIST

### Phase 1: Infrastructure Setup
- [ ] Create `lib/core/di/service_locator.dart` with GetIt setup
- [ ] Update `pubspec.yaml` to add GetIt dependency, remove flutter_riverpod
- [ ] Create notifier files in `lib/features/mail/presentation/notifiers/`
- [ ] Extract state classes to separate files

### Phase 2: Create ChangeNotifier Classes
- [ ] Create `OnboardingNotifier(ChangeNotifier)` 
- [ ] Create `InboxNotifier(ChangeNotifier)`
- [ ] Create `AccountListNotifier(ChangeNotifier)`
- [ ] Create `StorageInfoNotifier(ChangeNotifier)`
- [ ] Convert `AccountSettingsNotifier` to proper `ChangeNotifier`

### Phase 3: Update Root Widget
- [ ] Remove `ProviderScope` from `main.dart`
- [ ] Call `setupServiceLocator()` in `main()`
- [ ] Update `AppShell` to use `AccountListNotifier`
- [ ] Test routing between onboarding and inbox

### Phase 4: Update Page Widgets (Priority Order)
- [ ] **OnboardingPage**: Update to inject `OnboardingNotifier` to child pages
- [ ] **ProviderSelectionPage**: Replace `ref.watch()` with `ListenableBuilder`
- [ ] **ImapConfigPage**: Replace `ref.read()` with injected notifier
- [ ] **AccountSummaryPage**: Replace `ref.watch()` with `ListenableBuilder`
- [ ] **InboxPage**: Replace both `ref.watch()` calls with notifier instances
- [ ] **SettingsPage**: Replace `ref.watch()` with notifier listener
- [ ] **AccountSettingsPage**: Update to use constructor-injected notifier
- [ ] **StorageSettingsPage**: Create `StorageInfoNotifier` and update

### Phase 5: Testing & Cleanup
- [ ] Run all unit tests (update mocks for notifiers)
- [ ] Test onboarding flow end-to-end
- [ ] Test inbox operations (select account, mailbox, email)
- [ ] Test settings page account management
- [ ] Test storage cleanup operations
- [ ] Remove all `flutter_riverpod` imports
- [ ] Remove all `ConsumerWidget`/`ConsumerStatefulWidget` base classes

---

## PART 8: CODE PATTERNS & EXAMPLES

### 8.1 Basic ChangeNotifier Implementation

```dart
class MyNotifier extends ChangeNotifier {
  MyState _state = const MyState();
  
  MyState get state => _state;
  
  void updateState(MyState newState) {
    _state = newState;
    notifyListeners();
  }
  
  void someMethod() {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();
    
    // Do work...
    
    _state = _state.copyWith(isLoading: false, data: result);
    notifyListeners();
  }
}
```

### 8.2 StatefulWidget with ChangeNotifier

```dart
class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  late MyNotifier _notifier;
  
  @override
  void initState() {
    super.initState();
    _notifier = MyNotifier();
    _notifier.addListener(_onNotifierChanged);
  }
  
  void _onNotifierChanged() {
    setState(() {}); // Rebuild when notifier changes
  }
  
  @override
  void dispose() {
    _notifier.removeListener(_onNotifierChanged);
    _notifier.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final state = _notifier.state;
    return Scaffold(
      body: buildUI(state),
    );
  }
}
```

### 8.3 StatelessWidget with ListenableBuilder

```dart
class MyWidget extends StatelessWidget {
  final MyNotifier notifier;
  
  const MyWidget({required this.notifier, super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        final state = notifier.state;
        return Text('State: ${state.value}');
      },
    );
  }
}
```

### 8.4 Async Operations with ChangeNotifier

```dart
Future<void> saveData() async {
  _state = _state.copyWith(isSaving: true, clearError: true);
  notifyListeners();
  
  try {
    final result = await _repository.save(_state.data);
    _state = _state.copyWith(
      isSaving: false,
      data: result,
      successMessage: 'Saved!',
    );
  } catch (e) {
    _state = _state.copyWith(
      isSaving: false,
      error: e.toString(),
    );
  }
  
  notifyListeners();
}
```

---

## PART 9: MIGRATION IMPACT ANALYSIS

### 9.1 Advantages of ChangeNotifier Migration
1. **Reduced Dependency**: No need for `flutter_riverpod` package
2. **Explicit Wiring**: Dependencies injected explicitly; easier to trace
3. **Smaller Bundle**: Riverpod adds significant code/binary size
4. **Familiar Pattern**: ChangeNotifier is Flutter built-in, requires no external learning
5. **Better Testability**: Services/notifiers easier to mock without provider machinery
6. **Type Safety**: Direct references instead of provider lookups

### 9.2 Implementation Challenges
1. **Manual State Management**: No automatic invalidation; must call refresh manually
2. **More Boilerplate**: Each page needs listener setup/teardown
3. **Context Dependency**: Harder to access notifiers deep in widget tree (solution: service locator)
4. **Lifecycle Management**: Must properly dispose notifiers to avoid memory leaks
5. **Testing**: Need to inject notifiers into pages; more setup in tests

### 9.3 Mitigation Strategies
- Use **Service Locator (GetIt)** for easy notifier access
- Use **ListenableBuilder** to reduce boilerplate in stateless widgets
- Create helper extensions for common patterns
- Implement **comprehensive dispose() logic** to prevent leaks
- Document **state flow diagrams** for complex pages

---

## PART 10: FILE STRUCTURE AFTER MIGRATION

```
lib/
├─ core/
│  └─ di/
│     └─ service_locator.dart (NEW)
├─ features/
│  └─ mail/
│     ├─ presentation/
│     │  ├─ notifiers/ (NEW)
│     │  │  ├─ onboarding_notifier.dart (MOVED from providers/)
│     │  │  ├─ onboarding_state.dart (EXTRACTED)
│     │  │  ├─ inbox_notifier.dart (MOVED from providers/)
│     │  │  ├─ inbox_state.dart (EXTRACTED)
│     │  │  ├─ account_list_notifier.dart (NEW)
│     │  │  ├─ account_list_state.dart (NEW)
│     │  │  ├─ storage_info_notifier.dart (NEW)
│     │  │  ├─ storage_info_state.dart (NEW)
│     │  │  ├─ account_settings_notifier.dart (CONVERTED)
│     │  │  └─ account_settings_state.dart (EXTRACTED)
│     │  ├─ providers/ (DEPRECATED)
│     │  │  ├─ onboarding_provider.dart (DELETE/ARCHIVE)
│     │  │  ├─ inbox_provider.dart (DELETE/ARCHIVE)
│     │  │  └─ settings_provider.dart (DELETE/ARCHIVE)
│     │  └─ pages/
│     │     ├─ *.dart (UPDATED with ChangeNotifier usage)
```

---

## SUMMARY

This refactoring plan provides a complete blueprint for migrating UnifyDesk from Riverpod to ChangeNotifier:

1. **14 Providers identified** with full dependency mapping
2. **7 Notifier classes** documented for creation/conversion
3. **7 Pages** scheduled for widget pattern conversion
4. **Service Locator setup** with GetIt for dependency injection
5. **Migration checklist** organized in 5 phases
6. **Code patterns** provided for common scenarios

**Estimated Effort**: 40-60 development hours
**Risk Level**: Medium (careful attention to lifecycle and disposal needed)
**Testing Requirement**: Comprehensive integration tests for onboarding, inbox, and settings flows
