import '../../../../core/database/tables/attachments_table.dart';
import '../../domain/entities/email_attachment.dart';

/// Data model for email attachments with SQLite serialization.
class EmailAttachmentModel {
  const EmailAttachmentModel({
    required this.id,
    required this.emailId,
    required this.filename,
    required this.size,
    required this.mimeType,
    this.contentId,
    this.isInline = false,
    required this.partIndex,
  });

  final String id;
  final String emailId;
  final String filename;
  final int size;
  final String mimeType;
  final String? contentId;
  final bool isInline;
  final int partIndex;

  /// Create from SQLite row.
  factory EmailAttachmentModel.fromMap(Map<String, dynamic> map) {
    return EmailAttachmentModel(
      id: map[AttachmentsTable.colId] as String,
      emailId: map[AttachmentsTable.colEmailId] as String,
      filename: map[AttachmentsTable.colFilename] as String,
      size: map[AttachmentsTable.colSize] as int? ?? 0,
      mimeType: map[AttachmentsTable.colMimeType] as String? ??
          'application/octet-stream',
      contentId: map[AttachmentsTable.colContentId] as String?,
      isInline: (map[AttachmentsTable.colIsInline] as int? ?? 0) == 1,
      partIndex: map[AttachmentsTable.colPartIndex] as int? ?? 0,
    );
  }

  /// Convert to SQLite row.
  Map<String, dynamic> toMap() {
    return {
      AttachmentsTable.colId: id,
      AttachmentsTable.colEmailId: emailId,
      AttachmentsTable.colFilename: filename,
      AttachmentsTable.colSize: size,
      AttachmentsTable.colMimeType: mimeType,
      AttachmentsTable.colContentId: contentId,
      AttachmentsTable.colIsInline: isInline ? 1 : 0,
      AttachmentsTable.colPartIndex: partIndex,
    };
  }

  /// Convert to domain entity.
  EmailAttachment toEntity() {
    return EmailAttachment(
      id: id,
      emailId: emailId,
      filename: filename,
      size: size,
      mimeType: mimeType,
      contentId: contentId,
      isInline: isInline,
      partIndex: partIndex,
    );
  }
}
