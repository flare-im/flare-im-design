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
}
