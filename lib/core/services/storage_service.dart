import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';
import '../security/secure_storage_service.dart';

/// Storage size information.
class StorageInfo {
  const StorageInfo({
    required this.databaseSize,
    required this.cacheSize,
    required this.attachmentsSize,
    required this.totalSize,
  });

  /// Size of the SQLite database file.
  final int databaseSize;

  /// Size of cached data (email content, images, etc.).
  final int cacheSize;

  /// Size of downloaded attachments.
  final int attachmentsSize;

  /// Total storage used.
  final int totalSize;

  /// Format bytes to human-readable string.
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get formattedDatabaseSize => formatBytes(databaseSize);
  String get formattedCacheSize => formatBytes(cacheSize);
  String get formattedAttachmentsSize => formatBytes(attachmentsSize);
  String get formattedTotalSize => formatBytes(totalSize);
}

/// Service for managing app storage.
class StorageService {
  StorageService({
    SecureStorageService? secureStorage,
  }) : _secureStorage = secureStorage ?? SecureStorageService();

  final SecureStorageService _secureStorage;

  static const String _databaseName = 'unifydesk.db';
  static const String _cacheDir = 'cache';
  static const String _attachmentsDir = 'attachments';

  /// Get storage usage information.
  Future<StorageInfo> getStorageInfo() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final cacheDir = await getApplicationCacheDirectory();

    // Calculate database size
    final databaseFile = File('${documentsDir.path}/$_databaseName');
    final databaseSize =
        await databaseFile.exists() ? await databaseFile.length() : 0;

    // Calculate cache size
    final appCacheDir = Directory('${cacheDir.path}/$_cacheDir');
    final cacheSize = await _getDirectorySize(appCacheDir);

    // Calculate attachments size
    final attachmentsDirectory =
        Directory('${documentsDir.path}/$_attachmentsDir');
    final attachmentsSize = await _getDirectorySize(attachmentsDirectory);

    return StorageInfo(
      databaseSize: databaseSize,
      cacheSize: cacheSize,
      attachmentsSize: attachmentsSize,
      totalSize: databaseSize + cacheSize + attachmentsSize,
    );
  }

  /// Get the size of a directory recursively.
  Future<int> _getDirectorySize(Directory directory) async {
    if (!await directory.exists()) return 0;

    int totalSize = 0;
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    } catch (_) {
      // Ignore errors from inaccessible files
    }
    return totalSize;
  }

  /// Clear cached data (images, temporary files, etc.).
  /// Does NOT delete emails or account data.
  Future<void> clearCache() async {
    final cacheDir = await getApplicationCacheDirectory();
    final appCacheDir = Directory('${cacheDir.path}/$_cacheDir');

    if (await appCacheDir.exists()) {
      await appCacheDir.delete(recursive: true);
    }

    // Also clear Flutter's image cache directory
    final imageCacheDir = Directory('${cacheDir.path}/image_cache');
    if (await imageCacheDir.exists()) {
      await imageCacheDir.delete(recursive: true);
    }

    // Clear any libCachedImageData
    final libCacheDir = Directory('${cacheDir.path}/libCachedImageData');
    if (await libCacheDir.exists()) {
      await libCacheDir.delete(recursive: true);
    }
  }

  /// Delete all downloaded attachments.
  Future<void> clearAttachments() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${documentsDir.path}/$_attachmentsDir');

    if (await attachmentsDir.exists()) {
      await attachmentsDir.delete(recursive: true);
    }
  }

  /// Clear all email data from the database.
  /// Keeps account configurations but removes emails and mailboxes.
  Future<void> clearEmailData() async {
    final db = await AppDatabase.instance.database;

    // Delete all emails
    await db.delete('emails');

    // Delete all mailboxes
    await db.delete('mailboxes');
  }

  /// Perform a complete data reset.
  /// Deletes ALL data including accounts, emails, cache, and credentials.
  Future<void> resetAllData() async {
    // Clear cache and attachments first
    await clearCache();
    await clearAttachments();

    // Clear all secure credentials
    await _secureStorage.clearAll();

    // Delete the entire database
    await AppDatabase.instance.deleteDatabase();
  }

  /// Get database file path for display purposes.
  Future<String> getDatabasePath() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return '${documentsDir.path}/$_databaseName';
  }

  /// Get cache directory path for display purposes.
  Future<String> getCachePath() async {
    final cacheDir = await getApplicationCacheDirectory();
    return '${cacheDir.path}/$_cacheDir';
  }

  /// Get attachments directory path for display purposes.
  Future<String> getAttachmentsPath() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return '${documentsDir.path}/$_attachmentsDir';
  }

  /// Create necessary directories if they don't exist.
  Future<void> ensureDirectoriesExist() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final cacheDir = await getApplicationCacheDirectory();

    final attachmentsDir = Directory('${documentsDir.path}/$_attachmentsDir');
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    final appCacheDir = Directory('${cacheDir.path}/$_cacheDir');
    if (!await appCacheDir.exists()) {
      await appCacheDir.create(recursive: true);
    }
  }
}
