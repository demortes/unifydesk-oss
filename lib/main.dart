import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'features/mail/presentation/pages/inbox_page.dart';
import 'features/mail/presentation/pages/onboarding_page.dart';
import 'features/mail/presentation/providers/onboarding_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database factory for desktop platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    const ProviderScope(
      child: UnifyDeskApp(),
    ),
  );
}

class UnifyDeskApp extends StatelessWidget {
  const UnifyDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UnifyDesk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(),
        ),
      ),
      home: const AppShell(),
    );
  }
}

/// Main app shell that handles routing between onboarding and main app.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _showOnboarding = true;

  @override
  Widget build(BuildContext context) {
    // Check if user has accounts
    final hasAccountsAsync = ref.watch(hasAccountsProvider);

    return hasAccountsAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error initializing app',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      data: (hasAccounts) {
        // Show onboarding if no accounts or user requested it
        if (!hasAccounts || _showOnboarding && !hasAccounts) {
          return OnboardingPage(
            onComplete: () {
              setState(() {
                _showOnboarding = false;
              });
              // Refresh the accounts provider
              ref.invalidate(hasAccountsProvider);
            },
          );
        }

        // Show main inbox
        return const InboxPage();
      },
    );
  }
}
