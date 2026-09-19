import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {double scale = 2, bool disableAnimations = true}) {
  return MaterialApp(
    builder: (context, content) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        disableAnimations: disableAnimations,
      ),
      child: content!,
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  for (final scale in [2.0, 3.2]) {
    testWidgets('critical controls remain reachable at ${scale}x text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        host(
          ListView(
            padding: const EdgeInsets.all(12),
            children: [
              FlareButton(
                label: 'Retry sending the message safely',
                block: true,
                onPressed: () {},
              ),
              const SizedBox(height: 12),
              const FlareInput(
                placeholder: 'Long localized account or conversation name',
              ),
              const SizedBox(height: 12),
              FlareConversationRow(
                item: const ConversationRowData(
                  id: 'large-text',
                  title: 'Long translated conversation title',
                  preview: 'Draft and latest message remain available',
                  timestampLabel: '23:59',
                  unreadCount: 120,
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(
                width: 280,
                child: FlareMessageMeta(
                  timestamp: '23:59',
                  edited: true,
                  ephemeral: FlareMessageEphemeralState.burnAfterRead,
                  status: FlareMessageDeliveryStatus.failed,
                ),
              ),
              const SizedBox(height: 12),
              FlareComposer(onSend: (_) => true),
            ],
          ),
          scale: scale,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Retry sending the message safely'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byType(FlareComposer),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(FlareComposer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reduced motion removes button transition', (tester) async {
    await tester.pumpWidget(
      host(FlareButton(label: 'Continue', onPressed: () {})),
    );
    expect(
      tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).duration,
      Duration.zero,
    );
  });

  testWidgets('hardware keyboard traverses and activates buttons', (
    tester,
  ) async {
    var activated = 0;
    await tester.pumpWidget(
      host(
        Row(
          children: [
            FlareButton(label: 'First', onPressed: () => activated++),
            FlareButton(label: 'Second', onPressed: () => activated++),
          ],
        ),
        scale: 1,
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(activated, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(activated, 2);
  });
}
