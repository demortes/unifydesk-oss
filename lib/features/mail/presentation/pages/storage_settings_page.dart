import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/storage_service.dart';

/// Provider for storage service.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Provider for storage info.
final storageInfoProvider = FutureProvider<StorageInfo>((ref) async {
  final service = ref.watch(storageServiceProvider);
  return service.getStorageInfo();
});

/// Storage settings page for managing app data.
class StorageSettingsPage extends ConsumerStatefulWidget {
  const StorageSettingsPage({super.key});

  @override
  ConsumerState<StorageSettingsPage> createState() =>
      _StorageSettingsPageState();
}

class _StorageSettingsPageState extends ConsumerState<StorageSettingsPage> {
  bool _isClearing = false;
  String? _clearingOperation;

  Future<void> _clearCache() async {
    final confirmed = await _showConfirmDialog(
      title: 'Clear Cache',
      content:
          'This will delete cached images and temporary files. Your emails and accounts will not be affected.',
      confirmText: 'Clear Cache',
    );

    if (confirmed != true) return;

    setState(() {
      _isClearing = true;
      _clearingOperation = 'Clearing cache...';
    });

    try {
      final service = ref.read(storageServiceProvider);
      await service.clearCache();
      ref.invalidate(storageInfoProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear cache: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClearing = false;
          _clearingOperation = null;
        });
      }
    }
  }

  Future<void> _clearAttachments() async {
    final confirmed = await _showConfirmDialog(
      title: 'Clear Attachments',
      content:
          'This will delete all downloaded attachments. You can download them again when needed.',
      confirmText: 'Clear Attachments',
    );

    if (confirmed != true) return;

    setState(() {
      _isClearing = true;
      _clearingOperation = 'Clearing attachments...';
    });

    try {
      final service = ref.read(storageServiceProvider);
      await service.clearAttachments();
      ref.invalidate(storageInfoProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attachments cleared successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear attachments: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClearing = false;
          _clearingOperation = null;
        });
      }
    }
  }

  Future<void> _clearEmailData() async {
    final confirmed = await _showConfirmDialog(
      title: 'Clear Email Data',
      content:
          'This will delete all locally cached emails and mailbox data. '
          'Your account configurations will be kept, and emails will be '
          're-synced from the server on next refresh.',
      confirmText: 'Clear Emails',
      isDestructive: true,
    );

    if (confirmed != true) return;

    setState(() {
      _isClearing = true;
      _clearingOperation = 'Clearing email data...';
    });

    try {
      final service = ref.read(storageServiceProvider);
      await service.clearEmailData();
      ref.invalidate(storageInfoProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email data cleared successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear email data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClearing = false;
          _clearingOperation = null;
        });
      }
    }
  }

  Future<void> _resetAllData() async {
    // First confirmation
    final firstConfirm = await _showConfirmDialog(
      title: 'Reset All Data',
      content:
          'This will permanently delete ALL app data including:\n\n'
          '• All email accounts and settings\n'
          '• All cached emails and attachments\n'
          '• All saved passwords and credentials\n'
          '• All app preferences\n\n'
          'This action cannot be undone!',
      confirmText: 'Continue',
      isDestructive: true,
    );

    if (firstConfirm != true || !mounted) return;

    // Second confirmation with typing
    final secondConfirm = await _showTypeConfirmDialog();

    if (secondConfirm != true || !mounted) return;

    setState(() {
      _isClearing = true;
      _clearingOperation = 'Resetting all data...';
    });

    try {
      final service = ref.read(storageServiceProvider);
      await service.resetAllData();

      if (mounted) {
        // Navigate back to root and show message
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data has been reset. Please restart the app.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reset data: $e')),
        );
        setState(() {
          _isClearing = false;
          _clearingOperation = null;
        });
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  )
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showTypeConfirmDialog() {
    final controller = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Confirm Reset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To confirm, type "RESET" below:',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Type RESET',
                ),
                onChanged: (_) => setDialogState(() {}),
                autocorrect: false,
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: controller.text.toUpperCase() == 'RESET'
                  ? () => Navigator.of(context).pop(true)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('Reset Everything'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storageInfo = ref.watch(storageInfoProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage'),
        centerTitle: true,
      ),
      body: _isClearing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    _clearingOperation ?? 'Processing...',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Storage usage overview
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.storage,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Storage Usage',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 20),
                              onPressed: () =>
                                  ref.invalidate(storageInfoProvider),
                              tooltip: 'Refresh',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        storageInfo.when(
                          data: (info) => Column(
                            children: [
                              _StorageBar(info: info),
                              const SizedBox(height: 16),
                              _StorageRow(
                                icon: Icons.data_object,
                                label: 'Database',
                                size: info.formattedDatabaseSize,
                                color: Colors.blue,
                              ),
                              _StorageRow(
                                icon: Icons.cached,
                                label: 'Cache',
                                size: info.formattedCacheSize,
                                color: Colors.orange,
                              ),
                              _StorageRow(
                                icon: Icons.attachment,
                                label: 'Attachments',
                                size: info.formattedAttachmentsSize,
                                color: Colors.green,
                              ),
                              const Divider(height: 24),
                              _StorageRow(
                                icon: Icons.pie_chart,
                                label: 'Total',
                                size: info.formattedTotalSize,
                                color: colorScheme.primary,
                                isBold: true,
                              ),
                            ],
                          ),
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (error, _) => Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Error loading storage info: $error',
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Cache management
                const _SectionHeader(
                  title: 'Cache Management',
                  icon: Icons.cached,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.cleaning_services),
                        title: const Text('Clear Cache'),
                        subtitle: const Text(
                          'Remove temporary files and cached images',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _clearCache,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.attachment),
                        title: const Text('Clear Attachments'),
                        subtitle: const Text(
                          'Delete downloaded email attachments',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _clearAttachments,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Data management
                const _SectionHeader(
                  title: 'Data Management',
                  icon: Icons.folder_delete,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.email_outlined,
                          color: colorScheme.error,
                        ),
                        title: const Text('Clear Email Data'),
                        subtitle: const Text(
                          'Delete cached emails (keeps accounts)',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _clearEmailData,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Danger zone
                _SectionHeader(
                  title: 'Danger Zone',
                  icon: Icons.warning_amber,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.delete_forever, color: colorScheme.error),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reset All Data',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Permanently delete all accounts, emails, settings, and credentials. '
                                    'This cannot be undone.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _resetAllData,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              side: BorderSide(color: colorScheme.error),
                            ),
                            child: const Text('Reset All Data'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    this.color,
  });

  final String title;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveColor = color ?? colorScheme.primary;

    return Row(
      children: [
        Icon(icon, size: 20, color: effectiveColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: effectiveColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StorageBar extends StatelessWidget {
  const _StorageBar({required this.info});

  final StorageInfo info;

  @override
  Widget build(BuildContext context) {
    final total = info.totalSize > 0 ? info.totalSize : 1;
    final databasePercent = info.databaseSize / total;
    final cachePercent = info.cacheSize / total;
    final attachmentsPercent = info.attachmentsSize / total;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            if (databasePercent > 0)
              Expanded(
                flex: (databasePercent * 100).round().clamp(1, 100),
                child: Container(color: Colors.blue),
              ),
            if (cachePercent > 0)
              Expanded(
                flex: (cachePercent * 100).round().clamp(1, 100),
                child: Container(color: Colors.orange),
              ),
            if (attachmentsPercent > 0)
              Expanded(
                flex: (attachmentsPercent * 100).round().clamp(1, 100),
                child: Container(color: Colors.green),
              ),
            if (info.totalSize == 0)
              Expanded(
                child: Container(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StorageRow extends StatelessWidget {
  const _StorageRow({
    required this.icon,
    required this.label,
    required this.size,
    required this.color,
    this.isBold = false,
  });

  final IconData icon;
  final String label;
  final String size;
  final Color color;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            size,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
              color: isBold ? null : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
