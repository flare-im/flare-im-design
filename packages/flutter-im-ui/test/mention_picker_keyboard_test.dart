import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// FR-103 (K6): with a keyboard the picker is a combobox — focus stays in the
// search field, the first match is highlighted, the arrows move it, Enter
// picks it (not while an input method composes) and Escape closes.

const _people = [
  FlareMentionCandidate(id: 'u1', name: 'Ann'),
  FlareMentionCandidate(id: 'u2', name: 'Anton'),
  FlareMentionCandidate(id: 'u3', name: 'Bob'),
];

Future<(List<String>, List<String>)> _pump(WidgetTester tester) async {
  final picked = <String>[];
  final closed = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: FlareMentionPicker(
            candidates: _people,
            autofocus: true,
            onSelect: (candidate) => picked.add(candidate.id),
            onClose: () => closed.add('close'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (picked, closed);
}

List<bool> _highlighted(WidgetTester tester) => [
  for (final name in ['Ann', 'Anton', 'Bob'])
    if (find.text(name).evaluate().isNotEmpty)
      tester
              .widget<ColoredBox>(
                find
                    .ancestor(
                      of: find.text(name),
                      matching: find.byType(ColoredBox),
                    )
                    .first,
              )
              .color !=
          Colors.transparent,
];

void main() {
  testWidgets(
    'arrows move the highlight from the first match and Enter picks',
    (tester) async {
      final (picked, _) = await _pump(tester);
      final search = tester.state<EditableTextState>(find.byType(EditableText));
      expect(search.widget.focusNode.hasFocus, isTrue);
      expect(_highlighted(tester), [true, false, false]);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_highlighted(tester), [false, true, false]);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(_highlighted(tester), [
        false,
        false,
        true,
      ], reason: 'wraps around');
      // Focus never left the field.
      expect(search.widget.focusNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(picked, ['u3']);
    },
  );

  testWidgets('typing highlights the first match again', (tester) async {
    final (picked, _) = await _pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.enterText(find.byType(TextField), 'an');
    await tester.pump();
    expect(_highlighted(tester), [true, false]);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(picked, ['u1']);
  });

  testWidgets('the Enter that commits a composition is left to the input '
      'method; Escape closes', (tester) async {
    final (picked, closed) = await _pump(tester);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'an',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(picked, isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(closed, ['close']);
  });

  testWidgets('a tap still picks the person tapped', (tester) async {
    final (picked, _) = await _pump(tester);
    await tester.tap(find.text('Anton'));
    expect(picked, ['u2']);
  });
}
