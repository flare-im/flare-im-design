import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
      greaterThanOrEqualTo(FlareSizes.touchTarget),
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
