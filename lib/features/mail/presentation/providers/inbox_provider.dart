import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/email_local_datasource.dart';
import '../../data/datasources/imap_remote_datasource.dart';
import '../../data/repositories/email_repository_impl.dart';
import '../../domain/entities/email_message.dart';
import '../../domain/entities/mailbox.dart';
import '../../domain/repositories/email_repository.dart';
import 'onboarding_provider.dart';

/// Provider for the email repository.
final emailRepositoryProvider = Provider<EmailRepository>((ref) {
  final accountRepo = ref.watch(accountRepositoryProvider);
  return EmailRepositoryImpl(
    accountRepository: accountRepo,
    localDataSource: EmailLocalDataSource(),
    remoteDataSource: ImapRemoteDataSource(),
  );
});

/// State for the inbox.
class InboxState {
  const InboxState({
    this.selectedAccountId,
    this.selectedMailboxPath = 'INBOX',
    this.emails = const [],
    this.mailboxes = const [],
    this.isLoading = false,
    this.isSyncing = false,
    this.error,
    this.selectedEmailId,
  });

  final String? selectedAccountId;
  final String selectedMailboxPath;
  final List<EmailMessage> emails;
  final List<Mailbox> mailboxes;
  final bool isLoading;
  final bool isSyncing;
  final String? error;
  final String? selectedEmailId;

  InboxState copyWith({
    String? selectedAccountId,
    String? selectedMailboxPath,
    List<EmailMessage>? emails,
    List<Mailbox>? mailboxes,
    bool? isLoading,
    bool? isSyncing,
    String? error,
    String? selectedEmailId,
    bool clearError = false,
    bool clearSelectedEmail = false,
  }) {
    return InboxState(
      selectedAccountId: selectedAccountId ?? this.selectedAccountId,
      selectedMailboxPath: selectedMailboxPath ?? this.selectedMailboxPath,
      emails: emails ?? this.emails,
      mailboxes: mailboxes ?? this.mailboxes,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      error: clearError ? null : (error ?? this.error),
      selectedEmailId:
          clearSelectedEmail ? null : (selectedEmailId ?? this.selectedEmailId),
    );
  }

  /// Get the currently selected email.
  EmailMessage? get selectedEmail {
    if (selectedEmailId == null) return null;
    try {
      return emails.firstWhere((e) => e.id == selectedEmailId);
    } catch (_) {
      return null;
    }
  }

  /// Get inbox mailbox.
  Mailbox? get inboxMailbox {
    try {
      return mailboxes.firstWhere((m) => m.isInbox);
    } catch (_) {
      return null;
    }
  }

  /// Get total unread count.
  int get totalUnread => inboxMailbox?.unreadMessages ?? 0;
}

/// Notifier for inbox state management.
class InboxNotifier extends Notifier<InboxState> {
  late EmailRepository _repository;

  @override
  InboxState build() {
    _repository = ref.watch(emailRepositoryProvider);
    return const InboxState();
  }

  /// Initialize inbox with the first account.
  Future<void> initialize() async {
    final accounts = await ref.read(allAccountsProvider.future);
    if (accounts.isEmpty) return;

    await selectAccount(accounts.first.id);
  }

  /// Select an account and load its mailboxes.
  Future<void> selectAccount(String accountId) async {
    state = state.copyWith(
      selectedAccountId: accountId,
      isLoading: true,
      clearError: true,
    );

    try {
      // Load cached mailboxes first
      final cachedMailboxes = await _repository.getMailboxes(accountId);
      if (cachedMailboxes.isNotEmpty) {
        state = state.copyWith(mailboxes: cachedMailboxes);
      }

      // Load cached emails for inbox
      final cachedEmails = await _repository.getEmails(accountId, 'INBOX');
      state = state.copyWith(
        emails: cachedEmails,
        isLoading: false,
      );

      // Sync in background
      await syncMailboxes();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Sync mailboxes from server.
  Future<void> syncMailboxes() async {
    final accountId = state.selectedAccountId;
    if (accountId == null) return;

    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      final mailboxes = await _repository.syncMailboxes(accountId);
      state = state.copyWith(mailboxes: mailboxes, isSyncing: false);

      // Also sync current mailbox emails
      await syncEmails();
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: 'Sync failed: $e',
      );
    }
  }

