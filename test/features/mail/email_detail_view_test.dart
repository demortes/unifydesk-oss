import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:unifydesk/features/mail/presentation/widgets/email_detail_view.dart';
import 'package:unifydesk/features/mail/domain/entities/email_message.dart';

void main() {
  testWidgets('renders HTML body when htmlBody is provided', (WidgetTester tester) async {
    final email = EmailMessage(
      id: '1',
      accountId: 'acc',
      uid: 1,
      mailboxName: 'INBOX',
      from: const EmailAddress(address: 'sender@example.com', displayName: 'Sender'),
      subject: 'HTML email',
      date: DateTime.now(),
      // HTML-only body (image-only content)
      htmlBody: '<html><body><img src="https://example.com/image.png" alt="img"/></body></html>',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmailDetailView(
            email: email,
            onClose: () {},
            onToggleStar: () {},
            onDelete: () {},
            onArchive: () {},
            onMarkUnread: () {},
          ),
        ),
      ),
    );

    // Allow any async layout to settle
    await tester.pumpAndSettle();

    // The InAppWebView should be present to render the HTML
    expect(find.byType(InAppWebView), findsOneWidget);

    // Ensure we do not show the empty-state placeholder
    expect(find.text('No content available'), findsNothing);
  });

  testWidgets('shows raw server source when available via menu', (WidgetTester tester) async {
    const raw = 'RAW-MIME-START\r\nFrom: sender@example.com\r\n...';

    final email = EmailMessage(
      id: '2',
      accountId: 'acc',
      uid: 2,
      mailboxName: 'INBOX',
      from: const EmailAddress(address: 'sender@example.com', displayName: 'Sender'),
      subject: 'Raw source',
      date: DateTime.now(),
      textBody: 'plain text',
      rawSource: Uint8List.fromList(utf8.encode(raw)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmailDetailView(
            email: email,
            onClose: () {},
            onToggleStar: () {},
            onDelete: () {},
            onArchive: () {},
            onMarkUnread: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open popup menu (tap the overflow icon)
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Tap 'View Raw Source'
    expect(find.text('View Raw Source'), findsOneWidget);
    await tester.tap(find.text('View Raw Source'));
    await tester.pumpAndSettle();

    // Dialog should appear with raw content
    expect(find.text('Message Source'), findsOneWidget);
    expect(find.textContaining('RAW-MIME-START'), findsOneWidget);
  });
}
