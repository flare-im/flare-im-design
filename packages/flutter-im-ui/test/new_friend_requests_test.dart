import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// A request's source ("通过名片添加，由 X 推荐") is its own secondary line
// under the message, never sharing the message's line.

void main() {
  testWidgets('draws the source on its own line under the message', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareNewFriendRequests(
            items: const [
              FlareFriendRequest(
                id: 'r1',
                name: 'Cleo',
                message: '我是 Cleo',
                source: '通过名片添加，由 Ann 推荐',
              ),
              FlareFriendRequest(id: 'r2', name: 'Ann', message: 'Hi'),
            ],
            onAccept: (_) {},
            onReject: (_) {},
          ),
        ),
      ),
    );
    final source = find.byKey(const ValueKey('flare-friend-request-source-r1'));
    expect(source, findsOneWidget);
    expect(tester.widget<Text>(source).data, '通过名片添加，由 Ann 推荐');
    expect(tester.widget<Text>(source).maxLines, 1);
    // Its own line: below the message, not beside it.
    final message = tester.getRect(find.text('我是 Cleo'));
    final line = tester.getRect(source);
    expect(line.top, greaterThanOrEqualTo(message.bottom));
    expect(line.left, message.left);
    // A request without a source keeps its two lines.
    expect(
      find.byKey(const ValueKey('flare-friend-request-source-r2')),
      findsNothing,
    );
  });
}
