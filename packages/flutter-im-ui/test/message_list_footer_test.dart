import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

FlareMessageData _message(String id) => FlareMessageData(
  id: id,
  senderId: 'ann',
  senderName: 'Ann',
  content: FlareTextContent('message $id'),
);

/// The contract has declared a `footer` slot on `MessageList` for all four platforms since the catalogue
/// was written; only Vue ever had one, and nothing checked. The typing indicator needs it: it belongs to
/// the conversation, under the newest row, not pinned above the composer where a reader scrolled up would
/// be told someone is typing at a row they are not looking at.
void main() {
  testWidgets('the footer is drawn under the newest message', (tester) async {
    await tester.pumpWidget(
      _host(
        FlareMessageList(
          messages: [_message('m1'), _message('m2')],
          currentUserId: 'me',
          footer: const FlareTypingIndicator(names: ['Ann'], variant: FlareTypingVariant.inline),
        ),
      ),
    );
    // The indicator's dots never stop, so `pumpAndSettle` never would either.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final indicator = find.byType(FlareTypingIndicator);
    expect(indicator, findsOneWidget);
    // "Under the newest" is a position, not a widget-tree order: assert the geometry.
    expect(
      tester.getCenter(indicator).dy,
      greaterThan(tester.getCenter(find.text('message m2')).dy),
    );
  });

  testWidgets('no footer draws nothing extra', (tester) async {
    await tester.pumpWidget(
      _host(FlareMessageList(messages: [_message('m1')], currentUserId: 'me')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FlareTypingIndicator), findsNothing);
  });
}
