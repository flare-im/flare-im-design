import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';

Widget host(
  Widget child, {
  FlareStrings strings = const FlareStrings(),
  Brightness brightness = Brightness.light,
}) => MaterialApp(
  theme: ThemeData(brightness: brightness),
  home: FlareStringsScope(
    strings: strings,
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets(
    'packet supports touch and keyboard; unavailable commands are inert',
    (tester) async {
      var calls = 0;
      Widget card({
        bool disabled = false,
        bool busy = false,
        FlareRedPacketCardState state = FlareRedPacketCardState.unopened,
        bool handler = true,
      }) => FlareRedPacketCard(
        blessing: 'Hello',
        disabled: disabled,
        busy: busy,
        state: state,
        onOpen: handler ? () => calls++ : null,
      );
      await tester.pumpWidget(host(card()));
      await tester.tap(find.byType(FlareRedPacketCard));
      expect(calls, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(calls, 2);
      // A spent packet still opens: that is how the viewer reaches the details.
      await tester.pumpWidget(
        host(card(state: FlareRedPacketCardState.finished)),
      );
      await tester.tap(find.byType(FlareRedPacketCard));
      expect(calls, 3);
      for (final mode in [0, 1, 2]) {
        await tester.pumpWidget(
          host(card(disabled: mode == 0, busy: mode == 1, handler: mode != 2)),
        );
        await tester.tap(find.byType(FlareRedPacketCard));
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(calls, 3);
      }
    },
  );
  testWidgets(
    'packet uses kit locale for every state and exposes progress semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        for (final entry in [
          (
            const FlareRedPacketCard(blessing: 'Hello', busy: true),
            'Processing…',
          ),
          (
            const FlareRedPacketCard(blessing: 'Hello', disabled: true),
            'Unavailable',
          ),
          (
            const FlareRedPacketCard(
              blessing: 'Hello',
              state: FlareRedPacketCardState.finished,
            ),
            'All claimed',
          ),
          // The card never shows an amount, not even the viewer's own.
          (
            const FlareRedPacketCard(
              blessing: 'Hello',
              state: FlareRedPacketCardState.claimed,
            ),
            'Opened',
          ),
          (
            const FlareRedPacketCard(
              blessing: 'Hello',
              disabled: true,
              statusLabel: 'Created',
            ),
            'Created',
          ),
        ]) {
          await tester.pumpWidget(host(entry.$1, strings: flareStringsEnglish));
          expect(find.text(entry.$2), findsOneWidget);
          expect(find.bySemanticsLabel('Hello'), findsOneWidget);
        }
        await tester.pumpWidget(
          host(
            const FlareRedPacketCard(blessing: 'Hello', busy: true),
            strings: flareStringsEnglish,
          ),
        );
        final data = tester
            .getSemantics(find.bySemanticsLabel('Hello'))
            .getSemanticsData();
        expect(data.flagsCollection.isLiveRegion, isTrue);
        expect(data.hasAction(ui.SemanticsAction.tap), isFalse);
      } finally {
        semantics.dispose();
      }
    },
  );
  testWidgets(
    'generic plugin removes sensitive fields and actions when unavailable',
    (tester) async {
      await tester.pumpWidget(
        host(
          const FlarePluginView(
            view: FlarePluginViewModel(
              available: false,
              title: 'History',
              fields: [FlarePluginField(label: 'Private', value: 'secret')],
              actions: [FlarePluginAction(id: 'claim', label: 'Claim')],
            ),
          ),
        ),
      );
      expect(find.text('History'), findsOneWidget);
      expect(find.text('secret'), findsNothing);
      expect(find.byType(FlareButton), findsNothing);
    },
  );
  testWidgets(
    'generic plugin forwards only the action id and busy prevents a repeat',
    (tester) async {
      final calls = <String>[];
      Widget card(bool busy) => FlarePluginView(
        view: const FlarePluginViewModel(
          available: true,
          title: 'AI',
          actions: [FlarePluginAction(id: 'draft', label: 'Generate')],
        ),
        busy: busy,
        onAction: (id, _) => calls.add(id),
      );
      await tester.pumpWidget(host(card(false)));
      await tester.tap(find.text('Generate'));
      expect(calls, ['draft']);
      await tester.pumpWidget(host(card(true)));
      await tester.tap(find.text('Generate'));
      expect(calls, ['draft']);
    },
  );
  for (final width in [180.0, 390.0, 1024.0]) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      testWidgets(
        'packet respects width $width and $brightness with large text',
        (tester) async {
          await tester.pumpWidget(
            host(
              MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
                child: SizedBox(
                  width: width,
                  child: const FlareRedPacketCard(
                    blessing: 'Long greeting 祝福语',
                    busy: true,
                  ),
                ),
              ),
              brightness: brightness,
            ),
          );
          expect(tester.takeException(), isNull);
          final size = tester.getSize(find.byType(FlareRedPacketCard));
          expect(size.width, lessThanOrEqualTo(width));
          expect(size.height, greaterThanOrEqualTo(48));
        },
      );
    }
  }
  testWidgets('capture shared plugin and packet components', (tester) async {
    const output = String.fromEnvironment('FLARE_PLUGIN_KIT_SCREENSHOTS');
    if (output.isNotEmpty) {
      await tester.runAsync(() async {
        final loader = FontLoader('KitQA');
        final bytes = await File(
          '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
        ).readAsBytes();
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
        await loader.load();
        final icons = FontLoader('MaterialIcons');
        icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
      });
    }
    for (final specimen in [
      (390.0, 820.0, Brightness.light),
      (1280.0, 860.0, Brightness.dark),
    ]) {
      tester.view.physicalSize = Size(specimen.$1, specimen.$2);
      tester.view.devicePixelRatio = 1;
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: specimen.$3,
            fontFamily: output.isEmpty ? null : 'KitQA',
          ),
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              body: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FlareRedPacketCard(
                            blessing: '恭喜发财 · Best wishes',
                            disabled: true,
                            statusLabel: '已创建 · Created',
                          ),
                          const SizedBox(height: 24),
                          FlarePluginView(
                            view: const FlarePluginViewModel(
                              available: true,
                              title: 'AI 插件 · AI draft',
                              fields: [
                                FlarePluginField(
                                  label: '结果 / Result',
                                  value:
                                      'All components come from Flare IM Design.',
                                ),
                              ],
                              actions: [
                                FlarePluginAction(
                                  id: 'draft',
                                  label: '生成 / Generate',
                                ),
                              ],
                            ),
                            onAction: (_, _) {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (output.isNotEmpty) {
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(output).create(recursive: true);
          await File(
            '$output/flutter-${specimen.$3.name}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
