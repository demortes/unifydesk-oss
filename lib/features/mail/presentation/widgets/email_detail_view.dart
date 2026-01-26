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
    // Debug info
    debugPrint(
      'Email body - HTML: ${email.htmlBody?.length ?? 0}, Text: ${email.textBody?.length ?? 0}',
    );

    // Prefer HTML body if available
    if (email.htmlBody != null && email.htmlBody!.isNotEmpty) {
      return _HtmlBodyView(
        html: email.htmlBody!,
        fallbackText: _stripHtmlTags(email.htmlBody!),
      );
    }

    // Fall back to plain text
    if (email.textBody != null && email.textBody!.isNotEmpty) {
      return SelectableText(
        email.textBody!,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    // No content - show debug info
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No content available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Debug: htmlBody=${email.htmlBody?.length ?? "null"}, textBody=${email.textBody?.length ?? "null"}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
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

  /// Strip HTML tags and decode entities to get plain text.
  String _stripHtmlTags(String html) {
    // Remove style and script blocks entirely
    var result = html.replaceAll(
      RegExp('<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true),
      '',
    );
    result = result.replaceAll(
      RegExp(
        '<script[^>]*>.*?</script>',
        caseSensitive: false,
        dotAll: true,
      ),
      '',
    );

    // Replace common block elements with newlines
    result =
        result.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    result = result.replaceAll(RegExp('</p>', caseSensitive: false), '\n\n');
    result = result.replaceAll(RegExp('</div>', caseSensitive: false), '\n');
    result = result.replaceAll(RegExp('</tr>', caseSensitive: false), '\n');
    result = result.replaceAll(RegExp('</li>', caseSensitive: false), '\n');

    // Remove all remaining HTML tags
    result = result.replaceAll(RegExp('<[^>]+>'), '');

    // Decode common HTML entities
    result = result
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");

    // Clean up whitespace
    result = result.replaceAll(RegExp(r'[ \t]+'), ' ');
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return result.trim();
  }
}

/// Widget that tries to render HTML, falling back to plain text if empty.
class _HtmlBodyView extends StatelessWidget {
  const _HtmlBodyView({
    required this.html,
    required this.fallbackText,
  });

  final String html;
  final String fallbackText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If HTML is mostly empty after stripping, just show fallback as plain text
    if (fallbackText.isEmpty) {
      return Text(
        'No content available',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    // Clean up email HTML for flutter_html compatibility
    final cleanedHtml = _cleanEmailHtml(html);
    debugPrint(
      'Cleaned HTML: ${cleanedHtml.length} chars (from ${html.length})',
    );

    // Render HTML with flutter_html
    return Html(
      data: cleanedHtml,
      onLinkTap: (url, _, __) => _launchUrl(url),
      style: {
        '*': Style(
          color: theme.textTheme.bodyMedium?.color,
          fontSize: FontSize(14),
        ),
        'body': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        'html': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        'a': Style(
          color: theme.colorScheme.primary,
          textDecoration: TextDecoration.underline,
        ),
        'p': Style(
          margin: Margins.only(bottom: 8),
        ),
        'td': Style(
          padding: HtmlPaddings.all(4),
        ),
        'img': Style(
          width: Width(100, Unit.percent),
        ),
      },
    );
  }

  /// Clean email HTML to make it compatible with flutter_html.
  String _cleanEmailHtml(String html) {
    var result = html;

    // Remove DOCTYPE
    result =
        result.replaceAll(RegExp('<!DOCTYPE[^>]*>', caseSensitive: false), '');

    // Remove XML declarations
    result =
        result.replaceAll(RegExp(r'<\?xml[^>]*\?>', caseSensitive: false), '');

    // Remove MS Office conditional comments and their content
    result = result.replaceAll(
      RegExp(
        r'<!--\[if[^\]]*\]>.*?<!\[endif\]-->',
        caseSensitive: false,
        dotAll: true,
      ),
      '',
    );
    result = result.replaceAll(
      RegExp(
        r'<!--\[if[^\]]*\]>.*?<!endif-->',
        caseSensitive: false,
        dotAll: true,
      ),
      '',
    );

    // Remove style blocks (flutter_html doesn't use them well anyway)
    result = result.replaceAll(
      RegExp('<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true),
      '',
    );

    // Remove VML/Office namespaced elements
    result = result.replaceAll(
      RegExp('<v:[^>]*>.*?</v:[^>]*>', caseSensitive: false, dotAll: true),
      '',
    );
    result = result.replaceAll(
      RegExp('<o:[^>]*>.*?</o:[^>]*>', caseSensitive: false, dotAll: true),
      '',
    );
    result = result.replaceAll(RegExp('<v:[^>]*/>', caseSensitive: false), '');
    result = result.replaceAll(RegExp('<o:[^>]*/>', caseSensitive: false), '');

    // Remove xmlns attributes that might confuse the parser
    result = result.replaceAll(RegExp(r'\s+xmlns[^=]*="[^"]*"'), '');

    // Remove mso-* style properties inline
    result = result.replaceAll(RegExp('mso-[^;:"]+:[^;:"]+;?'), '');

    // Clean up head tag content (keep only title if present)
    result = result.replaceAll(
      RegExp('<head[^>]*>.*?</head>', caseSensitive: false, dotAll: true),
      '',
    );

    // Simplify the html tag
    result = result.replaceAll(
      RegExp('<html[^>]*>', caseSensitive: false),
      '<html>',
    );

    return result.trim();
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
