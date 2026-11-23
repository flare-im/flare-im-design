import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {Size size = const Size(390, 844)}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(size: size),
    child: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  testWidgets('draws the arch, the total, kind and blessing and submits', (
    tester,
  ) async {
    var submits = 0;
    await tester.pumpWidget(
      host(
        FlareRedPacketReview(
          amount: '¥26.64',
          kindLabel: '拼手气红包 · 3 个',
          blessing: '恭喜发财，大吉大利',
          onSubmit: () => submits++,
        ),
      ),
    );
    expect(
      tester
          .widget<FlareRedPacketArch>(find.byType(FlareRedPacketArch))
          .compact,
      isTrue,
    );
    final amount = tester.widget<Text>(
      find.byKey(FlareRedPacketReview.amountKey),
    );
    expect(amount.data, '¥26.64');
    expect(amount.style!.fontSize, FlareSizes.componentRedPacketAmountFontSize);
    expect(find.text('拼手气红包 · 3 个'), findsOneWidget);
    expect(find.text('恭喜发财，大吉大利'), findsOneWidget);
    final key = tester.widget<FlareButton>(
      find.byKey(FlareRedPacketReview.submitKey),
    );
    expect(key.size, FlareControlSize.lg);
    expect(key.block, isTrue);
    expect(key.label, '发红包');
    expect(
      FlareColors.of(
        tester.element(find.byKey(FlareRedPacketReview.submitKey)),
      ).primary,
      FlareColors.light.redPacketEnd,
    );
    await tester.tap(find.byKey(FlareRedPacketReview.submitKey));
    expect(submits, 1);
  });

  testWidgets('the total is 36 in a PC window', (tester) async {
    await tester.pumpWidget(
      host(
        const FlareRedPacketReview(amount: '¥1.00'),
        size: const Size(1280, 800),
      ),
    );
    expect(
      tester
          .widget<Text>(find.byKey(FlareRedPacketReview.amountKey))
          .style!
          .fontSize,
      36,
    );
  });

  testWidgets('busy spins and locks; an error reads in a danger banner', (
    tester,
  ) async {
    var submits = 0;
    await tester.pumpWidget(
      host(
        FlareRedPacketReview(
          amount: '¥1.00',
          busy: true,
          error: '余额不足',
          onSubmit: () => submits++,
        ),
      ),
    );
    final key = tester.widget<FlareButton>(
      find.byKey(FlareRedPacketReview.submitKey),
    );
    expect(key.loading, isTrue);
    await tester.tap(
      find.byKey(FlareRedPacketReview.submitKey),
      warnIfMissed: false,
    );
    expect(submits, 0);
    final banner = tester.widget<FlareStatusBanner>(
      find.byType(FlareStatusBanner),
    );
    expect(banner.tone, FlareStatusTone.danger);
    expect(banner.text, '余额不足');
  });

  testWidgets('busy looks like the composer: spinning, not dimmed', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(FlareRedPacketReview(amount: '¥1.00', busy: true, onSubmit: () {})),
    );
    final key = tester.widget<FlareButton>(
      find.byKey(FlareRedPacketReview.submitKey),
    );
    expect(key.loading, isTrue);
    expect(key.onPressed, isNotNull);
    expect(key.disabled, isFalse);
  });
}
