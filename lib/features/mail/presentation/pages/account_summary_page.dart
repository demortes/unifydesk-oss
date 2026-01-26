import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/email_account.dart';
import '../providers/onboarding_provider.dart';

/// Page showing summary of added accounts with option to add more.
class AccountSummaryPage extends ConsumerWidget {
  const AccountSummaryPage({
    required this.onAddAnother,
    required this.onComplete,
    super.key,
  });

  final VoidCallback onAddAnother;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts Added'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Success header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color:
                          colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: 32,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.addedAccounts.length == 1
                              ? 'Account added successfully!'
                              : '${state.addedAccounts.length} accounts added!',
                          style: theme.textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You can add more accounts now or continue to your inbox.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Account list
                  Text(
                    'Your Accounts',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...state.addedAccounts.map(
                    (account) => _AccountListItem(account: account),
                  ),
                ],
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Add another button
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(onboardingProvider.notifier).startNewAccount();
                      onAddAnother();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Another Account'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Continue button
                  FilledButton(
                    onPressed: onComplete,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Continue to Inbox'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountListItem extends StatelessWidget {
  const _AccountListItem({required this.account});

  final EmailAccount account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final iconColor = switch (account.providerType.name) {
      'gmail' => Colors.red,
      'yahoo' => Colors.purple,
      'icloud' => Colors.blue,
      'outlook' => Colors.blue.shade700,
      'aol' => Colors.orange,
      _ => colorScheme.primary,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.email,
            color: iconColor,
          ),
        ),
        title: Text(
          account.displayLabel,
          style: theme.textTheme.titleSmall,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (account.displayName != null)
              Text(
                account.email,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            Row(
              children: [
                Icon(
                  account.authType.name == 'oauth'
                      ? Icons.verified_user
                      : Icons.lock,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  account.authType.displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.check_circle,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
