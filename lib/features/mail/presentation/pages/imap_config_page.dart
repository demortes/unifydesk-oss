import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/mail_providers.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/server_config_form.dart';

/// Page for configuring IMAP/SMTP credentials.
class ImapConfigPage extends ConsumerStatefulWidget {
  const ImapConfigPage({
    required this.onSuccess,
    required this.onCancel,
    super.key,
  });

  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  @override
  ConsumerState<ImapConfigPage> createState() => _ImapConfigPageState();
}

class _ImapConfigPageState extends ConsumerState<ImapConfigPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _imapHostController;
  late final TextEditingController _imapPortController;
  late final TextEditingController _smtpHostController;
  late final TextEditingController _smtpPortController;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingProvider);
    _emailController = TextEditingController(text: state.email);
    _passwordController = TextEditingController(text: state.password);
    _displayNameController = TextEditingController(text: state.displayName);
    _imapHostController = TextEditingController(text: state.imapHost);
    _imapPortController =
        TextEditingController(text: state.imapPort.toString());
    _smtpHostController = TextEditingController(text: state.smtpHost);
    _smtpPortController =
        TextEditingController(text: state.smtpPort.toString());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _imapHostController.dispose();
    _imapPortController.dispose();
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(onboardingProvider.notifier)

      // Update state with form values
      ..setEmail(_emailController.text)
      ..setPassword(_passwordController.text)
      ..setDisplayName(_displayNameController.text);

    if (ref.read(onboardingProvider).selectedProvider == MailProvider.custom) {
      notifier
        ..setImapHost(_imapHostController.text)
        ..setImapPort(int.tryParse(_imapPortController.text) ?? 993)
        ..setSmtpHost(_smtpHostController.text)
        ..setSmtpPort(int.tryParse(_smtpPortController.text) ?? 465);
    }

    // Save account
    final success = await notifier.saveAccountWithPassword();

    if (success && mounted) {
      widget.onSuccess();
    }
  }

  Future<void> _openHelpUrl() async {
    final state = ref.read(onboardingProvider);
    final config = state.providerConfig;
    if (config?.helpUrl != null) {
      await launchUrl(Uri.parse(config!.helpUrl!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = state.selectedProvider;
    final config = state.providerConfig;
    final isCustom = provider == MailProvider.custom;

    return Scaffold(
      appBar: AppBar(
        title: Text(provider?.displayName ?? 'Add Account'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onCancel,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Provider info
              if (!isCustom && config != null) ...[
                ServerInfoDisplay(
                  imapHost: config.imap.host,
                  imapPort: config.imap.port,
                  smtpHost: config.smtp.host,
                  smtpPort: config.smtp.port,
                ),
                const SizedBox(height: 24),
              ],

              // Email field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'you@example.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password field
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'App Password',
                  hintText: 'Enter your app password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.password],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your app password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Help link for app password
              if (config?.helpUrl != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _openHelpUrl,
                    icon: const Icon(Icons.help_outline, size: 18),
                    label: const Text('How to create an app password'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Display name field (optional)
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name (optional)',
                  hintText: 'Personal Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outlined),
                ),
                textInputAction:
                    isCustom ? TextInputAction.next : TextInputAction.done,
              ),
              const SizedBox(height: 24),

              // Custom server config
              if (isCustom) ...[
                ServerConfigForm(
                  imapHostController: _imapHostController,
                  imapPortController: _imapPortController,
                  smtpHostController: _smtpHostController,
                  smtpPortController: _smtpPortController,
                  useSsl: state.useSsl,
                  onUseSslChanged: (value) {
                    ref
                        .read(onboardingProvider.notifier)
                        .setUseSsl(useSsl: value);
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Error message
              if (state.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.error!,
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Status message during validation
              if (state.statusMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.statusMessage!,
                          style: TextStyle(color: colorScheme.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: state.isLoading ? null : _submit,
                  child: state.isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              state.isValidating
                                  ? 'Verifying...'
                                  : 'Saving...',
                            ),
                          ],
                        )
                      : const Text('Add Account'),
                ),
              ),
              const SizedBox(height: 16),

              // Security note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your password is encrypted and stored securely on this device.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
