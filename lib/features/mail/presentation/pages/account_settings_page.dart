import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/mail_providers.dart';
import '../providers/settings_provider.dart';

/// Page for editing individual email account settings.
class AccountSettingsPage extends ConsumerStatefulWidget {
  const AccountSettingsPage({
    required this.accountId,
    super.key,
  });

  final String accountId;

  @override
  ConsumerState<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends ConsumerState<AccountSettingsPage> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _signatureController;
  late final TextEditingController _replyToController;
  late final TextEditingController _passwordController;
  late AccountSettingsNotifier _notifier;

  bool _obscurePassword = true;
  bool _isInitialized = false;
  AccountSettingsState _state = const AccountSettingsState(isLoading: true);

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _signatureController = TextEditingController();
    _replyToController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notifier = ref.read(accountSettingsNotifierProvider(widget.accountId));
    _notifier.addListener(_onStateChanged);
    _state = _notifier.state;
    _initControllers(_state);
  }

  @override
  void dispose() {
    _notifier.removeListener(_onStateChanged);
    _displayNameController.dispose();
    _signatureController.dispose();
    _replyToController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onStateChanged(AccountSettingsState newState) {
    if (mounted) {
      setState(() {
        _state = newState;
        _initControllers(newState);
      });
    }
  }

  void _initControllers(AccountSettingsState state) {
    if (!_isInitialized && state.account != null) {
      _displayNameController.text = state.displayName;
      _signatureController.text = state.signature;
      _replyToController.text = state.replyTo;
      _isInitialized = true;
    }
  }

  Future<void> _saveChanges() async {
    _notifier
      ..setDisplayName(_displayNameController.text)
      ..setSignature(_signatureController.text)
      ..setReplyTo(_replyToController.text);

    final success = await _notifier.saveChanges();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  Future<void> _updatePassword() async {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a new password')),
      );
      return;
    }

    final success = await _notifier.updatePassword(_passwordController.text);

    if (mounted) {
      if (success) {
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated')),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete this account? '
          'This will remove all local data and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await _notifier.deleteAccount();
      if (success && mounted) {
        Navigator.of(context).pop(true); // Return true to indicate deletion
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_state.account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account Settings')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(_state.error ?? 'Account not found'),
            ],
          ),
        ),
      );
    }

    final account = _state.account!;

    return Scaffold(
      appBar: AppBar(
        title: Text(account.displayLabel),
        centerTitle: true,
        actions: [
          if (_state.isSaving || _state.isValidatingPassword)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
              tooltip: 'Save changes',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account info card
          _buildSectionCard(
            title: 'Account',
            icon: Icons.email_outlined,
            children: [
              _buildInfoRow('Email', account.email),
              _buildInfoRow('Provider', account.providerType.displayName),
              _buildInfoRow(
                'Authentication',
                account.authType == AuthType.oauth ? 'OAuth 2.0' : 'Password',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Display settings
          _buildSectionCard(
            title: 'Display',
            icon: Icons.person_outline,
            children: [
              TextField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'Your name for outgoing emails',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _replyToController,
                decoration: const InputDecoration(
                  labelText: 'Reply-To Address (optional)',
                  hintText: 'Alternative email for replies',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Signature
          _buildSectionCard(
            title: 'Signature',
            icon: Icons.edit_note,
            children: [
              TextField(
                controller: _signatureController,
                decoration: const InputDecoration(
                  labelText: 'Email Signature',
                  hintText: 'Signature appended to your emails',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                textInputAction: TextInputAction.newline,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sync settings
          _buildSectionCard(
            title: 'Sync',
            icon: Icons.sync,
            children: [
              SwitchListTile(
                title: const Text('Account Active'),
                subtitle: const Text('Enable email synchronization'),
                value: _state.isActive,
                onChanged: (value) {
                  _notifier.setActive(value);
                },
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              ListTile(
                title: const Text('Sync Frequency'),
                subtitle: Text('Every ${_state.syncFrequencyMinutes} minutes'),
                trailing: DropdownButton<int>(
                  value: _state.syncFrequencyMinutes,
                  onChanged: (value) {
                    if (value != null) {
                      _notifier.setSyncFrequency(value);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 5, child: Text('5 min')),
                    DropdownMenuItem(value: 10, child: Text('10 min')),
                    DropdownMenuItem(value: 15, child: Text('15 min')),
                    DropdownMenuItem(value: 30, child: Text('30 min')),
                    DropdownMenuItem(value: 60, child: Text('1 hour')),
                  ],
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Password update (only for password auth)
          if (account.authType == AuthType.password) ...[
            _buildSectionCard(
              title: 'Security',
              icon: Icons.lock_outline,
              children: [
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    hintText: 'Enter new app password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                ),
                const SizedBox(height: 12),
                // Status message
                if (_state.statusMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(_state.statusMessage!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _state.isValidatingPassword ? null : _updatePassword,
                    child: const Text('Update Password'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Server info
          _buildSectionCard(
            title: 'Server Configuration',
            icon: Icons.dns_outlined,
            children: [
              _buildInfoRow('IMAP Server', account.effectiveImapConfig.host),
              _buildInfoRow('IMAP Port', account.effectiveImapConfig.port.toString()),
              _buildInfoRow('SMTP Server', account.effectiveSmtpConfig.host),
              _buildInfoRow('SMTP Port', account.effectiveSmtpConfig.port.toString()),
              _buildInfoRow('SSL/TLS', account.useSsl ? 'Enabled' : 'Disabled'),
            ],
          ),
          const SizedBox(height: 16),

          // Error message
          if (_state.error != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _state.error!,
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Delete account
          _buildSectionCard(
            title: 'Danger Zone',
            icon: Icons.warning_amber_outlined,
            color: colorScheme.error,
            children: [
              Text(
                'Deleting this account will remove all local data including cached emails.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _confirmDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error),
                  ),
                  child: const Text('Delete Account'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color ?? colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color ?? colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
