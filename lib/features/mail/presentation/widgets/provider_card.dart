import 'package:flutter/material.dart';

import '../../../../core/constants/mail_providers.dart';

/// Card widget for selecting a mail provider.
class ProviderCard extends StatelessWidget {
  const ProviderCard({
    required this.provider,
    required this.onTap,
    this.isSelected = false,
    super.key,
  });

  final MailProvider provider;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ProviderIcon(provider: provider),
              const SizedBox(height: 12),
              Text(
                provider.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
              if (provider.usesOAuth) ...[
                const SizedBox(height: 4),
                Text(
                  'Sign in with Google',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Provider icon widget.
class _ProviderIcon extends StatelessWidget {
  const _ProviderIcon({required this.provider});

  final MailProvider provider;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Use Material icons since we don't have custom assets yet
    final iconData = switch (provider) {
      MailProvider.gmail => Icons.mail,
      MailProvider.yahoo => Icons.mail_outline,
      MailProvider.icloud => Icons.cloud,
      MailProvider.outlook => Icons.business,
      MailProvider.aol => Icons.alternate_email,
      MailProvider.custom => Icons.settings,
    };

    final iconColor = switch (provider) {
      MailProvider.gmail => Colors.red,
      MailProvider.yahoo => Colors.purple,
      MailProvider.icloud => Colors.blue,
      MailProvider.outlook => Colors.blue.shade700,
      MailProvider.aol => Colors.orange,
      MailProvider.custom => colorScheme.primary,
    };

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        size: 32,
        color: iconColor,
      ),
    );
  }
}

/// Horizontal list of provider cards for compact display.
class ProviderCardList extends StatelessWidget {
  const ProviderCardList({
    required this.providers,
    required this.onProviderSelected,
    this.selectedProvider,
    super.key,
  });

  final List<MailProvider> providers;
  final ValueChanged<MailProvider> onProviderSelected;
  final MailProvider? selectedProvider;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        return ProviderCard(
          provider: provider,
          isSelected: provider == selectedProvider,
          onTap: () => onProviderSelected(provider),
        );
      },
    );
  }
}