  /// Sync emails from current mailbox.
  Future<void> syncEmails({bool fullSync = false}) async {
    final accountId = state.selectedAccountId;
    if (accountId == null) return;

    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      final emails = await _repository.syncEmails(
        accountId,
        state.selectedMailboxPath,
        fullSync: fullSync,
      );
      state = state.copyWith(emails: emails, isSyncing: false);
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: 'Email sync failed: $e',
      );
    }
  }

  /// Select a mailbox.
  Future<void> selectMailbox(String mailboxPath) async {
    if (state.selectedAccountId == null) return;

    state = state.copyWith(
      selectedMailboxPath: mailboxPath,
      isLoading: true,
      clearSelectedEmail: true,
    );

    try {
      // Load cached emails
      final cachedEmails = await _repository.getEmails(
        state.selectedAccountId!,
        mailboxPath,
      );
      state = state.copyWith(emails: cachedEmails, isLoading: false);

      // Sync in background
      await syncEmails();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Select an email.
  Future<void> selectEmail(String emailId) async {
    state = state.copyWith(selectedEmailId: emailId);

    // Mark as read if not already
    final email = state.selectedEmail;
    if (email != null && !email.isRead) {
      await markAsRead(email);
    }
  }

  /// Clear email selection.
  void clearSelection() {
    state = state.copyWith(clearSelectedEmail: true);
  }

  /// Mark email as read.
  Future<void> markAsRead(EmailMessage email) async {
    if (state.selectedAccountId == null) return;

    try {
      await _repository.setReadStatus(
        state.selectedAccountId!,
        email.mailboxName,
        email.id,
        email.uid,
        isRead: true,
      );

      // Update local state
      final updatedEmails = state.emails.map((e) {
        if (e.id == email.id) {
          return e.copyWith(isRead: true);
        }
        return e;
      }).toList();

      state = state.copyWith(emails: updatedEmails);
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark as read: $e');
    }
  }

  /// Mark email as unread.
  Future<void> markAsUnread(EmailMessage email) async {
    if (state.selectedAccountId == null) return;

    try {
      await _repository.setReadStatus(
        state.selectedAccountId!,
        email.mailboxName,
        email.id,
        email.uid,
        isRead: false,
      );

      final updatedEmails = state.emails.map((e) {
        if (e.id == email.id) {
          return e.copyWith(isRead: false);
        }
        return e;
      }).toList();

      state = state.copyWith(emails: updatedEmails);
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark as unread: $e');
    }
  }

  /// Toggle email starred status.
  Future<void> toggleStarred(EmailMessage email) async {
    if (state.selectedAccountId == null) return;

    try {
      await _repository.setStarredStatus(
        state.selectedAccountId!,
        email.mailboxName,
        email.id,
        email.uid,
        isStarred: !email.isStarred,
      );

      final updatedEmails = state.emails.map((e) {
        if (e.id == email.id) {
          return e.copyWith(isStarred: !email.isStarred);
        }
        return e;
      }).toList();

      state = state.copyWith(emails: updatedEmails);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update starred status: $e');
    }
  }

  /// Delete email.
  Future<void> deleteEmail(EmailMessage email) async {
    if (state.selectedAccountId == null) return;

    try {
      await _repository.deleteEmail(
        state.selectedAccountId!,
        email.mailboxName,
        email.id,
        email.uid,
      );

      // Remove from local state
      final updatedEmails =
          state.emails.where((e) => e.id != email.id).toList();
      state = state.copyWith(
        emails: updatedEmails,
        clearSelectedEmail: state.selectedEmailId == email.id,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete email: $e');
    }
  }

  /// Refresh inbox.
  Future<void> refresh() async {
    await syncEmails(fullSync: true);
  }

  /// Clear error.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Remove an account. Returns true if there are remaining accounts.
  Future<bool> removeAccount(String accountId) async {
    try {
      // Get the account repository
      final accountRepo = ref.read(accountRepositoryProvider);

      // Delete the account
      await accountRepo.deleteAccount(accountId);

      // Disconnect from IMAP if this was the selected account
      if (state.selectedAccountId == accountId) {
        await _repository.disconnect();
      }

      // Invalidate providers to refresh data
      ref..invalidate(allAccountsProvider)
      ..invalidate(hasAccountsProvider);

      // Check if there are remaining accounts
      final remainingAccounts = await ref.read(allAccountsProvider.future);

      if (remainingAccounts.isEmpty) {
        // Reset state
        state = const InboxState();
        return false;
      }

      // If we deleted the selected account, switch to another
      if (state.selectedAccountId == accountId) {
        await selectAccount(remainingAccounts.first.id);
      }

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to remove account: $e');
      return true; // Assume accounts remain on error
    }
  }
}

/// Provider for inbox state.
final inboxProvider = NotifierProvider<InboxNotifier, InboxState>(
  InboxNotifier.new,
);

/// Provider for the selected email with full content.
final selectedEmailProvider = FutureProvider<EmailMessage?>((ref) async {
  final inboxState = ref.watch(inboxProvider);
  final email = inboxState.selectedEmail;

  if (email == null) return null;

  // Check if we already have full body content (HTML or full text, not just preview)
  final hasHtmlBody = email.htmlBody != null && email.htmlBody!.isNotEmpty;
  final hasFullTextBody =
      email.textBody != null && email.textBody!.length > 200;

  if (hasHtmlBody || hasFullTextBody) {
    return email;
  }

  // Otherwise, fetch full content from server
  if (inboxState.selectedAccountId != null) {
    final repository = ref.read(emailRepositoryProvider);
    final fullEmail = await repository.fetchFullEmail(
      inboxState.selectedAccountId!,
      email.mailboxName,
      email.uid,
    );
    return fullEmail ?? email;
  }

  return email;
});
