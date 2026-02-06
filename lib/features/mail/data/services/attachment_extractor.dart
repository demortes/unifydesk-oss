import 'dart:typed_data';

import 'package:enough_mail/enough_mail.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../models/email_attachment_model.dart';

/// Extracts attachment metadata and binary data from raw MIME email sources.
class AttachmentExtractor {
  AttachmentExtractor._();

  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));
  static const _uuid = Uuid();

  /// Parse attachment metadata from a raw MIME source.
  ///
  /// Returns a list of [EmailAttachmentModel] with metadata only (no binary).
  static List<EmailAttachmentModel> parseAttachmentMetadata(
    String emailId,
    Uint8List rawSource,
  ) {
    try {
      final message = MimeMessage.parseFromData(rawSource);
      return parseAttachmentMetadataFromMessage(emailId, message);
    } catch (e, stack) {
      _logger.e('Failed to parse attachment metadata', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Parse attachment metadata from an already-parsed [MimeMessage].
  static List<EmailAttachmentModel> parseAttachmentMetadataFromMessage(
    String emailId,
    MimeMessage message,
  ) {
    try {
      final contentInfos = message.findContentInfo();
      final attachments = <EmailAttachmentModel>[];
      var partIndex = 0;

      for (final info in contentInfos) {
        if (info.fileName?.isNotEmpty ?? false) {
          final isInline = info.contentDisposition?.disposition ==
              ContentDisposition.inline;

          attachments.add(EmailAttachmentModel(
            id: _uuid.v4(),
            emailId: emailId,
            filename: info.fileName!,
            size: info.size ?? 0,
            mimeType: info.mediaType?.text ?? 'application/octet-stream',
            contentId: info.cid,
            isInline: isInline,
            partIndex: partIndex,
          ));
          partIndex++;
        }
      }

      _logger.d('Parsed ${attachments.length} attachments for email $emailId');
      return attachments;
    } catch (e, stack) {
      _logger.e('Failed to parse attachment metadata', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Extract binary data for a specific attachment from the raw MIME source.
  ///
  /// [rawSource] is the complete MIME message bytes.
  /// [partIndex] is the index into the content info list returned by
  /// `MimeMessage.findContentInfo()` that corresponds to this attachment.
  static Uint8List? extractAttachmentData(
    Uint8List rawSource,
    int partIndex,
  ) {
    try {
      final message = MimeMessage.parseFromData(rawSource);
      final contentInfos = message.findContentInfo();

      // Filter to only parts with filenames (same logic used during parsing)
      final attachmentInfos = <ContentInfo>[];
      for (final info in contentInfos) {
        if (info.fileName?.isNotEmpty ?? false) {
          attachmentInfos.add(info);
        }
      }

      if (partIndex < 0 || partIndex >= attachmentInfos.length) {
        _logger.e(
          'Invalid partIndex $partIndex, '
          'only ${attachmentInfos.length} attachments found',
        );
        return null;
      }

      final info = attachmentInfos[partIndex];
      final fetchId = info.fetchId;

      // Find the MIME part by its fetch ID
      final part = message.getPart(fetchId);
      if (part == null) {
        _logger.e('Could not find MIME part with fetchId: $fetchId');
        return null;
      }

      // Decode the binary content
      final data = part.decodeContentBinary();
      if (data == null || data.isEmpty) {
        _logger.w('Attachment part decoded to empty data');
        return null;
      }

      _logger.d(
        'Extracted attachment "${info.fileName}" '
        '(${data.length} bytes, fetchId: $fetchId)',
      );
      return data;
    } catch (e, stack) {
      _logger.e('Failed to extract attachment data', error: e, stackTrace: stack);
      return null;
    }
  }
}
