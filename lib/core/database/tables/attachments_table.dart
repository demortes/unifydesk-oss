import 'package:sqflite/sqflite.dart';

/// Database table definition for email attachments.
class AttachmentsTable {
  AttachmentsTable._();

  static const String tableName = 'attachments';

  // Column names
  static const String colId = 'id';
  static const String colEmailId = 'email_id';
  static const String colFilename = 'filename';
  static const String colSize = 'size';
  static const String colMimeType = 'mime_type';
  static const String colContentId = 'content_id';
  static const String colIsInline = 'is_inline';
  static const String colPartIndex = 'part_index';

  /// Create the attachments table.
  static Future<void> create(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        $colId TEXT PRIMARY KEY,
        $colEmailId TEXT NOT NULL,
        $colFilename TEXT NOT NULL,
        $colSize INTEGER NOT NULL DEFAULT 0,
        $colMimeType TEXT NOT NULL DEFAULT 'application/octet-stream',
        $colContentId TEXT,
        $colIsInline INTEGER NOT NULL DEFAULT 0,
        $colPartIndex INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY ($colEmailId) REFERENCES emails(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_attachments_email
      ON $tableName ($colEmailId)
    ''');
  }
}
