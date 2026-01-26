import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Check if we're running on a mobile platform that supports Google Sign-In
bool get _isMobilePlatform {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

/// Page for handling Google OAuth sign-in.
///
/// On mobile platforms (Android/iOS), this shows the Google Sign-In flow.
/// On desktop platforms, it informs users to use app passwords instead.
class OAuthPage extends ConsumerStatefulWidget {
  const OAuthPage({
    required this.onSuccess,
    required this.onCancel,
    super.key,
  });

  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  @override
  ConsumerState<OAuthPage> createState() => _OAuthPageState();
}

class _OAuthPageState extends ConsumerState<OAuthPage> {
  bool _isLoading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    if (!_isMobilePlatform) {
      setState(() {
        _error = 'Google Sign-In is not available on this platform. '
            'Please use an app password instead.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // For mobile platforms, we would use the Google Sign-In plugin
    // This is a placeholder - on actual mobile devices, this would work
    try {
      // On mobile, we'd call GoogleSignIn().signIn() here
      // For now, show a message that this requires mobile setup
      setState(() {
        _isLoading = false;
        _error = 'Google Sign-In requires additional platform setup. '
            'Please use an app password for now, or run on Android/iOS.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = _getErrorMessage(e);
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    final message = error.toString().toLowerCase();
    if (message.contains('network')) {
      return 'Network error. Please check your internet connection.';
    }
    if (message.contains('cancel')) {
      return 'Sign-in was cancelled.';
    }
    return 'Sign-in failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in with Google'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onCancel,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Google icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.mail,
                  size: 40,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Connect your Gmail account',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _isMobilePlatform
                    ? 'Sign in with your Google account to access your Gmail. '
                        "We'll only request the permissions needed to manage your email."
                    : 'On desktop, Gmail uses IMAP with an app password for secure access.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Desktop notice
              if (!_isMobilePlatform) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'How to use Gmail on desktop:',
                              style: TextStyle(
                                color: colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _StepItem(
                        number: '1',
                        text:
                            'Enable 2-Step Verification in your Google account',
                      ),
                      const _StepItem(
                        number: '2',
                        text: 'Create an App Password at myaccount.google.com',
                      ),
                      const _StepItem(
                        number: '3',
                        text: 'Use your email and app password to sign in',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Use app password button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.password),
                    label: const Text('Continue with App Password'),
                  ),
                ),
              ],

              // Error message
              if (_error != null) ...[
                const SizedBox(height: 16),
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
                          _error!,
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Mobile sign-in button
              if (_isMobilePlatform) ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.login),
                    label: Text(
                        _isLoading ? 'Signing in...' : 'Sign in with Google',),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Back button
              TextButton(
                onPressed: _isLoading ? null : widget.onCancel,
                child: const Text('Back to provider selection'),
              ),

              const Spacer(),

              // Privacy info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Your data stays on this device',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Credentials are encrypted and stored securely. '
                      'We never send your data to external servers.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.number,
    required this.text,
  });

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
