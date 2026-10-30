import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {FlareStrings strings = const FlareStrings()}) =>
    MaterialApp(
      home: FlareStringsScope(
        strings: strings,
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

/// A host that owns the values, the way an app wires the composer.
class _Harness extends StatefulWidget {
  const _Harness({
    this.kinds = FlareRedPacketKind.values,
    this.kind = FlareRedPacketKind.lucky,
    this.busy = false,
    this.locked = false,
    this.error,
    this.onSubmit,
    this.exponent = 2,
  });

  final List<FlareRedPacketKind> kinds;
  final int exponent;
  final FlareRedPacketKind kind;
  final bool busy;
  final bool locked;
  final String? error;
  final VoidCallback? onSubmit;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late FlareRedPacketKind kind = widget.kind;
  String amount = '';
  int count = 0;
  String greeting = '';

  void reset() => setState(() => amount = '');

  @override
  Widget build(BuildContext context) => FlareRedPacketComposer(
    kinds: widget.kinds,
    kind: kind,
    amount: amount,
    currencyExponent: widget.exponent,
    count: count,
    greeting: greeting,
    total: '¥$amount',
    error: widget.error,
    busy: widget.busy,
    locked: widget.locked,
    recipient: const Text('选择成员'),
    onKindChange: (v) => setState(() => kind = v),
    onAmountChange: (v) => setState(() => amount = v),
    onCountChange: (v) => setState(() => count = v),
    onGreetingChange: (v) => setState(() => greeting = v),
    onSubmit: widget.onSubmit,
  );
}

void main() {
  final table =
      jsonDecode(File('../../spec/red-packet-vectors.json').readAsStringSync())
          as Map<String, dynamic>;

  group('input filters follow spec/red-packet-vectors.json', () {
    for (final v
        in (table['amountInput'] as List).cast<Map<String, dynamic>>()) {
      test('amount ${v['id']}', () {
        expect(flareRedPacketAmount(v['input'] as String), v['output']);
      });
    }
    for (final v
        in (table['countInput'] as List).cast<Map<String, dynamic>>()) {
      test('count ${v['id']}', () {
        expect(flareRedPacketCount(v['input'] as String), v['output']);
      });
    }
    for (final v
        in (table['amountInputExponent'] as List)
            .cast<Map<String, dynamic>>()) {
      test('amount ${v['id']}', () {
        expect(
          flareRedPacketAmount(v['input'] as String, v['exponent'] as int),
          v['output'],
        );
      });
    }
    for (final v
        in (table['amountMinor'] as List).cast<Map<String, dynamic>>()) {
      test('minor ${v['id']}', () {
        expect(
          flareRedPacketAmountMinor(v['input'] as String, v['exponent'] as int),
          v['minor'],
        );
      });
    }
    test('placeholders by exponent', () {
      final cases = ((table['amountPlaceholder'] as Map)['cases'] as List)
          .cast<Map<String, dynamic>>();
      expect(cases, isNotEmpty);
      for (final v in cases) {
        expect(
          flareRedPacketAmountPlaceholder(v['exponent'] as int),
          v['placeholder'],
        );
      }
    });
    test('the exponent is rounded and held to 0..12', () {
      expect(flareRedPacketExponent(-1), 0);
      expect(flareRedPacketExponent(2.4), 2);
      expect(flareRedPacketExponent(9), 9);
      expect(flareRedPacketExponent(99), 12);
      expect(flareRedPacketAmount('1.2345678', 9), '1.2345678');
      expect(flareRedPacketAmount('1.1234567890123', 99), '1.123456789012');
    });
  });

  final state = find.byType(_Harness);
  _HarnessState harness(WidgetTester tester) => tester.state(state);
  Finder field(int index) => find.byType(TextField).at(index);

  testWidgets('relabels the amount per kind; count or recipient follows', (
    tester,
  ) async {
    await tester.pumpWidget(host(const _Harness()));
    expect(find.text('总金额'), findsOneWidget);
    expect(find.text('红包个数'), findsOneWidget);
    expect(find.text('选择成员'), findsNothing);

    await tester.tap(find.text('普通红包'));
    await tester.pump();
    expect(harness(tester).kind, FlareRedPacketKind.normal);
    expect(find.text('单个金额'), findsOneWidget);

    await tester.tap(find.text('专属红包'));
    await tester.pump();
    expect(find.text('金额'), findsOneWidget);
    expect(find.text('红包个数'), findsNothing);
    expect(find.text('发给谁'), findsOneWidget);
    expect(find.text('选择成员'), findsOneWidget);
  });

  testWidgets('a 1:1 chat hides the switch and the count and asks for 金额', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const _Harness(
          kinds: [FlareRedPacketKind.normal],
          kind: FlareRedPacketKind.lucky,
        ),
      ),
    );
    expect(find.byType(FlareSegmentedControl), findsNothing);
    expect(find.text('金额'), findsOneWidget);
    expect(find.text('单个金额'), findsNothing);
    expect(find.text('红包个数'), findsNothing);
  });

  for (final v in (table['composer'] as List).cast<Map<String, dynamic>>()) {
    testWidgets('composer vector ${v['id']}', (tester) async {
      final kinds = (v['kinds'] as List)
          .map((k) => FlareRedPacketKind.values.byName(k as String))
          .toList();
      await tester.pumpWidget(
        host(
          _Harness(
            kinds: kinds,
            kind: FlareRedPacketKind.values.byName(v['kind'] as String),
          ),
          strings: flareStringsEnglish,
        ),
      );
      final label = switch (v['amountLabel'] as String) {
        'total' => 'Total',
        'each' => 'Amount each',
        'amount' => 'Amount',
        final other => throw StateError('unknown label $other'),
      };
      expect(find.text(label), findsOneWidget);
      expect(
        find.text('Quantity'),
        v['showsCount'] as bool ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Send to'),
        v['showsRecipient'] as bool ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(FlareSegmentedControl),
        kinds.length > 1 ? findsOneWidget : findsNothing,
      );
    });
  }

  testWidgets('filters the amount and count as they are typed', (tester) async {
    await tester.pumpWidget(host(const _Harness()));
    await tester.enterText(field(0), '12.345a');
    await tester.pump();
    expect(harness(tester).amount, '12.34');
    expect(tester.widget<TextField>(field(0)).controller!.text, '12.34');
    expect(find.text('¥12.34'), findsOneWidget);
    await tester.enterText(field(1), '1x0');
    await tester.pump();
    expect(harness(tester).count, 10);
    expect(tester.widget<TextField>(field(1)).controller!.text, '10');
    await tester.enterText(field(2), '新年快乐');
    await tester.pump();
    expect(harness(tester).greeting, '新年快乐');
  });

  testWidgets('placeholders: 0.00, quantity hint, the default greeting', (
    tester,
  ) async {
    await tester.pumpWidget(host(const _Harness()));
    expect(find.text('0.00'), findsOneWidget);
    expect(find.text('填写个数'), findsOneWidget);
    expect(find.text('恭喜发财，大吉大利'), findsOneWidget);
  });

  testWidgets('currencyExponent sets the decimals, placeholder and keyboard', (
    tester,
  ) async {
    await tester.pumpWidget(host(const _Harness(exponent: 0)));
    expect(find.text('0'), findsOneWidget);
    expect(
      tester.widget<TextField>(field(0)).keyboardType,
      TextInputType.number,
    );
    await tester.enterText(field(0), '8.8');
    await tester.pump();
    expect(harness(tester).amount, '88');

    await tester.pumpWidget(host(const _Harness(exponent: 3)));
    await tester.pump();
    harness(tester).reset();
    await tester.pump();
    expect(find.text('0.000'), findsOneWidget);
    expect(
      tester.widget<TextField>(field(0)).keyboardType,
      const TextInputType.numberWithOptions(decimal: true),
    );
    await tester.enterText(field(0), '1.2345');
    await tester.pump();
    expect(harness(tester).amount, '1.234');
    expect(flareRedPacketAmountMinor(harness(tester).amount, 3), '1234');
  });

  testWidgets('a host value replaces the field text', (tester) async {
    await tester.pumpWidget(host(const _Harness()));
    await tester.enterText(field(0), '8.88');
    await tester.pump();
    harness(tester).reset();
    await tester.pump();
    expect(tester.widget<TextField>(field(0)).controller!.text, '');
  });

  testWidgets('shows the host error and submits through the kit button', (
    tester,
  ) async {
    var submits = 0;
    await tester.pumpWidget(
      host(_Harness(error: '单个红包金额不可超过 200 元', onSubmit: () => submits++)),
    );
    expect(find.text('单个红包金额不可超过 200 元'), findsOneWidget);
    await tester.tap(find.text('塞钱进红包'));
    expect(submits, 1);
  });

  testWidgets('busy locks the fields, the switch and the button', (
    tester,
  ) async {
    var submits = 0;
    await tester.pumpWidget(
      host(_Harness(busy: true, onSubmit: () => submits++)),
    );
    for (var i = 0; i < 3; i++) {
      expect(tester.widget<TextField>(field(i)).enabled, isFalse);
    }
    await tester.tap(find.text('普通红包'), warnIfMissed: false);
    await tester.pump();
    expect(harness(tester).kind, FlareRedPacketKind.lucky);
    final button = tester.widget<FlareButton>(find.byType(FlareButton));
    expect(button.loading, isTrue);
    await tester.tap(find.byType(FlareButton), warnIfMissed: false);
    expect(submits, 0);
  });

  testWidgets('the submit button is drawn in the packet red', (tester) async {
    await tester.pumpWidget(host(const _Harness()));
    final colors = FlareColors.of(tester.element(find.text('塞钱进红包')));
    expect(colors.primary, colors.redPacketEnd);
  });

  testWidgets('localizes its labels', (tester) async {
    await tester.pumpWidget(
      host(const _Harness(), strings: flareStringsEnglish),
    );
    expect(find.text('Lucky packet'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Put money in'), findsOneWidget);
  });

  for (final width in [320.0, 1024.0]) {
    testWidgets('lays out at $width with large text', (tester) async {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: Size(width, 1200),
            textScaler: const TextScaler.linear(1.8),
          ),
          child: host(const _Harness(kind: FlareRedPacketKind.exclusive)),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the selected kind takes the red packet accent', (tester) async {
    await tester.pumpWidget(host(const _Harness()));
    final control = tester.widget<FlareSegmentedControl>(
      find.byType(FlareSegmentedControl),
    );
    expect(control.accent, FlareColors.light.redPacketAccent);
    final selected = tester.widget<Text>(find.text('拼手气红包'));
    expect(selected.style!.color, FlareColors.light.redPacketAccent);
    expect(
      tester.widget<Text>(find.text('普通红包')).style!.color,
      FlareColors.light.textSecondary,
    );
  });

  testWidgets(
    'locked: read-only fields and kind, an inert button, no progress',
    (tester) async {
      var submits = 0;
      await tester.pumpWidget(
        host(_Harness(locked: true, onSubmit: () => submits++)),
      );
      for (var i = 0; i < 3; i++) {
        final input = tester.widget<TextField>(field(i));
        expect(input.readOnly, isTrue);
        expect(input.enabled, isTrue);
      }
      await tester.tap(find.text('普通红包'), warnIfMissed: false);
      await tester.pump();
      expect(harness(tester).kind, FlareRedPacketKind.lucky);
      final button = tester.widget<FlareButton>(find.byType(FlareButton));
      expect(button.loading, isFalse);
      expect(button.disabled, isTrue);
      await tester.tap(find.byType(FlareButton), warnIfMissed: false);
      expect(submits, 0);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}
