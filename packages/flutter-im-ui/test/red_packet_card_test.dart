import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared card table (`spec/red-packet-vectors.json` → card): the status
/// line precedence and the tap rule every kit follows. Finished and expired
/// packets stay tappable — that is how the viewer reaches the details.
/// The colours the envelope glyph is painted with (its painter is private to
/// the kit, so they are read by name).
({Color body, Color bodyDeep, Color seal}) glyphOf(WidgetTester tester) {
  final painter =
      tester
              .widget<CustomPaint>(find.byKey(FlareRedPacketCard.glyphKey))
              .painter
          as dynamic;
  return (
    body: painter.body as Color,
    bodyDeep: painter.bodyDeep as Color,
    seal: painter.seal as Color,
  );
}

/// The card face's gradient stops, top-left to bottom-right.
List<Color> faceOf(WidgetTester tester) {
  final box = tester
      .widgetList<Container>(
        find.descendant(
          of: find.byType(FlareRedPacketCard),
          matching: find.byType(Container),
        ),
      )
      .firstWhere(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration! as BoxDecoration).gradient is LinearGradient,
      );
  return ((box.decoration! as BoxDecoration).gradient! as LinearGradient)
      .colors;
}

void main() {
  final table =
      jsonDecode(File('../../spec/red-packet-vectors.json').readAsStringSync())
          as Map<String, dynamic>;
  final cases = (table['card'] as List).cast<Map<String, dynamic>>();
  final faded = table['faded'] as Map<String, dynamic>;
  final mix = (faded['mix'] as num).toDouble();

  Color hex(String value) =>
      Color(int.parse('FF${value.substring(1)}', radix: 16));
  // The table's arithmetic: the target takes `mix` of each channel, in sRGB.
  Color fadedToward(Color color, Color target) =>
      Color.lerp(color, target, mix)!;
  int channel(double v) => (v * 255).round();
  void expectClose(Color actual, Color expected) {
    for (final pair in [
      (actual.r, expected.r),
      (actual.g, expected.g),
      (actual.b, expected.b),
    ]) {
      expect((channel(pair.$1) - channel(pair.$2)).abs(), lessThanOrEqualTo(1));
    }
  }

  double luminance(Color c) {
    double lin(double v) => v <= 0.04045
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
  }

  double contrast(Color a, Color b) {
    final la = luminance(a), lb = luminance(b);
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  Color tokenColor(FlareColors colors, String token) => switch (token) {
    'colors.redPacket.start' => colors.redPacketStart,
    'colors.redPacket.middle' => colors.redPacketMiddle,
    'colors.redPacket.end' => colors.redPacketEnd,
    'colors.redPacket.gold' => colors.redPacketGold,
    'colors.redPacket.goldDeep' => colors.redPacketGoldDeep,
    final other => throw StateError('unknown token $other'),
  };

  FlareRedPacketState stateOf(String name) =>
      FlareRedPacketState.values.byName(name);

  String expected(Map<String, dynamic> v, FlareStrings s) =>
      switch (v['status'] as String) {
        'busy' => s.packetBusy,
        'statusLabel' => v['statusLabel'] as String,
        'claimedAmount' => s.packetClaimed(v['amount'] as String),
        'claimed' => s.packetStateClaimed,
        'finished' => s.packetFinished,
        'expired' => s.packetStateExpired,
        'unavailable' => s.packetUnavailable,
        'tapToOpen' => s.packetTapToClaim,
        final other => throw StateError('unknown status $other'),
      };

  test('the table still carries its cases', () {
    expect(cases.length, greaterThanOrEqualTo(8));
  });

  for (final v in cases) {
    final id = v['id'] as String;
    testWidgets('card vector $id', (tester) async {
      var taps = 0;
      final card = FlareRedPacketCard(
        blessing: 'Hello',
        state: stateOf(v['state'] as String),
        amount: v['amount'] as String?,
        busy: v['busy'] as bool? ?? false,
        disabled: v['disabled'] as bool? ?? false,
        statusLabel: v['statusLabel'] as String?,
        onOpen: () => taps++,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: FlareStringsScope(
            strings: flareStringsEnglish,
            child: Scaffold(body: Center(child: card)),
          ),
        ),
      );
      expect(find.text(expected(v, flareStringsEnglish)), findsOneWidget);
      final colors = FlareColors.light;
      expect(
        faceOf(tester).first,
        v['dimmed'] as bool
            ? fadedToward(colors.redPacketStart, colors.redPacketFadedMixTarget)
            : colors.redPacketStart,
      );
      await tester.tap(find.byType(FlareRedPacketCard));
      expect(taps, v['tappable'] as bool ? 1 : 0);
    });
  }

  testWidgets('kind label shares the brand line without displacing the brand', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: FlareRedPacketCard(
              blessing: '恭喜发财',
              kindLabel: '拼手气红包',
              state: FlareRedPacketState.expired,
            ),
          ),
        ),
      ),
    );
    expect(find.text('拼手气红包'), findsOneWidget);
    expect(find.text('Flare 红包'), findsOneWidget);
    expect(find.text('已过期'), findsOneWidget);
    final kind = tester.getRect(find.text('拼手气红包'));
    final brand = tester.getRect(find.text('Flare 红包'));
    expect(kind.right, lessThanOrEqualTo(brand.left));
    expect((kind.center.dy - brand.center.dy).abs(), lessThan(2));
  });

  group('faded face follows spec/red-packet-vectors.json → faded', () {
    final modes = [
      (
        'light',
        Brightness.light,
        FlareColors.light,
        faded['target'] as String,
        faded['ink'] as String,
        (faded['stops'] as List).cast<Map<String, dynamic>>(),
      ),
      (
        'dark',
        Brightness.dark,
        FlareColors.dark,
        (faded['dark'] as Map<String, dynamic>)['target'] as String,
        (faded['dark'] as Map<String, dynamic>)['ink'] as String,
        ((faded['dark'] as Map<String, dynamic>)['stops'] as List)
            .cast<Map<String, dynamic>>(),
      ),
    ];
    final minimum = (faded['minTextContrast'] as num).toDouble();
    final textStops = (faded['textStops'] as List).cast<String>();

    test('the mix is the shared token', () {
      expect(FlareSizes.componentRedPacketFadedMix, mix);
    });

    for (final (name, brightness, colors, target, ink, stops) in modes) {
      test('$name: target and ink are the tokens', () {
        expect(colors.redPacketFadedMixTarget, hex(target));
        expect(colors.redPacketFadedInk, hex(ink));
      });

      for (final stop in stops) {
        test('$name: ${stop['token']} keeps its hue', () {
          final base = tokenColor(colors, stop['token'] as String);
          expect(base, hex(stop['base'] as String));
          expectClose(
            fadedToward(base, colors.redPacketFadedMixTarget),
            hex(stop['faded'] as String),
          );
        });
      }

      test('$name: the faded ink keeps its contrast where the words sit', () {
        for (final token in textStops) {
          final stop = stops.firstWhere((s) => s['token'] == token);
          expect(
            contrast(hex(stop['faded'] as String), colors.redPacketFadedInk),
            greaterThanOrEqualTo(minimum),
          );
        }
      });

      testWidgets(
        '$name: a spent card draws the mixed face, ink words and a quieter seal',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: const Scaffold(
                body: Center(
                  child: FlareRedPacketCard(
                    blessing: '恭喜发财',
                    state: FlareRedPacketState.claimed,
                    amount: '0.88 元',
                  ),
                ),
              ),
            ),
          );
          final face = faceOf(tester);
          for (final (index, token) in [
            'colors.redPacket.start',
            'colors.redPacket.middle',
            'colors.redPacket.end',
          ].indexed) {
            final stop = stops.firstWhere((s) => s['token'] == token);
            expectClose(face[index], hex(stop['faded'] as String));
          }
          expect(
            tester.widget<Text>(find.text('恭喜发财')).style!.color,
            colors.redPacketFadedInk,
          );
          expect(
            tester.widget<Text>(find.text('已领取 · 0.88 元')).style!.color,
            colors.redPacketFadedInk,
          );
          // The envelope glyph is painted from the same mixed colours.
          final glyph = glyphOf(tester);
          final target = colors.redPacketFadedMixTarget;
          expectClose(glyph.body, fadedToward(colors.redPacketGold, target));
          expectClose(
            glyph.bodyDeep,
            fadedToward(colors.redPacketGoldDeep, target),
          );
          expectClose(glyph.seal, fadedToward(colors.redPacketEnd, target));
          expect(find.byType(ColorFiltered), findsNothing);
          expect(find.byType(Opacity), findsNothing);
        },
      );
    }

    test('light mode needs the ink: white would not be legible', () {
      for (final token in textStops) {
        final stop = (faded['stops'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((s) => s['token'] == token);
        expect(
          contrast(hex(stop['faded'] as String), Colors.white),
          lessThan(minimum),
        );
      }
    });

    for (final flags in [
      (busy: true, disabled: false),
      (busy: false, disabled: true),
    ]) {
      testWidgets(
        'busy ${flags.busy} / disabled ${flags.disabled} keeps the unopened face',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: FlareRedPacketCard(
                    blessing: '恭喜发财',
                    busy: flags.busy,
                    disabled: flags.disabled,
                    onOpen: () {},
                  ),
                ),
              ),
            ),
          );
          final colors = FlareColors.light;
          expect(faceOf(tester), [
            colors.redPacketStart,
            colors.redPacketMiddle,
            colors.redPacketEnd,
          ]);
          expect(
            tester.widget<Text>(find.text('恭喜发财')).style!.color,
            Colors.white,
          );
          expect(find.text(flags.busy ? '处理中…' : '暂不可用'), findsOneWidget);
          final glyph = glyphOf(tester);
          expect(glyph.body, colors.redPacketGold);
          expect(glyph.bodyDeep, colors.redPacketGoldDeep);
          expect(glyph.seal, colors.redPacketEnd);
          expect(find.byType(Opacity), findsNothing);
          expect(find.byType(ColorFiltered), findsNothing);
        },
      );
    }
  });

  testWidgets('the glyph is the shared small envelope, taller than wide', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: FlareRedPacketCard(blessing: '恭喜发财')),
        ),
      ),
    );
    final size = tester.getSize(find.byKey(FlareRedPacketCard.glyphKey));
    expect(size, const Size(30, 39));
    expect(find.byType(Icon), findsNothing);
  });
}
