import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(
  TextEditingController controller,
  FlareComposerCapabilities capabilities,
) => MaterialApp(
  home: Scaffold(
    body: Align(
      alignment: Alignment.bottomCenter,
      child: FlareComposer(
        controller: controller,
        capabilities: capabilities,
        onSend: (_) => true,
        onSendRich: (_) {},
        enableVoice: true,
        onVoiceSend: (_, _) async => true,
      ),
    ),
  ),
);

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets('toolbar follows host availability at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = TextEditingController(text: 'preserved draft');
      await tester.pumpWidget(
        host(
          controller,
          const FlareComposerCapabilities(
            availableActionIds: {},
            availableToolIds: {},
          ),
        ),
      );
      const strings = FlareStrings();
      for (final tooltip in [
        strings.composerEmoji,
        strings.composerMention,
        strings.composerVoiceInput,
        strings.actionImage,
        strings.composerRichText,
        strings.more,
      ]) {
        expect(find.byTooltip(tooltip), findsNothing);
      }
      expect(controller.text, 'preserved draft');
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });
  }

  testWidgets('revoking an open attachment or rich panel keeps the draft', (
    tester,
  ) async {
    final controller = TextEditingController(
      text: 'draft must survive policy change',
    );
    const all = FlareComposerCapabilities(availableActionIds: {'file'});
    const none = FlareComposerCapabilities(
      availableActionIds: {},
      availableToolIds: {},
    );
    await tester.pumpWidget(host(controller, all));
    await tester.tap(find.byTooltip(const FlareStrings().more));
    await tester.pumpAndSettle();
    expect(find.text(const FlareStrings().actionFile), findsWidgets);
    await tester.pumpWidget(host(controller, none));
    await tester.pumpAndSettle();
    expect(find.text(const FlareStrings().actionFile), findsNothing);
    expect(controller.text, 'draft must survive policy change');
    await tester.pumpWidget(host(controller, all));
    await tester.tap(find.byTooltip(const FlareStrings().composerRichText));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(controller, none));
    await tester.pumpAndSettle();
    expect(controller.text, 'draft must survive policy change');
    expect(
      find.byKey(const ValueKey('composer-format-divider-line')),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
