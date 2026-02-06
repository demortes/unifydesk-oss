import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/email_message.dart';
import '../../../../core/services/app_services.dart';
// unused imports removed

/// Widget to display full email content.
class EmailDetailView extends StatelessWidget {
  const EmailDetailView({
    super.key,
    required this.email,
    required this.onClose,
    required this.onToggleStar,
    required this.onDelete,
    required this.onArchive,
    required this.onMarkUnread,
  });

  final EmailMessage email;
  final VoidCallback onClose;
  final VoidCallback onToggleStar;
  final VoidCallback onDelete;
  final VoidCallback onArchive;
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
                icon: const Icon(Icons.archive_outlined),
                onPressed: onArchive,
                tooltip: 'Archive',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'view_source') {
                    _showSource(context);
                    return;
                  }
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
                  const PopupMenuItem(
                    value: 'view_source',
                    child: ListTile(
                      leading: Icon(Icons.code),
                      title: Text('View Raw Source'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Email header (fixed, not scrollable)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
              const SizedBox(height: 16),
              const Divider(height: 1),
            ],
          ),
        ),
        // Body content (expanded to fill all remaining space)
        Expanded(
          child: _buildBody(context),
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
        senderAddress: email.from.address,
      );
    }

    // Fall back to plain text (scrollable since it's inside Expanded)
    if (email.textBody != null && email.textBody!.isNotEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          email.textBody!,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    // No content
    return Center(
      child: Text(
        'No content available',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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

  /// Return the raw server source if available, otherwise build a
  /// rendered/assembled source for inspection. The raw source should
  /// contain the full MIME payload including headers and boundaries.
  String _buildRawSource() {
    if (email.rawSource != null && email.rawSource!.isNotEmpty) {
      try {
        // Decode lazily with permissive UTF-8 to avoid crashes on malformed bytes
        final decoded = const Utf8Decoder(allowMalformed: true).convert(email.rawSource!);
        return decoded;
      } catch (e) {
        // As a fallback, base64-encode the raw bytes so they are viewable
        return '---- RAW BINARY SOURCE (base64) ----\n${base64.encode(email.rawSource!)}';
      }
    }

    final buffer = StringBuffer();
    buffer.writeln('<!-- NOTE: raw server source not available; showing assembled view -->');
    buffer.writeln('From: ${email.from}');
    buffer.writeln('To: ${_formatRecipients(email.to)}');
    if (email.cc.isNotEmpty) buffer.writeln('Cc: ${_formatRecipients(email.cc)}');
    buffer.writeln('Subject: ${email.subject}');
    buffer.writeln('Date: ${email.date.toUtc().toIso8601String()}');
    if (email.messageId != null) buffer.writeln('Message-ID: ${email.messageId}');
    if (email.inReplyTo != null) buffer.writeln('In-Reply-To: ${email.inReplyTo}');
    if (email.references.isNotEmpty) buffer.writeln('References: ${email.references.join(' ')}');
    buffer.writeln('Account: ${email.accountId}');
    buffer.writeln('Mailbox: ${email.mailboxName}');
    buffer.writeln('UID: ${email.uid}');
    buffer.writeln();
    buffer.writeln('---- RAW PLAIN TEXT BODY ----');
    buffer.writeln(email.textBody ?? '(none)');
    buffer.writeln();
    buffer.writeln('---- RAW HTML BODY ----');
    buffer.writeln(email.htmlBody ?? '(none)');

    return buffer.toString();
  }

  void _showSource(BuildContext context) {
    final source = _buildRawSource();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message Source'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              source,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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

/// Widget that tries to render HTML using WebView, falling back to plain text if empty.
class _HtmlBodyView extends StatefulWidget {
  const _HtmlBodyView({
    required this.html,
    required this.fallbackText,
    required this.senderAddress,
  });

  final String html;
  final String fallbackText;
  final String senderAddress;

  @override
  State<_HtmlBodyView> createState() => _HtmlBodyViewState();
}

class _HtmlBodyViewState extends State<_HtmlBodyView> {
  bool _loadedOnce = false;
  InAppWebViewController? _controller;
  bool _disposed = false;
  bool _isPlainTextFallback = false;
  static final Logger _logger = Logger();
  String _htmlContent = '';

  // Stable key for the InAppWebView to prevent recreation across builds
  final _webViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    AppServices.imageBlockingService.addListener(_onServiceChanged);
    AppServices.imageAllowlistService.addListener(_onServiceChanged);
    _prepareContent();
  }

  void _onServiceChanged() {
    if (mounted && !_disposed) {
      _prepareContent();
      _loadContent();
      setState(() {});
    }
  }

  void _prepareContent() {
    final blockRemote = AppServices.imageBlockingService.blockRemoteImages;
    final allowlist = AppServices.imageAllowlistService.allowlist;
    final senderAllowed = allowlist.contains(widget.senderAddress.toLowerCase());
    final effectiveBlock = blockRemote && !senderAllowed && !_loadedOnce;

    final cleanedHtml = _cleanEmailHtml(widget.html);

    // Check if we should fall back to plain text
    _isPlainTextFallback = cleanedHtml.trim().isEmpty || cleanedHtml.trim() == '<html>';

    final processedHtml = effectiveBlock ? _stripNetworkImages(cleanedHtml) : cleanedHtml;
    _htmlContent = _wrapHtmlForWebView(processedHtml);

    _logger.d('Prepared HTML for WebView (${_htmlContent.length} chars)');
  }

  void _loadContent() {
    if (_controller != null && mounted && !_disposed) {
      _logger.d('Loading HTML into WebView');
      _controller!.loadData(data: _htmlContent);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _controller = null;
    AppServices.imageBlockingService.removeListener(_onServiceChanged);
    AppServices.imageAllowlistService.removeListener(_onServiceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blockRemote = AppServices.imageBlockingService.blockRemoteImages;
    final allowlist = AppServices.imageAllowlistService.allowlist;
    final senderAllowed = allowlist.contains(widget.senderAddress.toLowerCase());

    try {
      // If cleaning removed most content, fallback to plain text
      if (_isPlainTextFallback) {
        _logger.w('Cleaned HTML is empty, falling back to plain text');

        if (widget.fallbackText.isNotEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              widget.fallbackText,
              style: theme.textTheme.bodyMedium,
            ),
          );
        }

        return Center(
          child: Text(
            'No content available',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }

      final effectiveBlock = blockRemote && !senderAllowed && !_loadedOnce;

      // Use a stable key so the InAppWebView is NOT recreated across rebuilds.
      // No fixed height — the parent Expanded provides the constraints.
      final webViewWidget = InAppWebView(
          key: _webViewKey,
          initialData: InAppWebViewInitialData(data: _htmlContent),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: false,
            transparentBackground: true,
            supportZoom: false,
            disableContextMenu: true,
          ),
          onWebViewCreated: (controller) {
            if (!_disposed && mounted) {
              _controller = controller;
            }
          },
          onLoadStop: (controller, url) {
            _logger.d('WebView finished loading');
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            final url = navigationAction.request.url;
            if (url != null) {
              final urlString = url.toString();
              if (urlString.startsWith('http://') ||
                  urlString.startsWith('https://')) {
                _launchUrl(urlString);
                return NavigationActionPolicy.CANCEL;
              }
            }
            return NavigationActionPolicy.CANCEL;
          },
      );

      if (effectiveBlock) {
        return _buildImageBlockingBanner(context, webViewWidget);
      }

      return webViewWidget;
    } catch (e, stackTrace) {
      _logger.e('Error in HTML body view build', error: e, stackTrace: stackTrace);
      return _buildErrorFallback(context, e);
    }
  }

  String _wrapHtmlForWebView(String html) {
    // Wrap the email HTML in a complete document with responsive styling
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes">
  <style>
    * {
      box-sizing: border-box;
    }
    body {
      margin: 0;
      padding: 16px;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      font-size: 14px;
      line-height: 1.5;
      color: #333;
      word-wrap: break-word;
      overflow-wrap: break-word;
    }
    img {
      max-width: 100%;
      height: auto;
    }
    table {
      max-width: 100%;
      border-collapse: collapse;
    }
    a {
      color: #1976d2;
      text-decoration: underline;
    }
    .remote-image-blocked {
      padding: 8px;
      background: #f0f0f0;
      border: 1px dashed #ccc;
      margin: 4px 0;
      text-align: center;
      color: #666;
      font-size: 12px;
    }
  </style>
</head>
<body>
$html
</body>
</html>
''';
  }


  Widget _buildImageBlockingBanner(BuildContext context, Widget webViewWidget) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(Icons.image_not_supported,
                  color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Remote images are blocked for this message.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              TextButton(
                onPressed: () {
                  _logger.i(
                      'User chose to load images once for ${widget.senderAddress}');
                  setState(() {
                    _loadedOnce = true;
                    _prepareContent();
                    _loadContent();
                  });
                },
                child: const Text('Load once'),
              ),
              TextButton(
                onPressed: () {
                  _logger.i(
                      'User chose to always allow images for ${widget.senderAddress}');
                  AppServices.imageAllowlistService
                      .allow(widget.senderAddress);
                  setState(() {
                    _loadedOnce = true;
                    _prepareContent();
                    _loadContent();
                  });
                },
                child: const Text('Always load for this sender'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: webViewWidget),
      ],
    );
  }

  Widget _buildErrorFallback(BuildContext context, Object error) {
    final theme = Theme.of(context);
    _logger.w('Falling back to plain text due to error: $error');
    
    if (widget.fallbackText.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: theme.colorScheme.onErrorContainer,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'HTML rendering failed. Showing plain text version.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SelectableText(
            widget.fallbackText,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Unable to display email content. Please try refreshing.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Safely extract a substring preview, clamping the end index.
  String _safeSubstring(String? text, int maxLength) {
    if (text == null || text.isEmpty) return '';
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Clean email HTML to make it compatible with flutter_html.
  String _cleanEmailHtml(String html) {
    _logger.d('Starting HTML cleaning process');
    _logger.d('Original HTML length: ${html.length}');
    _logger.v('Original HTML preview (first 300 chars): ${_safeSubstring(html, 300)}');
    
    var result = html;
    var stepCount = 0;
    final removalLog = <String>[];

    void logStep(String description, String before, String after, {bool logContent = false}) {
      stepCount++;
      final removedCount = before.length - after.length;
      if (removedCount > 0) {
        final percentReduced = (removedCount / before.length * 100).toStringAsFixed(1);
        final logEntry = 'Step $stepCount - $description: Removed $removedCount characters ($percentReduced%) (${before.length} -> ${after.length})';
        removalLog.add(logEntry);
        _logger.d(logEntry);
        
        if (logContent && removedCount > 0) {
          // Find what was actually removed by comparing strings
          final removedContent = _findRemovedContent(before, after);
          if (removedContent.isNotEmpty) {
            _logger.t('  Content removed: ${_safeSubstring(removedContent, 200)}');
          }
        }
      }
    }

    // If the message was transferred with quoted-printable encoding the HTML
    // often contains soft line breaks and =XX hex escapes (e.g. =3D for =).
    // Decode that first so subsequent regexes operate on normal text.
    final beforeQP = result;
    result = _decodeQuotedPrintable(result);
    logStep('Quoted-printable decoding', beforeQP, result);

    // Remove DOCTYPE
    final beforeDoctype = result;
    result = result.replaceAll(RegExp('<!DOCTYPE[^>]*>', caseSensitive: false), '');
    logStep('DOCTYPE removal', beforeDoctype, result, logContent: true);

    // Remove XML declarations
    final beforeXML = result;
    result = result.replaceAll(RegExp(r'<\?xml[^>]*\?>', caseSensitive: false), '');
    logStep('XML declaration removal', beforeXML, result, logContent: true);

    // Remove MS Office conditional comments and their content
    final beforeMSComments1 = result;
    result = result.replaceAll(
      RegExp(
        r'<!--\[if[^\]]*\]>.*?<!\[endif\]-->',
        caseSensitive: false,
        dotAll: true,
      ),
      '',
    );
    logStep('MS Office conditional comments (type 1)', beforeMSComments1, result, logContent: true);
    
    final beforeMSComments2 = result;
    result = result.replaceAll(
      RegExp(
        r'<!--\[if[^\]]*\]>.*?<!endif-->',
        caseSensitive: false,
        dotAll: true,
      ),
      '',
    );
    logStep('MS Office conditional comments (type 2)', beforeMSComments2, result, logContent: true);

    // Remove style blocks (flutter_html doesn't use them well anyway)
    final beforeStyles = result;
    final styleMatches = RegExp('<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true).allMatches(result);
    if (styleMatches.isNotEmpty) {
      _logger.d('Found ${styleMatches.length} style blocks to remove');
      for (final match in styleMatches) {
        _logger.t('Removing style block: ${_safeSubstring(match.group(0), 100)}');
      }
    }
    result = result.replaceAll(
      RegExp('<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true),
      '',
    );
    logStep('Style blocks removal', beforeStyles, result, logContent: true);

    // Remove VML/Office namespaced elements
    final beforeVML = result;
    final vmlMatches = RegExp('<v:[^>]*>.*?</v:[^>]*>', caseSensitive: false, dotAll: true).allMatches(result);
    if (vmlMatches.isNotEmpty) {
      _logger.d('Found ${vmlMatches.length} VML elements to remove');
    }
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
    logStep('VML/Office elements removal', beforeVML, result, logContent: true);

    // Remove xmlns attributes that might confuse the parser
    final beforeXmlns = result;
    final xmlnsMatches = RegExp(r'\s+xmlns[^=]*="[^"]*"').allMatches(result);
    if (xmlnsMatches.isNotEmpty) {
      _logger.d('Found ${xmlnsMatches.length} xmlns attributes to remove');
    }
    result = result.replaceAll(RegExp(r'\s+xmlns[^=]*="[^"]*"'), '');
    logStep('Xmlns attributes removal', beforeXmlns, result);

    // Remove mso-* style properties inline
    final beforeMso = result;
    final msoMatches = RegExp('mso-[^;:"]+:[^;:"]+;?').allMatches(result);
    if (msoMatches.isNotEmpty) {
      _logger.d('Found ${msoMatches.length} mso-* properties to remove');
    }
    result = result.replaceAll(RegExp('mso-[^;:"]+:[^;:"]+;?'), '');
    logStep('MSO style properties removal', beforeMso, result);

    // Clean up head tag content (keep only title if present)
    final beforeHead = result;
    final headMatches = RegExp('<head[^>]*>.*?</head>', caseSensitive: false, dotAll: true).allMatches(result);
    if (headMatches.isNotEmpty) {
      _logger.d('Found ${headMatches.length} head sections to remove');
      for (final match in headMatches) {
        _logger.t('Removing head section: ${_safeSubstring(match.group(0), 200)}');
      }
    }
    result = result.replaceAll(
      RegExp('<head[^>]*>.*?</head>', caseSensitive: false, dotAll: true),
      '',
    );
    logStep('Head tag removal', beforeHead, result, logContent: true);

    // Simplify the html tag
    final beforeHtmlTag = result;
    result = result.replaceAll(
      RegExp('<html[^>]*>', caseSensitive: false),
      '<html>',
    );
    logStep('HTML tag simplification', beforeHtmlTag, result);

    final finalResult = result.trim();
    
    // Comprehensive logging summary
    _logger.i('HTML cleaning completed:');
    _logger.i('  Original length: ${html.length}');
    _logger.i('  Final length: ${finalResult.length}');
    _logger.i('  Reduction: ${html.length - finalResult.length} characters (${((html.length - finalResult.length) / html.length * 100).toStringAsFixed(1)}%)');
    _logger.i('  Processing steps: $stepCount');
    
    // Log summary of all removals
    if (removalLog.isNotEmpty) {
      _logger.i('  Content removal summary:');
      for (final entry in removalLog) {
        _logger.i('    $entry');
      }
    }

    // Check if the result looks valid
    final hasBodyTag = finalResult.toLowerCase().contains('<body');
    final hasContent = finalResult.replaceAll(RegExp('<[^>]*>'), '').trim().isNotEmpty;
    final suspiciouslySmall = finalResult.length < 50 && html.length > 500;
    
    if (suspiciouslySmall) {
      _logger.w('Warning: Cleaned HTML is suspiciously small compared to original');
      _logger.w('  This might indicate over-aggressive cleaning');
    }
    
    if (!hasContent) {
      _logger.w('Warning: Cleaned HTML appears to have no text content');
    }
    
    _logger.d('Final HTML analysis: hasBodyTag=$hasBodyTag, hasContent=$hasContent');

    // Log a preview of the final HTML for debugging
    if (finalResult.length > 500) {
      _logger.t('Final HTML preview (first 500 chars): ${finalResult.substring(0, 500)}...');
    } else {
      _logger.t('Final HTML: $finalResult');
    }

    return finalResult;
  }
  
  /// Helper method to identify what content was removed between two strings
  String _findRemovedContent(String before, String after) {
    try {
      // Simple approach: find first major difference
      final beforeLines = before.split('\n');
      final afterLines = after.split('\n');
      
      final removedLines = <String>[];
      var beforeIndex = 0;
      var afterIndex = 0;
      
      while (beforeIndex < beforeLines.length && afterIndex < afterLines.length) {
        if (beforeLines[beforeIndex] == afterLines[afterIndex]) {
          beforeIndex++;
          afterIndex++;
        } else {
          // Found a difference, try to find where it ends
          final removedContent = beforeLines[beforeIndex];
          if (removedContent.trim().isNotEmpty && removedContent.length > 10) {
            removedLines.add(removedContent.trim());
          }
          beforeIndex++;
          if (removedLines.length >= 3) break; // Limit to avoid spam
        }
      }
      
      return removedLines.join(' | ');
    } catch (e) {
      return 'Error analyzing removed content: $e';
    }
  }

  /// Decode a quoted-printable encoded string into a UTF-8 string.
  /// This handles soft line breaks (="CRLF") and hex escapes (=XX).
  String _decodeQuotedPrintable(String input) {
    if (!input.contains('=')) {
      _logger.t('No quoted-printable encoding detected');
      return input;
    }

    _logger.d('Decoding quoted-printable content (${input.length} chars)');
    
    // Count soft line breaks for logging
    final softBreakCount = RegExp(r'=\r?\n').allMatches(input).length;
    if (softBreakCount > 0) {
      _logger.d('Found $softBreakCount soft line breaks to remove');
    }

    // Remove soft line breaks '=' at end of lines
    var s = input.replaceAll(RegExp(r'=\r\n'), '');
    s = s.replaceAll(RegExp(r'=\n'), '');

    final bytes = <int>[];
    var hexEscapeCount = 0;
    
    for (var i = 0; i < s.length; i++) {
      final ch = s.codeUnitAt(i);
      if (ch == 0x3D) { // '='
        // Try to parse two hex digits following '='
        if (i + 2 < s.length) {
          final hex = s.substring(i + 1, i + 3);
          if (RegExp(r'^[0-9A-Fa-f]{2}$').hasMatch(hex)) {
            try {
              final val = int.parse(hex, radix: 16);
              bytes.add(val);
              i += 2;
              hexEscapeCount++;
              continue;
            } catch (e) {
              _logger.t('Failed to parse hex escape =$hex: $e');
              // fall through to treat '=' literally
            }
          }
          // Common pattern: =20 =C2=A0 etc. If next two are hex, handled above.
        }
        // Not a hex escape — emit '=' as-is
        bytes.add(ch);
        continue;
      }
      // Normal character, emit its Latin-1 byte value to preserve raw bytes
      bytes.add(ch & 0xFF);
    }

    if (hexEscapeCount > 0) {
      _logger.d('Decoded $hexEscapeCount hex escapes');
    }

    try {
      final decoded = const Utf8Decoder(allowMalformed: true).convert(bytes);
      _logger.d('Quoted-printable decoding successful (${input.length} -> ${decoded.length} chars)');
      return decoded;
    } catch (e) {
      _logger.w('Quoted-printable decoding failed, returning original: $e');
      // Fallback: return original input if decoding fails
      return input;
    }
  }

  /// Replace <img ... src="http..."> occurrences with a harmless
  /// placeholder div so flutter_html doesn't attempt to fetch remote images
  /// when blocking is enabled.
  String _stripNetworkImages(String html) {
    final imageRegex = RegExp("<img\\b[^>]*\\bsrc=[\"'](https?:[^\"']+)[\"'][^>]*>", caseSensitive: false);
    final matches = imageRegex.allMatches(html);
    
    if (matches.isNotEmpty) {
      _logger.d('Stripping ${matches.length} network images from HTML');
      for (final match in matches) {
        _logger.t('Blocking image: ${match.group(1)}');
      }
    }
    
    return html.replaceAllMapped(
      imageRegex,
      (m) {
        final imageUrl = m.group(1) ?? 'unknown';
        return '<div class="remote-image-blocked" style="padding: 8px; background: #f0f0f0; border: 1px dashed #ccc; margin: 4px 0; text-align: center; color: #666;">🚫 Remote image blocked: $imageUrl</div>';
      },
    );
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}