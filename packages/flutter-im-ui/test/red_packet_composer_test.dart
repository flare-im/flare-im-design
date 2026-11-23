import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    expect(
      tester.widget<TextField>(field(2)).decoration!.hintText,
      '恭喜发财，大吉大利',
    );
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

  testWidgets('a form error is a banner; the kit button submits a total', (
    tester,
  ) async {
    var submits = 0;
    await tester.pumpWidget(
      host(_Harness(error: '服务暂不可用', onSubmit: () => submits++)),
    );
    expect(
      tester.widget<FlareStatusBanner>(find.byType(FlareStatusBanner)).text,
      '服务暂不可用',
    );
    // A zero total cannot be sent.
    await tester.tap(find.text('塞钱进红包'), warnIfMissed: false);
    expect(submits, 0);
    await tester.enterText(field(0), '8.88');
    await tester.pump();
    await tester.tap(find.text('塞钱进红包'));
    expect(submits, 1);
  });

  testWidgets('a field error keeps the key off; the greeting holds 24', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const FlareRedPacketComposer(
          kinds: FlareRedPacketKind.values,
          total: '¥300.00',
          error: '单个红包金额不能超过 200 元',
          errorField: FlareRedPacketField.amount,
        ),
      ),
    );
    expect(
      tester.widget<FlareButton>(find.byType(FlareButton)).disabled,
      isTrue,
    );
    await tester.enterText(field(2), '一' * 30);
    await tester.pump();
    expect(tester.widget<TextField>(field(2)).controller!.text.length, 24);
  });

  testWidgets('the same field reported again with a new error refocuses', (
    tester,
  ) async {
    Widget composer(String error) => host(
      FlareRedPacketComposer(
        kinds: FlareRedPacketKind.values,
        total: '¥1.00',
        error: error,
        errorField: FlareRedPacketField.count,
        focusField: FlareRedPacketField.count,
      ),
    );
    await tester.pumpWidget(composer('红包个数不能超过 100 个'));
    await tester.pump();
    final count = tester.widget<TextField>(field(1)).focusNode!;
    expect(count.hasFocus, isTrue);
    tester.widget<TextField>(field(0)).focusNode!.requestFocus();
    await tester.pump();
    expect(count.hasFocus, isFalse);
    await tester.pumpWidget(composer('红包个数不能超过 100 个。'));
    await tester.pump();
    expect(count.hasFocus, isTrue);
  });

  testWidgets('busy turns the kind switch off for every input', (tester) async {
    await tester.pumpWidget(host(const _Harness(busy: true)));
    expect(
      tester
          .widget<FlareSegmentedControl>(find.byType(FlareSegmentedControl))
          .onSelect,
      isNull,
    );
    expect(
      tester
          .widget<ExcludeFocus>(
            find
                .ancestor(
                  of: find.byType(FlareSegmentedControl),
                  matching: find.byType(ExcludeFocus),
                )
                .first,
          )
          .excluding,
      isTrue,
    );
  });

  testWidgets('the count reads 个; the form stays 420 wide', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(const _Harness()));
    expect(find.text('个'), findsOneWidget);
    expect(
      tester.getSize(find.byType(FlareButton)).width,
      FlareSizes.detailPaneMaxWidth - 2 * FlareSizes.spacingLg,
    );
  });

  testWidgets('no offered kind cannot edit or submit a packet', (tester) async {
    var submits = 0;
    await tester.pumpWidget(
      host(_Harness(kinds: const [], onSubmit: () => submits++)),
    );
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      expect(field.enabled, isFalse);
    }
    expect(
      tester.widget<FlareButton>(find.byType(FlareButton)).disabled,
      isTrue,
    );
    await tester.tap(find.byType(FlareButton), warnIfMissed: false);
    expect(submits, 0);
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

  testWidgets(
    'the submit button uses the standard primary variant with packet red',
    (tester) async {
      await tester.pumpWidget(host(const _Harness()));
      final colors = FlareColors.of(tester.element(find.text('塞钱进红包')));
      expect(colors.primary, colors.redPacketEnd);
      expect(colors.primaryHover, colors.redPacketEndHover);
      expect(colors.primaryActive, colors.redPacketEndActive);
      final button = tester.widget<FlareButton>(find.byType(FlareButton));
      expect(button.variant, FlareButtonVariant.primary);
      expect(button.size, FlareControlSize.lg);
      expect(find.text('未领取的红包将于 24 小时后退回'), findsOneWidget);
    },
  );

  testWidgets('the compact arch spans the top, outside any card', (
    tester,
  ) async {
    await tester.pumpWidget(host(const _Harness()));
    final arch = find.byType(FlareRedPacketArch);
    expect(tester.widget<FlareRedPacketArch>(arch).compact, isTrue);
    expect(tester.getSize(arch).height, 32);
    expect(
      tester.getSize(arch).width,
      tester.getSize(find.byType(FlareRedPacketComposer)).width,
    );
  });

  testWidgets('errorField tints its row, writes the reason under it and '
      'focusField moves focus there', (tester) async {
    Widget composer({FlareRedPacketField? field}) => host(
      FlareRedPacketComposer(
        kinds: FlareRedPacketKind.values,
        total: '¥0.00',
        error: '红包个数不能超过 100 个',
        errorField: FlareRedPacketField.count,
        focusField: field,
      ),
    );
    await tester.pumpWidget(composer());
    final caption = find.byKey(FlareRedPacketComposer.errorCaptionKey);
    expect(caption, findsOneWidget);
    expect(find.text('红包个数不能超过 100 个'), findsOneWidget);
    final row = tester.widget<ColoredBox>(
      find.ancestor(of: caption, matching: find.byType(ColoredBox)).first,
    );
    expect(row.color, FlareColors.light.messageFailedBackground);
    // The tinted row holds the count field, not the amount.
    expect(
      find.descendant(
        of: find.ancestor(of: caption, matching: find.byType(ColoredBox)).first,
        matching: find.text('红包个数'),
      ),
      findsOneWidget,
    );
    await tester.pumpWidget(composer(field: FlareRedPacketField.count));
    await tester.pump();
    expect(tester.widget<TextField>(field(1)).focusNode!.hasFocus, isTrue);
  });

  testWidgets('the amount is 18/600 after the currency sign, 拼 first', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const FlareRedPacketComposer(
          kinds: FlareRedPacketKind.values,
          total: '¥0.00',
          currencySymbol: '¥',
        ),
      ),
    );
    final amount = tester.widget<TextField>(field(0));
    expect(amount.style!.fontSize, FlareSizes.fontSize3xl);
    expect(amount.style!.fontWeight, FontWeight.w600);
    expect(
      amount.keyboardType,
      const TextInputType.numberWithOptions(decimal: true),
    );
    expect(
      find.descendant(
        of: find.ancestor(of: field(0), matching: find.byType(Row)).first,
        matching: find.text('¥'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(
            find
                .ancestor(
                  of: find.text('总金额'),
                  matching: find.byType(ConstrainedBox),
                )
                .first,
          )
          .height,
      greaterThanOrEqualTo(FlareSizes.componentRedPacketFormRowHeight),
    );
    final badge = find.widgetWithText(FlareTag, '拼');
    expect(badge, findsOneWidget);
    expect(
      tester.getTopLeft(badge).dx,
      lessThan(tester.getTopLeft(find.text('总金额')).dx),
    );
  });

  testWidgets('currencySymbol sets the sign; absent or empty draws none', (
    tester,
  ) async {
    Widget composer(String? symbol) => host(
      FlareRedPacketComposer(
        kinds: FlareRedPacketKind.values,
        total: '¥0.00',
        currencySymbol: symbol,
      ),
    );
    await tester.pumpWidget(composer(r'HK$'));
    expect(find.text(r'HK$'), findsOneWidget);
    await tester.pumpWidget(composer(''));
    expect(find.text(r'HK$'), findsNothing);
    expect(find.text('¥'), findsNothing);
    await tester.pumpWidget(composer(null));
    expect(find.text('¥'), findsNothing);
  });

  testWidgets('a group reads its member count under the fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const FlareRedPacketComposer(
          kinds: FlareRedPacketKind.values,
          total: '¥0.00',
          memberCount: 12,
        ),
      ),
    );
    expect(find.text('本群共 12 人'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('本群共 12 人')).dy,
      greaterThan(tester.getTopLeft(find.text('红包个数')).dy),
    );
    await tester.pumpWidget(
      host(
        const FlareRedPacketComposer(
          kinds: [FlareRedPacketKind.normal],
          total: '¥0.00',
        ),
      ),
    );
    expect(find.textContaining('本群共'), findsNothing);
    expect(find.byType(FlareTag), findsNothing);
  });

  testWidgets('a form error is a danger banner above the card', (tester) async {
    await tester.pumpWidget(
      host(
        const FlareRedPacketComposer(
          kinds: FlareRedPacketKind.values,
          total: '¥0.00',
          error: '服务暂不可用',
          errorField: FlareRedPacketField.form,
        ),
      ),
    );
    final banner = tester.widget<FlareStatusBanner>(
      find.byType(FlareStatusBanner),
    );
    expect(banner.tone, FlareStatusTone.danger);
    expect(banner.text, '服务暂不可用');
    expect(find.byKey(FlareRedPacketComposer.errorCaptionKey), findsNothing);
  });

  testWidgets('an error for a row not on screen goes to the banner', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const FlareRedPacketComposer(
          kinds: [FlareRedPacketKind.normal],
          total: '¥0.00',
          error: '请选择发给谁',
          errorField: FlareRedPacketField.recipient,
        ),
      ),
    );
    expect(
      tester.widget<FlareStatusBanner>(find.byType(FlareStatusBanner)).text,
      '请选择发给谁',
    );
    expect(find.byKey(FlareRedPacketComposer.errorCaptionKey), findsNothing);
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

  testWidgets('§4.2 the greeting row is as tall as the amount row', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const FlareRedPacketComposer(
          kinds: FlareRedPacketKind.values,
          total: '¥0.00',
        ),
      ),
    );
    final greeting = find.ancestor(
      of: find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.inputFormatters?.length == 1 &&
            w.inputFormatters!.first is LengthLimitingTextInputFormatter,
      ),
      matching: find.byType(ConstrainedBox),
    );
    expect(
      tester.getSize(greeting.first).height,
      greaterThanOrEqualTo(FlareSizes.componentRedPacketFormRowHeight),
    );
  });
}
