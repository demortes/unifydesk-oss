import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/mail_providers.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/provider_card.dart';

/// Page for selecting an email provider during onboarding.
class ProviderSelectionPage extends ConsumerWidget {
  const ProviderSelectionPage({
    required this.onProviderSelected,
    super.key,
  });

  final void Function(MailProvider provider) onProviderSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Email Account'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Choose your email provider',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Select your email service to get started. We\'ll configure the settings automatically for you.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Provider grid
              ProviderCardList(
                providers: MailProviderConfigs.allProviders,
                selectedProvider: state.selectedProvider,
                onProviderSelected: (provider) {
                  ref
                      .read(onboardingProvider.notifier)
                      .selectProvider(provider);
                  onProviderSelected(provider);
                },
              ),

              const SizedBox(height: 32),

              // Privacy note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your credentials are stored securely on this device. We never send your data to external servers.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
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
