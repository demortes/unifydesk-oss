import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/email_message.dart';
import '../../domain/entities/mailbox.dart';
import '../providers/inbox_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/email_detail_view.dart';
import 'onboarding_page.dart';

/// Main inbox page with responsive layout.
class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({super.key});

  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage> {
  @override
  void initState() {
    super.initState();
    // Initialize inbox after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inboxProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inboxState = ref.watch(inboxProvider);
    final accounts = ref.watch(allAccountsProvider);
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
            onMailboxSelected: (path) {
              ref.read(inboxProvider.notifier).selectMailbox(path);
            },
            accounts: accounts.value ?? [],
            selectedAccountId: inboxState.selectedAccountId,
            onAccountSelected: (id) {
              ref.read(inboxProvider.notifier).selectAccount(id);
            },
            onAddAccount: () => _navigateToAddAccount(context),
            onRemoveAccount: (id) => _confirmRemoveAccount(context, id),
          ),
          // Divider
          VerticalDivider(width: 1, thickness: 1, color: colorScheme.outlineVariant),
          // Email list
          Expanded(
            flex: 2,
            child: _EmailListPane(
              emails: inboxState.emails,
              selectedEmailId: inboxState.selectedEmailId,
              isLoading: inboxState.isLoading,
              isSyncing: inboxState.isSyncing,
              error: inboxState.error,
              onEmailSelected: (email) {
                ref.read(inboxProvider.notifier).selectEmail(email.id);
              },
              onRefresh: () => ref.read(inboxProvider.notifier).refresh(),
              onErrorDismiss: () => ref.read(inboxProvider.notifier).clearError(),
              mailboxPath: inboxState.selectedMailboxPath,
            ),
          ),
          // Email detail (only on wide screens)
          if (isWide) ...[
            VerticalDivider(width: 1, thickness: 1, color: colorScheme.outlineVariant),
            Expanded(
              flex: 3,
              child: inboxState.selectedEmailId != null
                  ? _EmailDetailPane(
                      onClose: () => ref.read(inboxProvider.notifier).clearSelection(),
                      onToggleStar: () {
                        final email = inboxState.selectedEmail;
                        if (email != null) {
                          ref.read(inboxProvider.notifier).toggleStarred(email);
                        }
                      },
                      onDelete: () {
                        final email = inboxState.selectedEmail;
                        if (email != null) {
                          ref.read(inboxProvider.notifier).deleteEmail(email);
                        }
                      },
                      onMarkUnread: () {
                        final email = inboxState.selectedEmail;
                        if (email != null) {
                          ref.read(inboxProvider.notifier).markAsUnread(email);
                        }
                      },
                    )
                  : const _EmptyDetailPlaceholder(),
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
            ref.invalidate(allAccountsProvider);
            ref.read(inboxProvider.notifier).initialize();
          },
        ),
      ),
    );
  }

  Future<void> _confirmRemoveAccount(BuildContext context, String accountId) async {
    final accounts = ref.read(allAccountsProvider).value ?? [];
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
      final hasRemainingAccounts =
          await ref.read(inboxProvider.notifier).removeAccount(accountId);

      if (!hasRemainingAccounts && context.mounted) {
        // Last account removed - the hasAccountsProvider will trigger
        // navigation back to onboarding via AppShell
        ref.invalidate(hasAccountsProvider);
      }
    }
  }
}

/// Sidebar showing mailboxes and account switcher.
class _MailSidebar extends StatelessWidget {
  const _MailSidebar({
    required this.mailboxes,
    required this.selectedMailboxPath,
    required this.onMailboxSelected,
    required this.accounts,
    required this.selectedAccountId,
    required this.onAccountSelected,
    required this.onAddAccount,
    required this.onRemoveAccount,
  });

