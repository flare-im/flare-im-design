import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/src/components/flare_message_batch_toolbar.dart';

/// The toolbar owns leaving the selection: Escape and the system back exit it, an editable
/// control keeps its own Escape, and a running batch consumes both without exiting.
void main() {
  const caps = FlareMessageBatchCapabilities(delete: true);
  Widget host({required VoidCallback? onExit, bool busy = false}) =>
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const TextField(key: Key('draft')),
              FlareMessageBatchToolbar(
                selectedIds: const ['a'],
                total: 3,
                capabilities: caps,
                busy: busy,
                onExit: onExit,
              ),
            ],
          ),
        ),
      );

  testWidgets('Escape leaves the selection, unless a text field has focus', (
    tester,
  ) async {
    var exits = 0;
    await tester.pumpWidget(host(onExit: () => exits++));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(exits, 1);
    // Typing: the field's Escape comes first; the toolbar leaves it alone.
    await tester.tap(find.byKey(const Key('draft')));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(exits, 1);
  });

  testWidgets('a running batch consumes Escape and back without exiting', (
    tester,
  ) async {
    var exits = 0;
    await tester.pumpWidget(host(onExit: () => exits++, busy: true));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(exits, 0);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    // A vetoed pop counts as handled: consumed, the page stays, nothing exits.
    expect(await navigator.maybePop(), isTrue);
    expect(exits, 0);
  });

  testWidgets(
    'the system back leaves the selection before it leaves the page',
    (tester) async {
      var exits = 0;
      await tester.pumpWidget(host(onExit: () => exits++));
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      // Consumed by the toolbar (the page stays), and the selection is gone.
      expect(await navigator.maybePop(), isTrue);
      expect(exits, 1);
    },
  );

  testWidgets('without an exit handler nothing is claimed', (tester) async {
    await tester.pumpWidget(host(onExit: null));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    // Nothing vetoes the pop: on the root route it simply bubbles to the system.
    expect(await navigator.maybePop(), isFalse);
    expect(tester.takeException(), isNull);
  });
}
