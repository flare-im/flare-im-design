import 'package:extended_text_field/extended_text_field.dart';
import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => FlareEmojiStickerCatalog.instance.ensureLoaded());

  test('composer emoji span displays an image and preserves the raw token', () {
    final span = FlareComposerEmojiSpanBuilder().build(
      'hello [alien]',
      textStyle: const TextStyle(fontSize: 15),
    );

    final image = span.children!.whereType<ExtendedWidgetSpan>().single;
    expect(image.actualText, '[alien]');
    expect(image.start, 6);
    expect(image.child, isA<Semantics>());
  });

  test('unknown bracket tokens remain editable plain text', () {
    final span = FlareComposerEmojiSpanBuilder().build(
      '[not_a_pack_key]',
      textStyle: const TextStyle(fontSize: 15),
    );

    expect(span.children!.whereType<ExtendedWidgetSpan>(), isEmpty);
    expect(span.toPlainText(), '[not_a_pack_key]');
  });

  testWidgets('composer sends the protocol token shown as an image', (
    tester,
  ) async {
    String? sent;
    final controller = TextEditingController(text: '[alien]');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 720,
            child: FlareComposer(
              controller: controller,
              onSend: (value) {
                sent = value;
                return true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = tester.widget<ExtendedTextField>(
      find.byType(ExtendedTextField),
    );
    final span = field.specialTextSpanBuilder!.build(controller.text);
    expect(span.children!.whereType<ExtendedWidgetSpan>(), hasLength(1));
    expect(controller.text, '[alien]');
    final editable = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_ExtendedEditable',
    );
    final dynamic render = tester.renderObject(editable);
    final renderedText = render.text as TextSpan;
    expect(
      renderedText.children!.whereType<ExtendedWidgetSpan>(),
      hasLength(1),
      reason: 'the editable renderer must use the emoji span builder',
    );

    await tester.tap(find.byType(FlareComposerSendButton));
    await tester.pumpAndSettle();
    expect(sent, '[alien]');
    expect(controller.text, isEmpty);
  });
}
