import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/email_message.dart';

/// Widget to display full email content.
class EmailDetailView extends StatelessWidget {
  const EmailDetailView({
    super.key,
    required this.email,
    required this.onClose,
    required this.onToggleStar,
    required this.onDelete,
    required this.onMarkUnread,
  });

  final EmailMessage email;
  final VoidCallback onClose;
  final VoidCallback onToggleStar;
  final VoidCallback onDelete;
  final VoidCallback onMarkUnread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onClose,
                tooltip: 'Back to list',
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  email.isStarred ? Icons.star : Icons.star_border,
                  color: email.isStarred ? Colors.amber.shade600 : null,
                ),
                onPressed: onToggleStar,
                tooltip: email.isStarred ? 'Remove star' : 'Add star',
              ),
              IconButton(
                icon: const Icon(Icons.mark_email_unread_outlined),
                onPressed: onMarkUnread,
                tooltip: 'Mark as unread',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  // Handle other actions
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'reply',
                    child: ListTile(
                      leading: Icon(Icons.reply),
                      title: Text('Reply'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reply_all',
                    child: ListTile(
                      leading: Icon(Icons.reply_all),
                      title: Text('Reply All'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'forward',
                    child: ListTile(
                      leading: Icon(Icons.forward),
                      title: Text('Forward'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'print',
                    child: ListTile(
                      leading: Icon(Icons.print),
                      title: Text('Print'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Email content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject
                Text(
                  email.subject.isEmpty ? '(No Subject)' : email.subject,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                // Sender info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        email.from.display[0].toUpperCase(),
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  email.from.display,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                _formatFullDate(email.date),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'To: ${_formatRecipients(email.to)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (email.cc.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Cc: ${_formatRecipients(email.cc)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                // Body content
                _buildBody(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    // Prefer HTML body if available
    if (email.htmlBody != null && email.htmlBody!.isNotEmpty) {
      return Html(
        data: email.htmlBody!,
        onLinkTap: (url, _, __) {
          if (url != null) {
            _launchUrl(url);
          }
        },
        style: {
          'body': Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
          ),
          'a': Style(
            color: Theme.of(context).colorScheme.primary,
          ),
        },
      );
    }

    // Fall back to plain text
    if (email.textBody != null && email.textBody!.isNotEmpty) {
      return SelectableText(
        email.textBody!,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    // No content
    return Text(
      'No content available',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }

  String _formatFullDate(DateTime date) {
    return DateFormat.yMMMd().add_jm().format(date);
  }

  String _formatRecipients(List<EmailAddress> recipients) {
    if (recipients.isEmpty) return '';
    if (recipients.length == 1) return recipients.first.display;
    if (recipients.length == 2) {
      return '${recipients[0].display}, ${recipients[1].display}';
    }
    return '${recipients[0].display} and ${recipients.length - 1} others';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
