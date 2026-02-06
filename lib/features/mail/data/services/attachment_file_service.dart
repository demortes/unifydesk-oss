import 'dart:io';
import 'dart:typed_data';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Service for saving and sharing attachment files.
class AttachmentFileService {
  AttachmentFileService._();

  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  /// Save attachment data to the device's Downloads directory.
  ///
  /// Returns the full path to the saved file.
  static Future<String> saveToDownloads(
    String filename,
    Uint8List data,
  ) async {
    final dir = await _getDownloadsDirectory();
    final safeName = _sanitizeFilename(filename);
    final file = await _uniqueFile(dir, safeName);

    await file.writeAsBytes(data);
    _logger.i('Saved attachment to: ${file.path}');
    return file.path;
  }

  /// Share attachment via OS share sheet.
  static Future<void> shareAttachment(
    String filename,
    String mimeType,
    Uint8List data,
  ) async {
    // Write to temp directory first
    final tempDir = await getTemporaryDirectory();
    final safeName = _sanitizeFilename(filename);
    final tempFile = File('${tempDir.path}/$safeName');
    await tempFile.writeAsBytes(data);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(tempFile.path, mimeType: mimeType)],
      ),
    );
  }

  /// Get the Downloads directory, with fallback.
  static Future<Directory> _getDownloadsDirectory() async {
    try {
      final dir = await getDownloadsDirectory();
      if (dir != null) return dir;
    } catch (_) {
      // getDownloadsDirectory may not be supported on all platforms
    }

    // Fallback to documents directory
    final docs = await getApplicationDocumentsDirectory();
    final downloads = Directory('${docs.path}/Downloads');
    if (!downloads.existsSync()) {
      await downloads.create(recursive: true);
    }
    return downloads;
  }

  /// Ensure a unique filename by appending (1), (2), etc.
  static Future<File> _uniqueFile(Directory dir, String filename) async {
    var file = File('${dir.path}/$filename');
    if (!await file.exists()) return file;

    final ext = filename.contains('.')
        ? '.${filename.split('.').last}'
        : '';
    final base = ext.isNotEmpty
        ? filename.substring(0, filename.length - ext.length)
        : filename;

    var counter = 1;
    while (await file.exists()) {
      file = File('${dir.path}/$base ($counter)$ext');
      counter++;
    }
    return file;
  }

  /// Remove characters that are invalid in filenames.
  static String _sanitizeFilename(String filename) {
    return filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }
}
