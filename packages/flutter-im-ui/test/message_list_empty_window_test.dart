import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const strings = FlareStrings();

Widget host(Widget list) => MaterialApp(
  home: Scaffold(body: SizedBox(height: 500, child: list)),
);

void main() {
  testWidgets('only a proven empty window says no messages', (tester) async {
    await tester.pumpWidget(
      host(const FlareMessageList(messages: [], currentUserId: 'me')),
    );
    expect(find.text(strings.noMessages), findsOneWidget);
    expect(find.text(strings.retry), findsNothing);
  });

  for (final older in [true, false]) {
    testWidgets(
      'unknown empty window offers one explicit retry: older=$older',
      (tester) async {
        var calls = 0;
        await tester.pumpWidget(
          host(
            FlareMessageList(
              messages: const [],
              currentUserId: 'me',
              hasOlder: older,
              hasNewer: !older,
              onLoadOlder: older ? () => calls++ : null,
              onLoadNewer: older ? null : () => calls++,
            ),
          ),
        );
        await tester.pump();
        expect(
          calls,
          0,
          reason: 'an unknown empty view never starts a request itself',
        );
        expect(find.text(strings.noMessages), findsNothing);
        expect(
          find.text(strings.conversationWorkspaceChatFailure),
          findsOneWidget,
        );
        await tester.tap(find.text(strings.retry));
        await tester.tap(find.text(strings.retry));
        await tester.pump();
        expect(calls, 1);
        expect(find.text(strings.noMessages), findsNothing);
      },
    );
  }

  for (final pageLoading in [false, true]) {
    testWidgets(
      'an empty window being loaded shows progress: page=$pageLoading',
      (tester) async {
        await tester.pumpWidget(
          host(
            FlareMessageList(
              messages: const [],
              currentUserId: 'me',
              loading: !pageLoading,
              hasOlder: true,
              loadingOlder: pageLoading,
              onLoadOlder: () {},
            ),
          ),
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text(strings.noMessages), findsNothing);
        expect(find.text(strings.retry), findsNothing);
      },
    );
  }

  testWidgets('an empty failed page keeps its actual error', (tester) async {
    await tester.pumpWidget(
      host(
        FlareMessageList(
          messages: const [],
          currentUserId: 'me',
          hasOlder: true,
          olderError: 'History is offline',
          onLoadOlder: () {},
        ),
      ),
    );
    expect(find.text('History is offline'), findsOneWidget);
    expect(find.text(strings.conversationWorkspaceChatFailure), findsNothing);
    expect(find.text(strings.noMessages), findsNothing);
  });

  testWidgets('an explicit empty failure is not a proven empty conversation', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const FlareMessageList(
          messages: [],
          currentUserId: 'me',
          olderError: 'History is offline',
        ),
      ),
    );
    expect(find.text('History is offline'), findsOneWidget);
    expect(find.text(strings.noMessages), findsNothing);
    expect(find.text(strings.retry), findsNothing);
  });

  testWidgets('known rows remain visible when older history fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        FlareMessageList(
          messages: [
            FlareMessageData(
              id: 'known',
              senderId: 'peer',
              senderName: 'Peer',
              content: const FlareTextContent('cached row'),
            ),
          ],
          currentUserId: 'me',
          hasOlder: true,
          olderError: 'History is offline',
          onLoadOlder: () {},
        ),
      ),
    );
    expect(find.text('cached row'), findsOneWidget);
    expect(find.text('History is offline'), findsOneWidget);
    expect(find.byType(FlareEmptyState), findsNothing);
  });

  testWidgets('the host can retain its own empty failure placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        FlareMessageList(
          messages: const [],
          currentUserId: 'me',
          hasOlder: true,
          onLoadOlder: () {},
          emptyPlaceholder: const Text('Host failure'),
        ),
      ),
    );
    expect(find.text('Host failure'), findsOneWidget);
    expect(find.text(strings.noMessages), findsNothing);
  });
}
