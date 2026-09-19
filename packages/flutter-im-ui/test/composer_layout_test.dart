import 'package:extended_text_field/extended_text_field.dart';
import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                    onSend: (_) => true,
                    onImage: () {},
                    actions: FlareComposerActionPanel.defaultActions,
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          for (final icon in [
            flareIconMap['emoji']!,
            flareIconMap['mention']!,
            flareIconMap['mic']!,
            flareIconMap['image']!,
            flareIconMap['rich-text']!,
            flareIconMap['add']!,
            flareIconMap['send']!,
          ]) {
            final control = find.ancestor(
              of: find.byIcon(icon),
              matching: find.byType(IconButton),
            );
            expect(tester.getSize(control), const Size(44, 44));
          }
          await tester.tap(find.byIcon(flareIconMap['add']!));
          await tester.pump();
          expect(find.byType(ExtendedTextField), findsNothing);
          await tester.tap(find.byIcon(flareIconMap['close']!));
          await tester.pump();
          expect(controller.text, 'Draft stays here');
          await tester.tap(find.byIcon(flareIconMap['rich-text']!));
          await tester.pump();
          await tester.tap(
            find.ancestor(
              of: find.byIcon(Icons.format_bold),
              matching: find.byType(IconButton),
            ),
          );
          await tester.pump();
          expect(controller.text, 'Draft stays here');
          expect(tester.takeException(), isNull);
          await tester.tap(find.byIcon(flareIconMap['mic']!));
          await tester.pump();
          expect(find.byType(FlareInlineVoice), findsOneWidget);
          await tester.tap(find.byIcon(flareIconMap['keyboard']!));
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
                onSend: (_) {
                  sent++;
                  return true;
                },
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

  testWidgets('modifier submit mode preserves Enter and sends Ctrl+Enter', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'desktop draft');
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    final sent = <String>[];
    tester.view.physicalSize = const Size(1024, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareComposer(
            controller: controller,
            focusNode: focusNode,
            desktopSubmitMode: FlareComposerSubmitMode.modifierEnter,
            onSend: (text) {
              sent.add(text);
              return true;
            },
          ),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(sent, isEmpty);
    expect(controller.text, contains('desktop draft'));
    controller.text = 'desktop draft';
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(sent, ['desktop draft']);
    expect(controller.text, isEmpty);
  });
}
