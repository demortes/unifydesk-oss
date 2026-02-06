import 'package:equatable/equatable.dart';

/// Represents an email attachment with metadata.
///
/// Binary data is not stored here — it is extracted on-demand from the
/// email's raw MIME source using [partIndex].
class EmailAttachment extends Equatable {
  const EmailAttachment({
    required this.id,
    required this.emailId,
    required this.filename,
    required this.size,
    required this.mimeType,
    this.contentId,
    this.isInline = false,
    required this.partIndex,
  });

  /// Unique identifier (UUID).
  final String id;

  /// Foreign key to the parent email.
  final String emailId;

  /// Original filename of the attachment.
  final String filename;

  /// Size in bytes.
  final int size;

  /// MIME type (e.g. "application/pdf", "image/png").
  final String mimeType;

  /// Content-ID for inline attachments (used in `cid:` references).
  final String? contentId;

  /// Whether this is an inline attachment (e.g. embedded image).
  final bool isInline;

  /// Index into the MIME message's content info list, used to locate
  /// the correct part when extracting binary data from raw source.
  final int partIndex;

  /// Human-readable file size.
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  List<Object?> get props => [
        id,
        emailId,
        filename,
        size,
        mimeType,
        contentId,
        isInline,
        partIndex,
      ];
}
