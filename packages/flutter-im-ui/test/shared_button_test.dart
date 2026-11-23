import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flare_im_ui/src/components/red_packet_tint.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _pressHost(Widget child, {bool reduceMotion = false}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: Scaffold(body: Center(child: child)),
    ),
  ),
);

Color? _fill(WidgetTester tester, Type type) =>
    (tester
                .widget<AnimatedContainer>(
                  find
                      .descendant(
                        of: find.byType(type),
                        matching: find.byType(AnimatedContainer),
                      )
                      .first,
                )
                .decoration!
            as BoxDecoration)
        .color;

double _scale(WidgetTester tester, Type type) => tester
    .widget<AnimatedScale>(
      find.descendant(
        of: find.byType(type),
        matching: find.byType(AnimatedScale),
      ),
    )
    .scale;

/// Holds a finger on [type]'s centre until the tap-down lands.
Future<TestGesture> _hold(WidgetTester tester, Type type) async {
  final finger = await tester.startGesture(tester.getCenter(find.byType(type)));
  await tester.pump(const Duration(milliseconds: 200));
  return finger;
}

void main() {
  testWidgets(
    'a long inline label wraps inside a narrow parent at large text size',
    (tester) async {
      const label = 'Confirm debit and create packet';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: SizedBox(
                width: 180,
                child: FlareButton(
                  label: label,
                  icon: 'check',
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final control = tester.getRect(find.byType(FlareButton));
      final text = tester.getRect(find.text(label));
      expect(text.right, lessThanOrEqualTo(control.right));
      expect(text.height, greaterThan(20));
    },
  );
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

  // §7 / §12.10: press shrinks to 0.98 and takes the pressed colour.
  for (final (variant, rest, pressedOf)
      in <
        (
          FlareButtonVariant,
          Color Function(FlareColors),
          Color Function(FlareColors),
        )
      >[
        (FlareButtonVariant.primary, (c) => c.primary, (c) => c.primaryActive),
        (FlareButtonVariant.danger, (c) => c.error, (c) => c.errorActive),
        (FlareButtonVariant.secondary, (c) => c.bgSecondary, (c) => c.bgHover),
        (FlareButtonVariant.quiet, (_) => Colors.transparent, (c) => c.bgHover),
        (FlareButtonVariant.text, (_) => Colors.transparent, (c) => c.bgHover),
      ]) {
    testWidgets('a pressed $variant key shrinks and darkens', (tester) async {
      await tester.pumpWidget(
        _pressHost(
          FlareButton(label: 'Go', variant: variant, onPressed: () {}),
        ),
      );
      final colors = FlareColors.of(tester.element(find.byType(FlareButton)));
      expect(_fill(tester, FlareButton), rest(colors));
      expect(_scale(tester, FlareButton), 1);
      final finger = await _hold(tester, FlareButton);
      expect(_fill(tester, FlareButton), pressedOf(colors));
      expect(_scale(tester, FlareButton), FlareButton.pressScale);
      await finger.up();
      await tester.pumpAndSettle();
      expect(_fill(tester, FlareButton), rest(colors));
      expect(_scale(tester, FlareButton), 1);
    });
  }

  testWidgets('reduced motion: a pressed key changes colour, not size', (
    tester,
  ) async {
    await tester.pumpWidget(
      _pressHost(
        FlareButton(label: 'Go', onPressed: () {}),
        reduceMotion: true,
      ),
    );
    final colors = FlareColors.of(tester.element(find.byType(FlareButton)));
    final finger = await _hold(tester, FlareButton);
    expect(_fill(tester, FlareButton), colors.primaryActive);
    expect(_scale(tester, FlareButton), 1);
    await finger.up();
  });

  testWidgets('a pointer over a danger key takes errorHover', (tester) async {
    await tester.pumpWidget(
      _pressHost(
        FlareButton(
          label: 'Delete',
          variant: FlareButtonVariant.danger,
          onPressed: () {},
        ),
      ),
    );
    final colors = FlareColors.of(tester.element(find.byType(FlareButton)));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(FlareButton)));
    await tester.pump();
    expect(_fill(tester, FlareButton), colors.errorHover);
  });

  testWidgets('the red packet tint reaches the pressed key', (tester) async {
    await tester.pumpWidget(
      _pressHost(
        FlareRedPacketTint(
          child: FlareButton(label: 'Pay', onPressed: () {}),
        ),
      ),
    );
    final colors = FlareColors.of(tester.element(find.byType(FlareButton)));
    final finger = await _hold(tester, FlareButton);
    expect(_fill(tester, FlareButton), colors.redPacketEndActive);
    await finger.up();
  });

  testWidgets('a disabled key does not press', (tester) async {
    await tester.pumpWidget(
      _pressHost(
        const FlareButton(label: 'Go', disabled: true, onPressed: null),
      ),
    );
    final finger = await _hold(tester, FlareButton);
    expect(_scale(tester, FlareButton), 1);
    await finger.up();
  });

  testWidgets('sizes take the type tokens and the spinner icon-size-sm', (
    tester,
  ) async {
    for (final (size, font) in [
      (FlareControlSize.sm, FlareSizes.fontSizeMd),
      (FlareControlSize.md, FlareSizes.fontSizeLg),
      (FlareControlSize.lg, FlareSizes.fontSizeXl),
    ]) {
      await tester.pumpWidget(
        _pressHost(FlareButton(label: 'Go', size: size, onPressed: () {})),
      );
      expect(tester.widget<Text>(find.text('Go')).style!.fontSize, font);
    }
    await tester.pumpWidget(
      _pressHost(FlareButton(label: 'Go', loading: true, onPressed: () {})),
    );
    expect(
      tester.getSize(find.byType(CircularProgressIndicator)),
      const Size.square(FlareSizes.iconSizeSm),
    );
  });

  testWidgets('a pressed icon button shrinks and darkens', (tester) async {
    for (final (variant, pressedOf)
        in <(FlareIconButtonVariant, Color Function(FlareColors))>[
          (FlareIconButtonVariant.solid, (c) => c.primaryActive),
          (FlareIconButtonVariant.plain, (c) => c.bgHover),
          (FlareIconButtonVariant.tinted, (c) => c.bgHover),
        ]) {
      await tester.pumpWidget(
        _pressHost(
          FlareIconButton(
            icon: 'check',
            semanticLabel: 'Done',
            variant: variant,
            onPressed: () {},
          ),
        ),
      );
      final colors = FlareColors.of(
        tester.element(find.byType(FlareIconButton)),
      );
      final finger = await _hold(tester, FlareIconButton);
      expect(
        _fill(tester, FlareIconButton),
        pressedOf(colors),
        reason: '$variant',
      );
      expect(_scale(tester, FlareIconButton), FlareButton.pressScale);
      await finger.up();
      await tester.pumpAndSettle();
      expect(_scale(tester, FlareIconButton), 1);
    }
    await tester.pumpWidget(
      _pressHost(
        FlareIconButton(icon: 'check', semanticLabel: 'Done', onPressed: () {}),
        reduceMotion: true,
      ),
    );
    final finger = await _hold(tester, FlareIconButton);
    expect(_scale(tester, FlareIconButton), 1);
    await finger.up();
  });
}
