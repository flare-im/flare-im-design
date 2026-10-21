import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {FlareStrings strings = const FlareStrings()}) =>
    MaterialApp(
      home: FlareStringsScope(
        strings: strings,
        child: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  final events = <String>[];
  setUp(events.clear);

  FlareRedPacketPayConfirm pay({
    bool insufficient = false,
    bool busy = false,
  }) => FlareRedPacketPayConfirm(
    amount: '¥5.00',
    methodLabel: '钱包（余额 ¥12.00）',
    insufficient: insufficient,
    busy: busy,
    onConfirm: () => events.add('confirm'),
    onCancel: () => events.add('cancel'),
  );

  testWidgets('shows the amount large, the method row, confirm and cancel', (
    tester,
  ) async {
    await tester.pumpWidget(host(pay()));
    final amount = tester.widget<Text>(find.text('¥5.00'));
    expect(amount.style!.fontSize, FlareSizes.componentRedPacketAmountFontSize);
    expect(find.text('支付方式'), findsOneWidget);
    expect(find.text('钱包（余额 ¥12.00）'), findsOneWidget);
    expect(find.text('余额不足'), findsNothing);
    await tester.tap(find.text('确认支付'));
    await tester.tap(find.text('取消'));
    expect(events, ['confirm', 'cancel']);
  });

  testWidgets('an insufficient balance disables confirm and says why', (
    tester,
  ) async {
    await tester.pumpWidget(host(pay(insufficient: true)));
    expect(find.text('余额不足'), findsOneWidget);
    await tester.tap(find.text('确认支付'), warnIfMissed: false);
    expect(events, isEmpty);
    await tester.tap(find.text('取消'));
    expect(events, ['cancel']);
  });

  testWidgets('busy locks both buttons and shows progress on confirm', (
    tester,
  ) async {
    await tester.pumpWidget(host(pay(busy: true)));
    final buttons = tester.widgetList<FlareButton>(find.byType(FlareButton));
    expect(buttons.first.loading, isTrue);
    expect(buttons.last.disabled, isTrue);
    for (final button in find.byType(FlareButton).evaluate().toList()) {
      await tester.tap(find.byWidget(button.widget), warnIfMissed: false);
    }
    expect(events, isEmpty);
  });

  testWidgets('show() presents it on the kit sheet under the title', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    final busy = ValueNotifier(false);
    addTearDown(busy.dispose);
    FlareRedPacketPayConfirm.show<void>(
      context,
      busy: busy,
      builder: (_) => pay(),
    );
    await tester.pumpAndSettle();
    expect(find.text('确认付款'), findsOneWidget);
    expect(find.text('¥5.00'), findsOneWidget);
    expect(find.byType(FlareBottomSheet), findsOneWidget);
  });

  testWidgets('localizes its copy', (tester) async {
    await tester.pumpWidget(
      host(pay(insufficient: true), strings: flareStringsEnglish),
    );
    expect(find.text('Pay with'), findsOneWidget);
    expect(find.text('Pay'), findsOneWidget);
    expect(find.text('Insufficient balance'), findsOneWidget);
  });

  testWidgets('lays out at 320 with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 800),
          textScaler: TextScaler.linear(1.8),
        ),
        child: host(pay(insufficient: true)),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
