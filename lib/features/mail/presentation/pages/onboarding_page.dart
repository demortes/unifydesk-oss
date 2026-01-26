import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/mail_providers.dart';
import 'account_summary_page.dart';
import 'imap_config_page.dart';
import 'oauth_page.dart';
import 'provider_selection_page.dart';

/// Main onboarding flow orchestrator.
///
/// Manages navigation between onboarding steps without using GoRouter
/// to keep the flow self-contained.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({
    required this.onComplete,
    super.key,
  });

  /// Called when onboarding is complete and user should proceed to inbox.
  final VoidCallback onComplete;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  _OnboardingStep _currentStep = _OnboardingStep.providerSelection;

  void _goToStep(_OnboardingStep step) {
    setState(() {
      _currentStep = step;
    });
  }

  void _onProviderSelected(MailProvider provider) {
    if (provider.usesOAuth) {
      _goToStep(_OnboardingStep.oauth);
    } else {
      _goToStep(_OnboardingStep.imapConfig);
    }
  }

  void _onAccountAdded() {
    _goToStep(_OnboardingStep.summary);
  }

  void _onAddAnother() {
    _goToStep(_OnboardingStep.providerSelection);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_currentStep) {
      _OnboardingStep.providerSelection => ProviderSelectionPage(
          onProviderSelected: _onProviderSelected,
        ),
      _OnboardingStep.oauth => OAuthPage(
          onSuccess: _onAccountAdded,
          onCancel: () => _goToStep(_OnboardingStep.providerSelection),
        ),
      _OnboardingStep.imapConfig => ImapConfigPage(
          onSuccess: _onAccountAdded,
          onCancel: () => _goToStep(_OnboardingStep.providerSelection),
        ),
      _OnboardingStep.summary => AccountSummaryPage(
          onAddAnother: _onAddAnother,
          onComplete: widget.onComplete,
        ),
    };
  }
}

enum _OnboardingStep {
  providerSelection,
  oauth,
  imapConfig,
  summary,
}