  final List<Mailbox> mailboxes;
  final String selectedMailboxPath;
  final ValueChanged<String> onMailboxSelected;
  final List accounts;
  final String? selectedAccountId;
  final ValueChanged<String> onAccountSelected;
  final VoidCallback onAddAccount;
  final ValueChanged<String> onRemoveAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 220,
      child: Column(
        children: [
          // Account switcher
          Container(
            padding: const EdgeInsets.all(12),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == '_add') {
                  onAddAccount();
                } else if (value == '_remove') {
                  if (selectedAccountId != null) {
                    onRemoveAccount(selectedAccountId!);
                  }
                } else {
                  onAccountSelected(value);
                }
              },
              itemBuilder: (context) => [
                ...accounts.map(
                  (account) => PopupMenuItem<String>(
                    value: account.id,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            account.email[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            account.email,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (account.id == selectedAccountId)
                          Icon(Icons.check, size: 18, color: colorScheme.primary),
                      ],
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: '_add',
                  child: Row(
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 8),
                      Text('Add Account'),
                    ],
                  ),
                ),
                if (selectedAccountId != null)
                  PopupMenuItem<String>(
                    value: '_remove',
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle_outline, color: colorScheme.error),
                        const SizedBox(width: 8),
                        Text(
                          'Remove Account',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ),
                  ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        _getSelectedAccountInitial(),
                        style: TextStyle(color: colorScheme.onPrimaryContainer),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getSelectedAccountEmail(),
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          // Mailbox list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Special folders first
                ..._buildSpecialFolders(context),
                if (mailboxes.any((m) => !_isSpecialFolder(m)))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Folders',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                // Other folders
                ...mailboxes
                    .where((m) => !_isSpecialFolder(m) && m.isSelectable)
                    .map((m) => _buildMailboxTile(context, m)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSelectedAccountInitial() {
    final account = accounts.cast<dynamic>().firstWhere(
          (a) => a.id == selectedAccountId,
          orElse: () => null,
        );
    if (account == null) return '?';
    return (account.email as String)[0].toUpperCase();
  }

  String _getSelectedAccountEmail() {
    final account = accounts.cast<dynamic>().firstWhere(
          (a) => a.id == selectedAccountId,
          orElse: () => null,
        );
    if (account == null) return 'Select Account';
    return account.email as String;
  }

  bool _isSpecialFolder(Mailbox m) {
    return m.isInbox || m.isSent || m.isDrafts || m.isTrash || m.isJunk;
  }

  List<Widget> _buildSpecialFolders(BuildContext context) {
    final specialFolders = <Mailbox>[];

    // Find special folders in order
    for (final m in mailboxes) {
      if (m.isInbox) {
        specialFolders.insert(0, m);
      } else if (m.isSent) {
        specialFolders.add(m);
      } else if (m.isDrafts) {
        specialFolders.add(m);
      } else if (m.isJunk) {
        specialFolders.add(m);
      } else if (m.isTrash) {
        specialFolders.add(m);
      }
    }

    // If no mailboxes yet, show default inbox
    if (specialFolders.isEmpty && mailboxes.isEmpty) {
      return [
        _buildMailboxTile(
          context,
          const Mailbox(accountId: '', name: 'Inbox', path: 'INBOX'),
        ),
      ];
    }

    return specialFolders.map((m) => _buildMailboxTile(context, m)).toList();
  }

  Widget _buildMailboxTile(BuildContext context, Mailbox mailbox) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = mailbox.path == selectedMailboxPath;

    IconData icon;
    switch (mailbox.iconName) {
      case 'inbox':
        icon = Icons.inbox;
        break;
      case 'send':
        icon = Icons.send;
        break;
      case 'drafts':
        icon = Icons.drafts;
        break;
      case 'delete':
        icon = Icons.delete;
        break;
      case 'warning':
        icon = Icons.warning;
        break;
      case 'archive':
        icon = Icons.archive;
        break;
      default:
        icon = Icons.folder;
    }

    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        size: 20,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        mailbox.name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? colorScheme.primary : null,
        ),
      ),
      trailing: mailbox.unreadMessages > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                mailbox.unreadMessages.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            )
          : null,
      selected: isSelected,
      selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
      onTap: () => onMailboxSelected(mailbox.path),
    );
  }
}

