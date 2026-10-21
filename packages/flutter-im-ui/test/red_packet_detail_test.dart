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

const claims = [
  FlareRedPacketClaim(id: 'u1', name: '阿花', time: '10:02', amount: '0.62 元'),
  FlareRedPacketClaim(
    id: 'u2',
    name: '大壮',
    time: '10:03',
    amount: '0.88 元',
    best: true,
  ),
];

FlareRedPacketDetail detail({
  String? kindLabel,
  String? amount,
  String? amountNote,
  List<FlareRedPacketClaim> claims = const [],
  String? note,
  String senderName = '小明',
}) => FlareRedPacketDetail(
  senderName: senderName,
  blessing: '恭喜发财，大吉大利',
  kindLabel: kindLabel,
  amount: amount,
  amountNote: amountNote,
  summary: '已领取 2/3 个，共 1.50/3.00 元',
  claims: claims,
  note: note,
);

void main() {
  testWidgets(
    'leads with the sender, the kind badge, the blessing and the amount',
    (tester) async {
      await tester.pumpWidget(
        host(detail(kindLabel: '拼', amount: '0.88 元', amountNote: '已存入钱包')),
      );
      expect(find.text('小明的红包'), findsOneWidget);
      expect(find.text('拼'), findsOneWidget);
      expect(find.text('恭喜发财，大吉大利'), findsOneWidget);
      final amount = tester.widget<Text>(find.text('0.88 元'));
      expect(
        amount.style!.fontSize,
        FlareSizes.componentRedPacketAmountFontSize,
      );
      expect(find.text('已存入钱包'), findsOneWidget);
      expect(find.text('已领取 2/3 个，共 1.50/3.00 元'), findsOneWidget);
    },
  );

  testWidgets('omits the amount block when the viewer got nothing', (
    tester,
  ) async {
    await tester.pumpWidget(host(detail()));
    expect(find.text('已存入钱包'), findsNothing);
    expect(find.text('拼'), findsNothing);
  });

  testWidgets(
    'lists claims with name, time and amount; only the best is marked',
    (tester) async {
      await tester.pumpWidget(host(detail(claims: claims)));
      for (final text in ['阿花', '10:02', '0.62 元', '大壮', '10:03', '0.88 元']) {
        expect(find.text(text), findsOneWidget);
      }
      expect(find.text('手气最佳'), findsOneWidget);
      final best = tester.getRect(find.text('手气最佳'));
      final row = tester.getRect(find.text('0.88 元'));
      expect(best.top, greaterThan(row.top));
      expect((best.right - row.right).abs(), lessThan(1));
      expect(find.text('暂无人领取'), findsNothing);
    },
  );

  testWidgets('says nobody has claimed yet', (tester) async {
    await tester.pumpWidget(host(detail()));
    expect(find.text('暂无人领取'), findsOneWidget);
  });

  testWidgets('closes with the note only when given', (tester) async {
    await tester.pumpWidget(host(detail(note: '未领取的金额将在 24 小时后退回')));
    expect(find.text('未领取的金额将在 24 小时后退回'), findsOneWidget);
  });

  testWidgets('each claim row reads as one node', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(host(detail(claims: claims)));
      final node = tester.getSemantics(find.text('大壮'));
      expect(node.label, contains('大壮'));
      expect(node.label, contains('0.88 元'));
      expect(node.label, contains('手气最佳'));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('localizes its own copy', (tester) async {
    await tester.pumpWidget(
      host(
        detail(senderName: 'Ming', claims: [claims[1]]),
        strings: flareStringsEnglish,
      ),
    );
    expect(find.text('Red packet from Ming'), findsOneWidget);
    expect(find.text('Best luck'), findsOneWidget);
  });

  for (final width in [320.0, 1024.0]) {
    testWidgets('lays out at $width with large text', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: Size(width, 900),
            textScaler: const TextScaler.linear(1.8),
          ),
          child: host(
            detail(
              kindLabel: '拼',
              amount: '188.88 元',
              amountNote: '已存入钱包',
              claims: [
                ...claims,
                const FlareRedPacketClaim(
                  id: 'u3',
                  name: '一个名字特别特别特别长的群成员',
                  time: '10:05',
                  amount: '1.50 元',
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('no title bar unless the host passes onBack', (tester) async {
    await tester.pumpWidget(host(detail()));
    expect(find.text('红包详情'), findsNothing);
    expect(find.byType(FlareIconButton), findsNothing);
  });

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('onBack draws the red title bar ($brightness)', (tester) async {
      var backs = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
            body: SingleChildScrollView(
              child: FlareRedPacketDetail(
                senderName: '小明',
                blessing: '恭喜发财',
                summary: '已领取 1/1 个',
                onBack: () => backs++,
              ),
            ),
          ),
        ),
      );
      final title = tester.widget<Text>(find.text('红包详情'));
      expect(title.style!.color, Colors.white);
      final bar = tester.widget<ColoredBox>(
        find
            .ancestor(of: find.text('红包详情'), matching: find.byType(ColoredBox))
            .first,
      );
      final colors = brightness == Brightness.dark
          ? FlareColors.dark
          : FlareColors.light;
      expect(bar.color, colors.redPacketEnd);
      await tester.tap(find.byType(FlareIconButton));
      expect(backs, 1);
    });
  }

  testWidgets('the bar takes a host title and reaches under the status bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(top: 47),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: FlareRedPacketDetail(
                senderName: '小明',
                blessing: '恭喜发财',
                summary: '已领取 1/1 个',
                title: 'Lucky packet',
                onBack: () {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Lucky packet'), findsOneWidget);
    final box = find
        .ancestor(
          of: find.text('Lucky packet'),
          matching: find.byType(ColoredBox),
        )
        .first;
    expect(tester.getTopLeft(box).dy, 0);
    expect(tester.getTopLeft(find.text('Lucky packet')).dy, greaterThan(47));
  });
}
