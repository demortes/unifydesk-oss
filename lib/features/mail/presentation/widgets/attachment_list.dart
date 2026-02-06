import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../data/services/attachment_file_service.dart';
import '../../domain/entities/email_attachment.dart';
import '../providers/inbox_provider.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// Displays the list of attachments for an email.
///
/// Shows a collapsible section with attachment rows. Each row has a file icon,
/// filename, size, and download/share buttons.
class AttachmentList extends ConsumerStatefulWidget {
  const AttachmentList({
    super.key,
    required this.emailId,
  });

  final String emailId;

  @override
  ConsumerState<AttachmentList> createState() => _AttachmentListState();
}

class _AttachmentListState extends ConsumerState<AttachmentList> {
  bool _expanded = true;
  final Set<String> _downloading = {};

  @override
  Widget build(BuildContext context) {
    final attachmentsAsync =
        ref.watch(selectedEmailAttachmentsProvider(widget.emailId));

    return attachmentsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (attachments) {
        if (attachments.isEmpty) return const SizedBox.shrink();

        // Filter out inline images from the displayed list
        final regularAttachments =
            attachments.where((a) => !a.isInline).toList();
        if (regularAttachments.isEmpty) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Attachments (${regularAttachments.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _expanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            // Attachment rows
            if (_expanded)
              ...regularAttachments.map(
                (attachment) => _AttachmentRow(
                  attachment: attachment,
                  isDownloading: _downloading.contains(attachment.id),
                  onDownload: () => _downloadAttachment(attachment),
                  onShare: () => _shareAttachment(attachment),
                ),
              ),
            const Divider(height: 1),
          ],
        );
      },
    );
  }

  Future<void> _downloadAttachment(EmailAttachment attachment) async {
    if (_downloading.contains(attachment.id)) return;

    setState(() => _downloading.add(attachment.id));
    try {
      final repository = ref.read(emailRepositoryProvider);
      final data =
          await repository.getAttachmentData(widget.emailId, attachment.id);

      if (data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to extract attachment')),
          );
        }
        return;
      }

      final path =
          await AttachmentFileService.saveToDownloads(attachment.filename, data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to $path')),
        );
      }
    } catch (e) {
      _logger.e('Download failed', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloading.remove(attachment.id));
      }
    }
  }

  Future<void> _shareAttachment(EmailAttachment attachment) async {
    try {
      final repository = ref.read(emailRepositoryProvider);
      final data =
          await repository.getAttachmentData(widget.emailId, attachment.id);

      if (data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to extract attachment')),
          );
        }
        return;
      }

      await AttachmentFileService.shareAttachment(
        attachment.filename,
        attachment.mimeType,
        data,
      );
    } catch (e) {
      _logger.e('Share failed', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }
}

/// A single attachment row showing icon, name, size, and action buttons.
class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({
    required this.attachment,
    required this.isDownloading,
    required this.onDownload,
    required this.onShare,
  });

  final EmailAttachment attachment;
  final bool isDownloading;
  final VoidCallback onDownload;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // File type icon
          Icon(
            _iconForMimeType(attachment.mimeType),
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          // Filename and size
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.filename,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  attachment.formattedSize,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Download button
          if (isDownloading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.download, size: 20),
              tooltip: 'Download',
              onPressed: onDownload,
              visualDensity: VisualDensity.compact,
            ),
          // Share button
          IconButton(
            icon: const Icon(Icons.share, size: 20),
            tooltip: 'Share',
            onPressed: onShare,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  IconData _iconForMimeType(String mimeType) {
    final type = mimeType.toLowerCase();
    if (type.startsWith('image/')) return Icons.image;
    if (type.startsWith('video/')) return Icons.videocam;
    if (type.startsWith('audio/')) return Icons.audiotrack;
    if (type.contains('pdf')) return Icons.picture_as_pdf;
    if (type.contains('zip') ||
        type.contains('rar') ||
        type.contains('tar') ||
        type.contains('gz') ||
        type.contains('7z')) {
      return Icons.folder_zip;
    }
    if (type.contains('spreadsheet') ||
        type.contains('excel') ||
        type.contains('csv')) {
      return Icons.table_chart;
    }
    if (type.contains('presentation') || type.contains('powerpoint')) {
      return Icons.slideshow;
    }
    if (type.contains('document') ||
        type.contains('word') ||
        type.contains('text/')) {
      return Icons.description;
    }
    return Icons.insert_drive_file;
  }
}