/// Email list pane.
class _EmailListPane extends StatelessWidget {
  const _EmailListPane({
    required this.emails,
    required this.selectedEmailId,
    required this.isLoading,
    required this.isSyncing,
    required this.error,
    required this.onEmailSelected,
    required this.onRefresh,
    required this.onErrorDismiss,
    required this.mailboxPath,
  });

  final List<EmailMessage> emails;
  final String? selectedEmailId;
  final bool isLoading;
  final bool isSyncing;
  final String? error;
  final ValueChanged<EmailMessage> onEmailSelected;
  final VoidCallback onRefresh;
  final VoidCallback onErrorDismiss;
  final String mailboxPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              Text(
                mailboxPath,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (isSyncing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: onRefresh,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        // Error banner
        if (error != null)
          MaterialBanner(
            content: Text(error!),
            backgroundColor: colorScheme.errorContainer,
            contentTextStyle: TextStyle(color: colorScheme.onErrorContainer),
            actions: [
              TextButton(
                onPressed: onErrorDismiss,
                child: const Text('Dismiss'),
              ),
            ],
          ),
        // Email list
        Expanded(
          child: isLoading && emails.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : emails.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No emails',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: onRefresh,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Sync emails'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => onRefresh(),
                      child: ListView.builder(
                        itemCount: emails.length,
                        itemBuilder: (context, index) {
                          final email = emails[index];
                          return _EmailListTile(
                            email: email,
                            isSelected: email.id == selectedEmailId,
                            onTap: () => onEmailSelected(email),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

/// Single email list tile.
class _EmailListTile extends StatelessWidget {
  const _EmailListTile({
    required this.email,
    required this.isSelected,
    required this.onTap,
  });

  final EmailMessage email;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
          border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            left: isSelected
                ? BorderSide(color: colorScheme.primary, width: 3)
                : BorderSide.none,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread indicator
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6, right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: email.isRead ? Colors.transparent : colorScheme.primary,
              ),
            ),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender and date
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          email.from.display,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: email.isRead ? FontWeight.normal : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatDate(email.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Subject
                  Row(
                    children: [
                      if (email.isStarred)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber.shade600,
                          ),
                        ),
                      if (email.hasAttachments)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.attach_file,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          email.subject.isEmpty ? '(No Subject)' : email.subject,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: email.isRead ? FontWeight.normal : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Preview
                  Text(
                    email.preview,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final emailDate = DateTime(date.year, date.month, date.day);

    if (emailDate == today) {
      return DateFormat.jm().format(date);
    } else if (emailDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat.E().format(date);
    } else if (date.year == now.year) {
      return DateFormat.MMMd().format(date);
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }
}

/// Email detail pane that fetches full content.
class _EmailDetailPane extends ConsumerWidget {
  const _EmailDetailPane({
    required this.onClose,
    required this.onToggleStar,
    required this.onDelete,
    required this.onMarkUnread,
  });

  final VoidCallback onClose;
  final VoidCallback onToggleStar;
  final VoidCallback onDelete;
  final VoidCallback onMarkUnread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailAsync = ref.watch(selectedEmailProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return emailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load email',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      data: (email) {
        if (email == null) {
          return const _EmptyDetailPlaceholder();
        }
        return EmailDetailView(
          email: email,
          onClose: onClose,
          onToggleStar: onToggleStar,
          onDelete: onDelete,
          onMarkUnread: onMarkUnread,
        );
      },
    );
  }
}

/// Empty state placeholder for email detail pane.
class _EmptyDetailPlaceholder extends StatelessWidget {
  const _EmptyDetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.email_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Select an email to read',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
