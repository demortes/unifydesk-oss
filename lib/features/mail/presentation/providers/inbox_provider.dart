import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unifydesk/core/services/network_metered_service.dart';
import 'package:logger/logger.dart';

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
    this.prefetchSuccessCount = 0,
    this.prefetchFailureCount = 0,
  });

  final String? selectedAccountId;
  final String selectedMailboxPath;
  final List<EmailMessage> emails;
  final List<Mailbox> mailboxes;
  final bool isLoading;
  final bool isSyncing;
  final String? error;
  final String? selectedEmailId;
  final int prefetchSuccessCount;
  final int prefetchFailureCount;

  InboxState copyWith({
    String? selectedAccountId,
    String? selectedMailboxPath,
    List<EmailMessage>? emails,
    List<Mailbox>? mailboxes,
    bool? isLoading,
    bool? isSyncing,
    String? error,
    String? selectedEmailId,
    int? prefetchSuccessCount,
    int? prefetchFailureCount,
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
      prefetchSuccessCount: prefetchSuccessCount ?? this.prefetchSuccessCount,
      prefetchFailureCount: prefetchFailureCount ?? this.prefetchFailureCount,
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

/// Simple lifecycle observer that reports active/background state via callback.
class _LifecycleObserver with WidgetsBindingObserver {
  _LifecycleObserver(this._onActiveChanged);

  final void Function(bool active) _onActiveChanged;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _onActiveChanged(state == AppLifecycleState.resumed);
  }
}

/// Notifier for inbox state management.
class InboxNotifier extends Notifier<InboxState> {
  late EmailRepository _repository;
  final Logger _logger = Logger();
  bool _isLifecycleObserverAttached = false;
  bool _isAppActive = true;

  static const int _defaultPrefetchDelaySeconds = 2;

  @override
  InboxState build() {
    _repository = ref.watch(emailRepositoryProvider);
    // Attach lifecycle observer once
    if (!_isLifecycleObserverAttached) {
      WidgetsBinding.instance.addObserver(_LifecycleObserver((active) {
        _isAppActive = active;
      }),);
      _isLifecycleObserverAttached = true;
    }

    return const InboxState();
  }

  /// Resolve a unified mailbox key (e.g. 'ARCHIVE') to a real mailbox path
  /// for a specific account, using that account's mailbox list.
  String? _resolveMailboxPathForAccount(String mailboxKey, List<Mailbox> accountMailboxes) {
    // If this is not one of the unified special keys, treat it as a real path
    const special = ['INBOX', 'SENT', 'DRAFTS', 'JUNK', 'TRASH', 'ARCHIVE'];
    if (!special.contains(mailboxKey)) return mailboxKey;

    try {
      if (mailboxKey == 'INBOX') {
        final m = accountMailboxes.firstWhere((m) => m.isInbox);
        return m.path;
      }
    } catch (_) {
      // fallthrough to sensible defaults below
    }

    try {
      if (mailboxKey == 'SENT') {
        final m = accountMailboxes.firstWhere((m) => m.isSent);
        return m.path;
      }
    } catch (_) {}

    try {
      if (mailboxKey == 'DRAFTS') {
        final m = accountMailboxes.firstWhere((m) => m.isDrafts);
        return m.path;
      }
    } catch (_) {}

    try {
      if (mailboxKey == 'JUNK') {
        final m = accountMailboxes.firstWhere((m) => m.isJunk);
        return m.path;
      }
    } catch (_) {}

    try {
      if (mailboxKey == 'TRASH') {
        final m = accountMailboxes.firstWhere((m) => m.isTrash);
        return m.path;
      }
    } catch (_) {}

    // Archive: prefer an actual Archive mailbox, otherwise fallback to Trash if present
    try {
      if (mailboxKey == 'ARCHIVE') {
        final m = accountMailboxes.firstWhere((m) => m.isArchive);
        return m.path;
      }
    } catch (_) {
      try {
        final t = accountMailboxes.firstWhere((m) => m.isTrash);
        return t.path;
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  /// Initialize inbox with the first account.
  Future<void> initialize() async {
    final accounts = await ref.read(allAccountsProvider.future);
    if (accounts.isEmpty) return;

    // Default to unified view across all accounts
    await selectAccount(null);
    // Start background prefetch of common mailboxes to warm cache
    // Do not await to avoid blocking UI initialization
    unawaited(prefetchCommonMailboxes());
  }

  /// Select an account and load its mailboxes.
  Future<void> selectAccount(String? accountId) async {
    state = state.copyWith(
      selectedAccountId: accountId,
      isLoading: true,
      clearError: true,
    );

    try {
      // If accountId is null, show unified mailboxes/emails across all accounts
      if (accountId == null) {
        final accounts = await ref.read(allAccountsProvider.future);

        // Aggregate cached mailboxes for special folders
        final Map<String, Mailbox> aggregated = {};
        for (final acc in accounts) {
          final cachedMailboxes = await _repository.getMailboxes(acc.id);
          for (final m in cachedMailboxes) {
            final key = m.isInbox
                ? 'INBOX'
                : m.isSent
                    ? 'SENT'
                    : m.isDrafts
                        ? 'DRAFTS'
                        : m.isTrash
                            ? 'TRASH'
                            : m.isJunk
                                ? 'JUNK'
                                : m.isArchive
                                    ? 'ARCHIVE'
                                    : m.path;

            final existing = aggregated[key];
            if (existing == null) {
              aggregated[key] = Mailbox(
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
            } else {
              aggregated[key] = existing.copyWith(
                totalMessages: existing.totalMessages + m.totalMessages,
                unreadMessages: existing.unreadMessages + m.unreadMessages,
              );
            }
          }
        }

        // Ensure common special folders exist in the unified view
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

        // Order mailboxes so common folders appear first in a predictable order
        final List<Mailbox> ordered = [];
        for (final key in ['INBOX', 'SENT', 'DRAFTS', 'JUNK', 'TRASH', 'ARCHIVE']) {
          if (aggregated.containsKey(key)) ordered.add(aggregated[key]!);
        }
        // Add any remaining non-special mailboxes alphabetically
        final remaining = aggregated.keys
            .where((k) => !['INBOX', 'SENT', 'DRAFTS', 'JUNK', 'TRASH', 'ARCHIVE'].contains(k))
            .toList()
          ..sort();
        for (final k in remaining) {
          ordered.add(aggregated[k]!);
        }

        state = state.copyWith(
          mailboxes: ordered,
          // default unified selection to INBOX
          selectedMailboxPath: 'INBOX',
        );

        // Aggregate cached emails for selected mailbox path (default INBOX)
        final List<EmailMessage> allEmails = [];
        final selPath = state.selectedMailboxPath;
        final List<String> failures = [];
        for (final acc in accounts) {
          try {
            // Resolve special unified keys (e.g. ARCHIVE) to an actual mailbox path on the account
            String? accountPath;
            try {
              final accountMailboxes = await _repository.getMailboxes(acc.id);
              accountPath = _resolveMailboxPathForAccount(selPath, accountMailboxes);
            } catch (e) {
              accountPath = selPath;
            }

            if (accountPath == null) {
              failures.add('${acc.displayLabel}: no matching mailbox for $selPath');
              continue;
            }

            final cached = await _repository.getEmails(acc.id, accountPath);
            allEmails.addAll(cached);
          } catch (e) {
            failures.add('${acc.displayLabel}: $e');
          }
        }

        // Sort by date descending
        allEmails.sort((a, b) => b.date.compareTo(a.date));

        state = state.copyWith(emails: allEmails, isLoading: false);
        if (allEmails.isEmpty && failures.isNotEmpty) {
          state = state.copyWith(error: 'Failed to load emails for accounts: ${failures.join('; ')}');
        }

        // Sync in background across accounts
        await syncMailboxes();
        // Kick off prefetch for common folders in background
        unawaited(prefetchCommonMailboxes());
        return;
      }

      // Single-account flow (unchanged)
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
      // Kick off prefetch of common folders for this account
      unawaited(prefetchCommonMailboxes());
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Prefetch common mailboxes (INBOX, Sent, Drafts, Junk, Trash, Archive)
  /// across accounts and warm the local DB/cache with recent messages and
  /// optionally their full bodies to speed up rendering when the user opens
  /// a mailbox or message.
  Future<void> prefetchCommonMailboxes({int fullEmailPrefetchCount = 3}) async {
    // Short delay before prefetch to avoid fighting immediate user actions
    await Future.delayed(const Duration(seconds: _defaultPrefetchDelaySeconds));

    try {
      final accounts = await ref.read(allAccountsProvider.future);
      final commonKeys = ['INBOX', 'SENT', 'DRAFTS', 'JUNK', 'TRASH', 'ARCHIVE'];

      // For each account, resolve the mailbox paths for common keys.
      final List<Future<void>> accountTasks = [];
      for (final acc in accounts) {
        // Respect per-account prefetch setting
        if (!acc.prefetchEnabled) {
          _logger.d('Prefetch disabled for account ${acc.email}');
          continue;
        }
        accountTasks.add(Future(() async {
          try {
            final accountMailboxes = await _repository.getMailboxes(acc.id);
            final paths = <String>[];
            for (final key in commonKeys) {
              final path = _resolveMailboxPathForAccount(key, accountMailboxes);
              if (path != null && !paths.contains(path)) paths.add(path);
            }

            // Fetch messages for each common mailbox concurrently but limited
            // to avoid hammering the server.
            const concurrency = 3;
            for (var i = 0; i < paths.length; i += concurrency) {
              final chunk = paths.sublist(i, (i + concurrency) > paths.length ? paths.length : i + concurrency);
              await Future.wait(chunk.map((p) => _repository.syncEmails(acc.id, p).catchError((_) => <EmailMessage>[])));
            }

            // Optionally fetch full bodies for top N recent messages per mailbox
            for (final p in paths) {
              try {
                final emails = await _repository.getEmails(acc.id, p, limit: acc.prefetchCount);
                int success = 0;
                int failure = 0;
                for (final e in emails.take(acc.prefetchCount)) {
                  try {
                    // Pause if app is backgrounded
                    if (!_isAppActive) {
                      _logger.d('App backgrounded — pausing prefetch');
                      break;
                    }

                    // Pause on metered networks (treat mobile as metered)
                    final isMetered = await ref.read(networkMeteredServiceProvider).isActiveNetworkMetered();
                    if (isMetered) {
                      _logger.d('Metered network detected — skipping prefetch for ${acc.email}');
                      break;
                    }

                    await _repository.fetchFullEmail(acc.id, p, e.uid);
                    success++;
                    _logger.d('Prefetched full email ${e.uid} from $p for ${acc.email}');
                  } catch (err) {
                    failure++;
                    _logger.w('Prefetch failed for ${acc.email} $p uid=${e.uid}: $err');
                  }
                }

                // Update simple counters in state for metrics
                if (success > 0 || failure > 0) {
                  state = state.copyWith(
                    prefetchSuccessCount: state.prefetchSuccessCount + success,
                    prefetchFailureCount: state.prefetchFailureCount + failure,
                  );
                }
              } catch (_) {}
            }
          } catch (_) {}
        }),);
      }

      // Run account tasks with limited concurrency
      const accountConcurrency = 2;
      for (var i = 0; i < accountTasks.length; i += accountConcurrency) {
        final chunk = accountTasks.sublist(i, (i + accountConcurrency) > accountTasks.length ? accountTasks.length : i + accountConcurrency);
        await Future.wait(chunk);
      }
    } catch (_) {
      // Ignore prefetch errors silently
    }
  }

  /// Sync mailboxes from server.
  Future<void> syncMailboxes() async {
    final accountId = state.selectedAccountId;
    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      if (accountId == null) {
        // Aggregate synced mailboxes across all accounts
        final accounts = await ref.read(allAccountsProvider.future);
        final Map<String, Mailbox> aggregated = {};
        for (final acc in accounts) {
          final mailboxes = await _repository.syncMailboxes(acc.id);
          for (final m in mailboxes) {
            final key = m.isInbox
                ? 'INBOX'
                : m.isSent
                    ? 'SENT'
                    : m.isDrafts
                        ? 'DRAFTS'
                        : m.isTrash
                            ? 'TRASH'
                            : m.isJunk
                                ? 'JUNK'
                                : m.isArchive
                                    ? 'ARCHIVE'
                                    : m.path;

            final existing = aggregated[key];
            if (existing == null) {
              aggregated[key] = Mailbox(
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
            } else {
              aggregated[key] = existing.copyWith(
                totalMessages: existing.totalMessages + m.totalMessages,
                unreadMessages: existing.unreadMessages + m.unreadMessages,
              );
            }
          }
        }

        // Ensure common special folders exist in the unified view
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

        // Order mailboxes so common folders appear first in a predictable order
        final List<Mailbox> ordered = [];
        for (final key in ['INBOX', 'SENT', 'DRAFTS', 'JUNK', 'TRASH', 'ARCHIVE']) {
          if (aggregated.containsKey(key)) ordered.add(aggregated[key]!);
        }
        // Add any remaining non-special mailboxes alphabetically
        final remaining = aggregated.keys
            .where((k) => !['INBOX', 'SENT', 'DRAFTS', 'JUNK', 'TRASH', 'ARCHIVE'].contains(k))
            .toList()
          ..sort();
        for (final k in remaining) {
          ordered.add(aggregated[k]!);
        }

        state = state.copyWith(mailboxes: ordered, isSyncing: false, selectedMailboxPath: 'INBOX');

        // Sync emails for current mailbox across accounts
        await syncEmails(fullSync: true);
        return;
      }

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
    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      if (accountId == null) {
        // Aggregate emails from all accounts for the selected mailbox path
        final accounts = await ref.read(allAccountsProvider.future);
        final List<EmailMessage> allEmails = [];
        final List<String> failures = [];
        for (final acc in accounts) {
          try {
            String? accountPath;
            try {
              final accountMailboxes = await _repository.getMailboxes(acc.id);
              accountPath = _resolveMailboxPathForAccount(state.selectedMailboxPath, accountMailboxes);
            } catch (e) {
              accountPath = state.selectedMailboxPath;
            }

            if (accountPath == null) {
              failures.add('${acc.displayLabel}: no matching mailbox for ${state.selectedMailboxPath}');
              continue;
            }

            final emails = await _repository.syncEmails(
              acc.id,
              accountPath,
              fullSync: fullSync,
            );
            allEmails.addAll(emails);
          } catch (e) {
            failures.add('${acc.displayLabel}: $e');
          }
        }
        allEmails.sort((a, b) => b.date.compareTo(a.date));
        state = state.copyWith(emails: allEmails, isSyncing: false);
        if (allEmails.isEmpty && failures.isNotEmpty) {
          state = state.copyWith(error: 'Failed to sync emails for accounts: ${failures.join('; ')}');
        }
        return;
      }

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
    state = state.copyWith(
      selectedMailboxPath: mailboxPath,
      isLoading: true,
      clearSelectedEmail: true,
    );

    try {
      if (state.selectedAccountId == null) {
        // Load cached emails across all accounts for this mailbox
        final accounts = await ref.read(allAccountsProvider.future);
        final List<EmailMessage> allEmails = [];
        final List<String> failures = [];
        for (final acc in accounts) {
          try {
            String? accountPath;
            try {
              final accountMailboxes = await _repository.getMailboxes(acc.id);
              accountPath = _resolveMailboxPathForAccount(mailboxPath, accountMailboxes);
            } catch (e) {
              accountPath = mailboxPath;
            }

            if (accountPath == null) {
              failures.add('${acc.displayLabel}: no matching mailbox for $mailboxPath');
              continue;
            }

            final cached = await _repository.getEmails(acc.id, accountPath);
            allEmails.addAll(cached);
          } catch (e) {
            failures.add('${acc.displayLabel}: $e');
          }
        }
        allEmails.sort((a, b) => b.date.compareTo(a.date));
        state = state.copyWith(emails: allEmails, isLoading: false);

        if (allEmails.isEmpty && failures.isNotEmpty) {
          state = state.copyWith(error: 'Failed to load mailbox "$mailboxPath" for accounts: ${failures.join('; ')}');
        }

        // Sync in background across accounts
        await syncEmails();
        return;
      }

      // Single-account mailbox
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
    try {
      await _repository.setReadStatus(
        email.accountId,
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
    try {
      await _repository.setReadStatus(
        email.accountId,
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
    try {
      await _repository.setStarredStatus(
        email.accountId,
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
    // Prefer archiving: if an Archive mailbox exists, move the email there
    try {
      Mailbox? archiveMailbox;
      try {
        // Prefer account-specific archive mailbox when available
        final accountMailboxes = await _repository.getMailboxes(email.accountId);
        try {
          archiveMailbox = accountMailboxes.firstWhere((m) => m.isArchive);
        } catch (_) {
          // If no archive mailbox, prefer Trash as a safer fallback
          try {
            archiveMailbox = accountMailboxes.firstWhere((m) => m.isTrash);
          } catch (_) {
            archiveMailbox = null;
          }
        }
      } catch (_) {
        archiveMailbox = null;
      }

      if (archiveMailbox != null && archiveMailbox.path != email.mailboxName) {
        await _repository.moveEmail(
          email.accountId,
          email.mailboxName,
          archiveMailbox.path,
          email.id,
          email.uid,
        );

        // Remove from local state view
        final updatedEmails = state.emails.where((e) => e.id != email.id).toList();
        state = state.copyWith(
          emails: updatedEmails,
          clearSelectedEmail: state.selectedEmailId == email.id,
        );
        return;
      }

      // No archive mailbox found — perform delete
      await _repository.deleteEmail(
        email.accountId,
        email.mailboxName,
        email.id,
        email.uid,
      );

      // Remove from local state
      final updatedEmails = state.emails.where((e) => e.id != email.id).toList();
      state = state.copyWith(
        emails: updatedEmails,
        clearSelectedEmail: state.selectedEmailId == email.id,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete email: $e');
    }
  }

  /// Archive email by moving it to the account's Archive mailbox.
  Future<void> archiveEmail(EmailMessage email) async {
    try {
      Mailbox? archiveMailbox;
      try {
        final accountMailboxes = await _repository.getMailboxes(email.accountId);
        try {
          archiveMailbox = accountMailboxes.firstWhere((m) => m.isArchive);
        } catch (_) {
          try {
            archiveMailbox = accountMailboxes.firstWhere((m) => m.isTrash);
          } catch (_) {
            archiveMailbox = null;
          }
        }
      } catch (_) {
        archiveMailbox = null;
      }

      if (archiveMailbox == null) {
        // Try to create an Archive mailbox on the account and retry
        try {
          await _repository.createMailbox(email.accountId, 'Archive');
          final refreshed = await _repository.getMailboxes(email.accountId);
          try {
            archiveMailbox = refreshed.firstWhere((m) => m.isArchive);
          } catch (_) {
            archiveMailbox = null;
          }
        } catch (_) {
          archiveMailbox = null;
        }
      }

      if (archiveMailbox == null) return;

      if (archiveMailbox.path == email.mailboxName) return;

      await _repository.moveEmail(
        email.accountId,
        email.mailboxName,
        archiveMailbox.path,
        email.id,
        email.uid,
      );

      // Remove from local state view
      final updatedEmails = state.emails.where((e) => e.id != email.id).toList();
      state = state.copyWith(
        emails: updatedEmails,
        clearSelectedEmail: state.selectedEmailId == email.id,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to archive email: $e');
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
      ref
        ..invalidate(allAccountsProvider)
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

  // Otherwise, fetch full content from server using the email's account id
  final repository = ref.read(emailRepositoryProvider);
  final fullEmail = await repository.fetchFullEmail(
    email.accountId,
    email.mailboxName,
    email.uid,
  );
  return fullEmail ?? email;
});
