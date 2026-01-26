import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Form widget for configuring custom IMAP/SMTP server settings.
class ServerConfigForm extends StatelessWidget {
  const ServerConfigForm({
    required this.imapHostController,
    required this.imapPortController,
    required this.smtpHostController,
    required this.smtpPortController,
    required this.useSsl,
    required this.onUseSslChanged,
    super.key,
  });

  final TextEditingController imapHostController;
  final TextEditingController imapPortController;
  final TextEditingController smtpHostController;
  final TextEditingController smtpPortController;
  final bool useSsl;
  final ValueChanged<bool> onUseSslChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Server Configuration',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),

        // IMAP Settings
        Text(
          'Incoming Mail (IMAP)',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: imapHostController,
                decoration: const InputDecoration(
                  labelText: 'IMAP Server',
                  hintText: 'imap.example.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: imapPortController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: '993',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final port = int.tryParse(value);
                  if (port == null || port < 1 || port > 65535) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // SMTP Settings
        Text(
          'Outgoing Mail (SMTP)',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: smtpHostController,
                decoration: const InputDecoration(
                  labelText: 'SMTP Server',
                  hintText: 'smtp.example.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: smtpPortController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: '465',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final port = int.tryParse(value);
                  if (port == null || port < 1 || port > 65535) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // SSL Toggle
        SwitchListTile(
          title: const Text('Use SSL/TLS'),
          subtitle: const Text('Recommended for secure connections'),
          value: useSsl,
          onChanged: onUseSslChanged,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

/// Compact server info display for known providers.
class ServerInfoDisplay extends StatelessWidget {
  const ServerInfoDisplay({
    required this.imapHost,
    required this.imapPort,
    required this.smtpHost,
    required this.smtpPort,
    super.key,
  });

  final String imapHost;
  final int imapPort;
  final String smtpHost;
  final int smtpPort;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Server settings configured automatically',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ServerInfoRow(
            label: 'IMAP',
            value: '$imapHost:$imapPort',
          ),
          const SizedBox(height: 4),
          _ServerInfoRow(
            label: 'SMTP',
            value: '$smtpHost:$smtpPort',
          ),
        ],
      ),
    );
  }
}

class _ServerInfoRow extends StatelessWidget {
  const _ServerInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}
