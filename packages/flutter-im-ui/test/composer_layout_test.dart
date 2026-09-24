import 'package:extended_text_field/extended_text_field.dart';
import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 390.0, 599.0, 600.0, 1024.0]) {
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
          final wide = width >= FlareSizes.navigationRailMinWidth;
          final initialHeight = tester
              .getSize(find.byType(FlareComposer))
              .height;
          expect(initialHeight, wide ? lessThanOrEqualTo(64) : greaterThan(80));
          final fieldCenter = tester.getCenter(find.byType(ExtendedTextField));
          final emojiCenter = tester.getCenter(
            find.byIcon(flareIconMap['emoji']!),
          );
          expect(
            (fieldCenter.dy - emojiCenter.dy).abs(),
            wide ? lessThan(8) : greaterThan(20),
          );
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
            expect(
              tester.getSize(control),
              wide ? const Size(34, 36) : const Size(44, 44),
            );
            final iconButton = tester.widget<IconButton>(control);
            expect(iconButton.iconSize, FlareSizes.iconSizeMd);
          }
          await tester.tap(find.byIcon(flareIconMap['add']!));
          await tester.pump();
          // Web keeps the editor mounted while the attach surface is open, so
          // selection, focus and the draft survive the round trip.
          expect(find.byType(ExtendedTextField), findsOneWidget);
          expect(find.byType(FlareComposerActionPanel), findsOneWidget);
          await tester.tap(find.byIcon(flareIconMap['close']!));
          await tester.pump();
          expect(controller.text, 'Draft stays here');
          await tester.tap(find.byIcon(flareIconMap['rich-text']!));
          await tester.pump();
          const formatIds = [
            'heading',
            'bold',
            'strike',
            'italic',
            'underline',
            'ordered',
            'bullet',
            'quote',
            'link',
            'image',
            'code',
            'code-block',
            'horizontal-rule',
          ];
          for (final id in formatIds) {
            expect(find.byKey(ValueKey('composer-format-$id')), findsOneWidget);
          }
          final centers = formatIds
              .map(
                (id) => tester
                    .getCenter(find.byKey(ValueKey('composer-format-$id')))
                    .dx,
              )
              .toList();
          expect(centers, orderedEquals([...centers]..sort()));
          if (wide) {
            final composerTop = tester
                .getTopLeft(find.byType(FlareComposer))
                .dy;
            final headingRect = tester.getRect(
              find.byKey(const ValueKey('composer-format-heading')),
            );
            final lowerDivider = tester.getTopLeft(
              find.byKey(const ValueKey('composer-format-divider-line')),
            );
            expect(
              // The top hairline is painted inside the composer's box.
              headingRect.top - composerTop - 1,
              closeTo(lowerDivider.dy - headingRect.bottom, 0.01),
            );
          }
          await tester.tap(find.byKey(const ValueKey('composer-format-bold')));
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
  testWidgets('coarse pointers expand the heading levels in place', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: FlarePlatformScope(
          adapter: const FlareUnsupportedPlatformAdapter(
            capabilities: FlarePlatformCapabilities(
              pointer: FlarePointerKind.coarse,
            ),
          ),
          child: Scaffold(body: FlareComposer(onSend: (_) => true)),
        ),
      ),
    );
    await tester.tap(find.byIcon(flareIconMap['rich-text']!));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('composer-format-heading')));
    await tester.pump();
    for (final id in [
      'paragraph',
      'heading-1',
      'heading-2',
      'heading-3',
      'heading-4',
      'heading-5',
      'heading-6',
    ]) {
      expect(find.byKey(ValueKey('composer-format-$id')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('composer-format-bold')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('composer-format-heading-3')));
    await tester.pump();
    expect(find.text('H3'), findsOneWidget);
    expect(find.byKey(const ValueKey('composer-format-bold')), findsOneWidget);
  });

  testWidgets(
    'desktop rich toolbar starts left and exposes Web P and H labels',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1024, 800);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: FlarePlatformScope(
            adapter: const FlareUnsupportedPlatformAdapter(
              capabilities: FlarePlatformCapabilities(
                pointer: FlarePointerKind.fine,
              ),
            ),
            child: Scaffold(body: FlareComposer(onSend: (_) => true)),
          ),
        ),
      );

      expect(flareIconMap['rich-text'], Icons.title);
      expect(
        find.byKey(const ValueKey('composer-resize-action')),
        findsOneWidget,
      );
      expect(find.byType(FlareComposerResizeIcon), findsOneWidget);
      await tester.tap(find.byIcon(Icons.title));
      await tester.pump();

      final composerLeft = tester.getTopLeft(find.byType(FlareComposer)).dx;
      final headingLeft = tester
          .getTopLeft(find.byKey(const ValueKey('composer-format-heading')))
          .dx;
      expect(headingLeft, closeTo(composerLeft + FlareSizes.spacingMd, 0.01));

      await tester.tap(find.byKey(const ValueKey('composer-format-heading')));
      await tester.pumpAndSettle();
      for (final label in ['P', 'H1', 'H2', 'H3', 'H4', 'H5', 'H6']) {
        expect(find.text(label), findsWidgets);
      }
      expect(find.text('正文'), findsNothing);
      expect(find.text('标题 1'), findsNothing);

      final menuLabelLefts = <double>[
        tester.getTopLeft(find.text('P').last).dx,
        for (var level = 1; level <= 6; level++)
          tester.getTopLeft(find.text('H$level').last).dx,
      ];
      for (final left in menuLabelLefts.skip(1)) {
        expect(left, closeTo(menuLabelLefts.first, 0.01));
      }
    },
  );

  testWidgets('desktop resize and send follow the Web composer lifecycle', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1024, 800);
    addTearDown(tester.view.reset);
    final controller = TextEditingController(text: 'send me');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: FlareComposer(controller: controller, onSend: (_) => true),
          ),
        ),
      ),
    );

    final collapsedHeight = tester.getSize(find.byType(FlareComposer)).height;
    await tester.tap(find.byKey(const ValueKey('composer-resize-action')));
    await tester.pump();
    expect(
      tester.getSize(find.byType(FlareComposer)).height,
      greaterThan(collapsedHeight),
    );
    expect(
      tester.widget<ExtendedTextField>(find.byType(ExtendedTextField)).minLines,
      6,
    );

    await tester.tap(find.byIcon(flareIconMap['send']!));
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(
      tester.getSize(find.byType(FlareComposer)).height,
      closeTo(collapsedHeight, 0.01),
    );
  });

  testWidgets('emoji packs and tabs are identical on mobile and desktop', (
    tester,
  ) async {
    for (final width in [390.0, 1024.0]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: FlareComposer(
                key: ValueKey(width),
                onSend: (_) => true,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(flareIconMap['emoji']!));
      // Animated image decoding/progress indicators deliberately keep frames
      // scheduled, so settling is the wrong completion signal for this panel.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(FlareEmojiStickerPicker), findsOneWidget);
      expect(find.text('表情'), findsOneWidget);
      expect(find.text('Classic'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);
    }
    addTearDown(tester.view.reset);
  });

  testWidgets(
    'the more-panel voice action opens the same recorder as toolbar',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 800);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: FlareComposer(
                enableVoice: true,
                onVoiceSend: (_, _) async => true,
                capabilities: const FlareComposerCapabilities(
                  availableActionIds: {'image', 'video', 'file', 'voice'},
                ),
                onAction: (_) {},
                onSend: (_) => true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(flareIconMap['add']!));
      await tester.pump();
      for (final label in ['图片', '视频', '文件', '语音']) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.text('语音'));
      await tester.pump();
      expect(find.byType(FlareInlineVoice), findsOneWidget);
      expect(find.byType(FlareComposerActionPanel), findsNothing);
    },
  );

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
