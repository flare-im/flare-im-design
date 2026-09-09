import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

FlareMessageData message(int i, {String? body}) => FlareMessageData(
  id: 'm$i',
  senderId: 'other',
  senderName: 'Other',
  content: FlareTextContent(body ?? 'Message $i — ${'line ' * (i % 4 + 1)}'),
);
void main() {
  testWidgets(
    'prepend, concurrent append and edits above reader preserve visible row',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      var rows = [for (var i = 20; i < 60; i++) message(i)];
      Future<void> render() => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: FlareMessageList(
                messages: rows,
                currentUserId: 'me',
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await render();
      await tester.pumpAndSettle();
      controller.jumpTo(350);
      await tester.pumpAndSettle();
      final visible = find
          .byType(FlareMessageBubble)
          .evaluate()
          .map((e) => e.widget as FlareMessageBubble)
          .firstWhere((w) {
            final rect = tester.getRect(find.byKey(ValueKey(w.message.id)));
            return rect.bottom > 0 && rect.top < 400;
          });
      final key = find.byKey(ValueKey(visible.message.id));
      final y = tester.getTopLeft(key).dy;
      rows = [for (var i = 0; i < 20; i++) message(i), ...rows, message(60)];
      await render();
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(key).dy, closeTo(y, 1));
      rows = [message(0, body: 'edited long history ' * 50), ...rows.skip(1)];
      await render();
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(key).dy, closeTo(y, 1));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'pagination is single-flight, retries explicitly and respects exhausted history',
    (tester) async {
      var calls = 0;
      var loading = false;
      var hasOlder = true;
      String? error;
      Future<void> render() => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlareMessageList(
              messages: [message(1)],
              currentUserId: 'me',
              hasOlder: hasOlder,
              loadingOlder: loading,
              olderError: error,
              onLoadOlder: () => calls++,
            ),
          ),
        ),
      );
      await render();
      await tester.tap(find.byType(TextButton));
      await tester.pump();
      await tester.tap(find.byType(TextButton));
      expect(calls, 1);
      loading = true;
      await render();
      expect(find.byType(TextButton), findsNothing);
      loading = false;
      error = '网络失败';
      await render();
      expect(find.text('网络失败'), findsOneWidget);
      await tester.tap(find.byType(TextButton));
      expect(calls, 2);
      hasOlder = false;
      error = null;
      await render();
      expect(find.byType(TextButton), findsNothing);
    },
  );
}
