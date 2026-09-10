import 'package:extended_text_field/extended_text_field.dart';
import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 390.0, 1024.0]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'composer fits $width $brightness and preserves draft through panels',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 800);
          addTearDown(tester.view.reset);
          final controller = TextEditingController(text: 'Draft stays here');
          addTearDown(controller.dispose);
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: FlareComposer(
                    controller: controller,
                    enableVoice: true,
                    onVoiceSend: (_, _) async => true,
                    onSend: (_) {},
                    onImage: () {},
                    actions: FlareMessageActionSheet.defaultActions,
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          for (final icon in [
            Icons.emoji_emotions_outlined,
            Icons.alternate_email,
            Icons.mic_none,
            Icons.image_outlined,
            Icons.text_fields,
            Icons.add,
            Icons.send_outlined,
          ]) {
            final control = find.ancestor(
              of: find.byIcon(icon),
              matching: find.byType(IconButton),
            );
            expect(tester.getSize(control), const Size(44, 44));
          }
          await tester.tap(find.byIcon(Icons.add));
          await tester.pump();
          expect(find.byType(ExtendedTextField), findsNothing);
          await tester.tap(find.byIcon(Icons.close));
          await tester.pump();
          expect(controller.text, 'Draft stays here');
          await tester.tap(find.byIcon(Icons.text_fields));
          await tester.pump();
          await tester.tap(find.byTooltip('Bold'));
          await tester.pump();
          expect(controller.text, 'Draft stays here');
          expect(tester.takeException(), isNull);
          await tester.tap(find.byIcon(Icons.mic_none));
          await tester.pump();
          expect(find.byType(FlareInlineVoice), findsOneWidget);
          await tester.tap(find.byIcon(Icons.keyboard_outlined));
          await tester.pump();
          expect(controller.text, 'Draft stays here');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'disabled input never sends and replacing a controller detaches the old draft',
    (tester) async {
      final first = TextEditingController(text: 'first');
      final second = TextEditingController(text: 'second');
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      var sent = 0;
      Widget host(TextEditingController controller, bool disabled) =>
          MaterialApp(
            home: Scaffold(
              body: FlareComposer(
                controller: controller,
                disabled: disabled,
                onSend: (_) => sent++,
              ),
            ),
          );
      await tester.pumpWidget(host(first, false));
      await tester.pumpWidget(host(second, true));
      first.text = 'old draft changed';
      await tester.pump();
      expect(
        tester
            .widget<ExtendedTextField>(find.byType(ExtendedTextField))
            .controller,
        second,
      );
      await tester.tap(find.byIcon(Icons.send_outlined));
      expect(sent, 0);
      expect(second.text, 'second');
      expect(tester.takeException(), isNull);
    },
  );
}
