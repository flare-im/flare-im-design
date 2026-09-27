import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'shared button supports keyboard activation and respects unavailable states',
    (tester) async {
      var count = 0;
      Widget host({
        bool disabled = false,
        bool loading = false,
        bool handler = true,
      }) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: FlareButton(
              label: 'Run',
              disabled: disabled,
              loading: loading,
              onPressed: handler ? () => count++ : null,
            ),
          ),
        ),
      );
      await tester.pumpWidget(host());
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(count, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(count, 2);
      for (final mode in [0, 1, 2]) {
        await tester.pumpWidget(
          host(disabled: mode == 0, loading: mode == 1, handler: mode != 2),
        );
        await tester.tap(find.text('Run'));
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(count, 2);
      }
    },
  );
  testWidgets('inline shared buttons do not consume the entire row', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              FlareButton(label: 'Accept', onPressed: () {}),
              FlareButton(
                label: 'Decline',
                variant: FlareButtonVariant.secondary,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(FlareButton).first).width, lessThan(200));
  });
  testWidgets('a block button centres its label across its width', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: FlareButton(label: 'Save', block: true, onPressed: () {}),
          ),
        ),
      ),
    );
    final button = tester.getRect(find.byType(FlareButton));
    final label = tester.getRect(find.text('Save'));
    expect(button.width, 300);
    // The label box hugs the text (a full-width box would draw it at the
    // start edge) and sits in the middle of the button.
    expect(label.width, lessThan(button.width / 2));
    expect(label.center.dx, closeTo(button.center.dx, 1));
  });
  testWidgets('a long label in a narrow block button stays inside it', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            child: FlareButton(
              label: 'A very long confirmation label that cannot fit',
              block: true,
              icon: 'check',
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final button = tester.getRect(find.byType(FlareButton));
    final label = tester.getRect(
      find.text('A very long confirmation label that cannot fit'),
    );
    expect(label.right, lessThanOrEqualTo(button.right));
  });
}
