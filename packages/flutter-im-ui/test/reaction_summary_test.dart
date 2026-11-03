import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('narrow touch footer wraps without overlapping targets', (
    tester,
  ) async {
    final taps = <String>[];
    const time = ValueKey('footer-time');
    Future<void> pump(double width) => tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: FlareReactionSummary(
                reactions: const [
                  FlareReactionGroup(emoji: 'A', count: 1),
                  FlareReactionGroup(emoji: 'B', count: 2),
                  FlareReactionGroup(emoji: 'C', count: 3),
                  FlareReactionGroup(emoji: 'D', count: 4),
                ],
                hideAdd: true,
                onToggle: taps.add,
                trailing: const SizedBox(key: time, width: 40, height: 14),
              ),
            ),
          ),
        ),
      ),
    );

    await pump(170);
    final buttons = find.byType(TextButton);
    final a = tester.getRect(buttons.at(0));
    final b = tester.getRect(buttons.at(1));
    final d = tester.getRect(buttons.at(3));
    final label = tester.getRect(find.text('A 1'));
    final meta = tester.getRect(find.byKey(time));
    expect(a.width, greaterThanOrEqualTo(44));
    expect(a.height, greaterThanOrEqualTo(44));
    expect(label.top, lessThan(a.top + 6));
    expect(b.left, greaterThanOrEqualTo(a.right));
    expect(d.top, greaterThanOrEqualTo(a.bottom));
    expect(meta.center.dy, closeTo(d.top + 11, 1));
    expect(meta.right, 170);
    // The blank half of each slot still belongs to the visible pill.
    await tester.tapAt(Offset(a.center.dx, a.bottom - 3));
    await tester.tapAt(Offset(b.center.dx, b.bottom - 3));
    await tester.tapAt(Offset(d.center.dx, d.bottom - 3));
    expect(taps, ['A', 'B', 'D']);

    await pump(90);
    final last = tester.getRect(buttons.at(3));
    final narrowMeta = tester.getRect(find.byKey(time));
    expect(narrowMeta.top, greaterThanOrEqualTo(last.bottom));
    expect(narrowMeta.right, 90);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reacted text uses one external timestamp next to its pill', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.macOS),
        home: const Scaffold(
          body: FlareMessageBubble(
            message: FlareMessageData(
              id: 'reacted-text',
              senderId: 'alice',
              senderName: 'Alice',
              content: FlareTextContent('Test message with room for metadata'),
              timeLabel: '11:58 PM',
              reactions: [FlareReactionGroup(emoji: 'OK', count: 2)],
            ),
            currentUserId: 'me',
          ),
        ),
      ),
    );
    final surface = tester.getRect(
      find.byKey(FlareMessageBubble.bubbleSurfaceKey),
    );
    final footer = tester.getRect(find.byType(FlareReactionSummary));
    final reaction = tester.getRect(find.text('OK 2'));
    final time = tester.getRect(find.text('11:58 PM'));
    expect(footer.top - surface.bottom, 4);
    expect(time.center.dy, closeTo(reaction.center.dy, 2));
    expect(time.right, closeTo(surface.right, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reactions expose selection and support keyboard activation', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareReactionSummary(
            reactions: const [
              FlareReactionGroup(emoji: 'OK', count: 2, reactedBySelf: true),
            ],
            hideAdd: true,
            onToggle: (value) => selected = value,
          ),
        ),
      ),
    );
    final button = find.byType(TextButton);
    expect(
      tester.getSize(button).height,
      greaterThanOrEqualTo(FlareSizes.touchTargetMin),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('OK 2')),
      matchesSemantics(
        label: 'OK 2',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(selected, 'OK');
    semantics.dispose();
  });

  testWidgets(
    'missing callbacks disable controls and add action uses scoped label',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FlareStringsScope(
            strings: const FlareStrings(addReaction: 'Add reaction'),
            child: const Scaffold(
              body: FlareReactionSummary(
                reactions: [FlareReactionGroup(emoji: 'OK', count: 1)],
              ),
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Add reaction'), findsOneWidget);
      // Without onToggle a reaction is a label, not a disabled control.
      expect(find.bySemanticsLabel('OK 1'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'OK 1'), findsNothing);
      for (final button in tester.widgetList<TextButton>(
        find.byType(TextButton),
      )) {
        expect(button.onPressed, isNull);
      }
    },
  );
}
