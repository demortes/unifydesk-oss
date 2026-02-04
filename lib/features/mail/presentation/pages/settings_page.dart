import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/mail_providers.dart';
import '../../domain/entities/email_account.dart';
import '../providers/settings_provider.dart';
import 'account_settings_page.dart';
import 'onboarding_page.dart';
import 'storage_settings_page.dart';

/// Main settings page for managing email accounts and app preferences.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsListProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Email Accounts Section
          _SectionHeader(
            title: 'Email Accounts',
            icon: Icons.email_outlined,
            action: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addAccount(context),
              tooltip: 'Add account',
            ),
          ),
          const SizedBox(height: 8),
          accountsAsync.when(
            data: (accounts) {
              if (accounts.isEmpty) {
                return _EmptyAccountsCard(
                  onAddAccount: () => _addAccount(context),
                );
              }
              return Column(
                children: accounts
                    .map((account) => _AccountCard(
                          account: account,
                          onTap: () => _openAccountSettings(context, ref, account),
                        ),)
                    .toList(),
              );
            },
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, stack) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Failed to load accounts: $error'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // General Settings Section
          const _SectionHeader(
            title: 'General',
            icon: Icons.settings_outlined,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Appearance'),
                  subtitle: const Text('Theme, colors, and display options'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  subtitle: const Text('Email alerts and sounds'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: const Text('Storage'),
                  subtitle: const Text('Cache and local data management'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const StorageSettingsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Privacy & Security Section
          const _SectionHeader(
            title: 'Privacy & Security',
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('App Lock'),
                  subtitle: const Text('Require authentication to open'),
                  trailing: Switch(
                    value: false,
                    onChanged: (value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon')),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.image_not_supported_outlined),
                  title: const Text('Block Remote Images'),
                  subtitle: const Text('Prevent tracking pixels'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About Section
          const _SectionHeader(
            title: 'About',
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.open_in_new, size: 20),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Open Source Licenses'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'UnifyDesk',
                      applicationVersion: '1.0.0',
                    );
                  },
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.tag),
                  title: Text('Version'),
                  trailing: Text('1.0.0'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _addAccount(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => OnboardingPage(
          onComplete: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _openAccountSettings(
    BuildContext context,
    WidgetRef ref,
    EmailAccount account,
  ) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => AccountSettingsPage(accountId: account.id),
      ),
    );

    // Refresh accounts list if an account was deleted
    if (deleted ?? false) {
      ref.invalidate(accountsListProvider);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    this.action,
  });

  final String title;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}

class _EmptyAccountsCard extends StatelessWidget {
  const _EmptyAccountsCard({required this.onAddAccount});

  final VoidCallback onAddAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.email_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No email accounts',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add an account to start using email',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAddAccount,
              icon: const Icon(Icons.add),
              label: const Text('Add Account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.onTap,
  });

  final EmailAccount account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getProviderColor(account.providerType),
          child: Icon(
            _getProviderIcon(account.providerType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(account.displayLabel),
        subtitle: Text(account.email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!account.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Disabled',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getProviderColor(MailProvider provider) {
    switch (provider) {
      case MailProvider.gmail:
        return const Color(0xFFEA4335);
      case MailProvider.yahoo:
        return const Color(0xFF6001D2);
      case MailProvider.icloud:
        return const Color(0xFF3693F3);
      case MailProvider.outlook:
        return const Color(0xFF0078D4);
      case MailProvider.aol:
        return const Color(0xFF31459B);
      case MailProvider.custom:
        return const Color(0xFF607D8B);
    }
  }

  IconData _getProviderIcon(MailProvider provider) {
    switch (provider) {
      case MailProvider.gmail:
      case MailProvider.yahoo:
      case MailProvider.icloud:
      case MailProvider.outlook:
      case MailProvider.aol:
        return Icons.email;
      case MailProvider.custom:
        return Icons.dns;
    }
  }
}
