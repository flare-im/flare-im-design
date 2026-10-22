import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// RedPacketDetail against spec/red-packet-vectors.json → detail: what each
/// viewer role sees per status, from the fields the server returned.
final Map<String, dynamic> table =
    jsonDecode(File('../../spec/red-packet-vectors.json').readAsStringSync())
        as Map<String, dynamic>;
final Map<String, dynamic> detailTable = table['detail'] as Map<String, dynamic>;
final int nowMs = detailTable['nowMs'] as int;
final int offset = detailTable['utcOffsetMinutes'] as int;

Widget host(Widget child, {FlareStrings strings = const FlareStrings()}) =>
    MaterialApp(
      home: FlareStringsScope(
        strings: strings,
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

FlareRedPacketDetailsView detailsOf(String id) {
  final v = (detailTable['cases'] as List).cast<Map<String, dynamic>>()
      .firstWhere((c) => c['id'] == id);
  return FlareRedPacketDetailsView.fromJson(
    (v['details'] as Map).cast<String, Object?>(),
  );
}

const claims = [
  FlareRedPacketClaim(
    id: 'u1',
    name: '阿花',
    amountMinor: '62',
    claimedAtMs: 1792632660000,
  ),
  FlareRedPacketClaim(
    id: 'u2',
    name: '大壮',
    amountMinor: '88',
    claimedAtMs: 1792632720000,
    best: true,
  ),
];

FlareRedPacketDetail detail({
  String id = 'sender-open',
  List<FlareRedPacketClaim> claims = const [],
  String senderName = '小明',
  String? designatedName,
  String? title,
  VoidCallback? onBack,
}) => FlareRedPacketDetail(
  senderName: senderName,
  details: detailsOf(id),
  designatedName: designatedName,
  claims: claims,
  nowMs: nowMs,
  title: title,
  onBack: onBack,
);

void main() {
  test('every case: amount, deposited, headline, summary, claims, note', () {
    const zh = FlareStrings();
    for (final v in (detailTable['cases'] as List)
        .cast<Map<String, dynamic>>()) {
      final got = flareRedPacketDetailPresentation(
        FlareRedPacketDetailsView.fromJson(
          (v['details'] as Map).cast<String, Object?>(),
        ),
        strings: zh,
        nowMs: nowMs,
        utcOffsetMinutes: offset,
        designatedName: v['designatedName'] as String?,
      );
      final expect_ = v['expect'] as Map<String, dynamic>;
      final id = v['id'] as String;
      expect(got.amount, expect_['amount'], reason: '$id amount');
      expect(got.deposited, expect_['deposited'], reason: '$id deposited');
      expect(got.headline, expect_['headline'], reason: '$id headline');
      expect(got.summary, expect_['summary'], reason: '$id summary');
      expect(got.claims, expect_['claims'], reason: '$id claims');
      expect(got.note, expect_['note'], reason: '$id note');
    }
  });

  test('claim rows: money and time', () {
    const zh = FlareStrings();
    for (final v in (detailTable['claimRows'] as List)
        .cast<Map<String, dynamic>>()) {
      final claim = v['claim'] as Map<String, dynamic>;
      final expected = v['expect'] as Map<String, dynamic>;
      expect(
        flareRedPacketMoney(
          claim['amountMinor'] as String,
          v['currencyExponent'] as int,
          v['currency'] as String,
        ),
        expected['amount'],
      );
      expect(
        flareRedPacketTime(
          claim['claimedAtMs'] as int,
          nowMs,
          zh,
          utcOffsetMinutes: offset,
        ),
        expected['time'],
      );
    }
  });

  test('the copy keys carry the vectors\' zh copy', () {
    const s = FlareStrings();
    final zh = (detailTable['copy'] as Map<String, dynamic>)['zh'] as Map;
    expect(s.packetSummarySender, zh['summarySender']);
    expect(s.packetSummaryCompleted, zh['summaryCompleted']);
    expect(s.packetSummaryCount, zh['summaryCount']);
    expect(s.packetRefundAt, zh['refundAt']);
    expect(s.packetRefundedNote, zh['refundedNote']);
    expect(s.packetDeposited, zh['deposited']);
    expect(s.packetMissed, zh['missed']);
    expect(s.packetExpiredNotice, zh['expired']);
    expect(s.packetNotEligibleName, zh['notEligibleName']);
    expect(s.packetNotEligible, zh['notEligible']);
  });

  testWidgets('a claimer sees their own amount large and the deposit line', (
    tester,
  ) async {
    await tester.pumpWidget(host(detail(id: 'claimer-open', claims: claims)));
    expect(find.text('小明的红包'), findsOneWidget);
    expect(find.text('拼手气'), findsOneWidget);
    expect(find.text('恭喜发财，大吉大利'), findsOneWidget);
    final amount = tester.widget<Text>(find.byKey(FlareRedPacketDetail.amountKey));
    expect(amount.data, '¥2.30');
    expect(amount.style!.fontSize, FlareSizes.componentRedPacketAmountFontSize);
    expect(find.text('已存入钱包'), findsOneWidget);
    expect(find.text('已领取 2/5 个'), findsOneWidget);
  });

  testWidgets('the not-designated viewer sees no amount and no records', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(detail(id: 'ineligible-named', designatedName: 'Bob', claims: claims)),
    );
    expect(find.text('仅 Bob 可领取'), findsOneWidget);
    expect(find.byKey(FlareRedPacketDetail.amountKey), findsNothing);
    expect(find.byKey(FlareRedPacketDetail.summaryKey), findsNothing);
    expect(find.byKey(FlareRedPacketDetail.claimsKey), findsNothing);
    expect(find.text('阿花'), findsNothing);
    expect(find.textContaining('¥'), findsNothing);
  });

  testWidgets('an eligible member who came too late sees the records only', (
    tester,
  ) async {
    await tester.pumpWidget(host(detail(id: 'eligible-completed', claims: claims)));
    expect(find.text('手慢了，红包派完了'), findsOneWidget);
    expect(find.text('已领取 5/5 个'), findsOneWidget);
    expect(find.text('阿花'), findsOneWidget);
    expect(find.text('¥0.62'), findsOneWidget);
  });

  testWidgets('the sender gets totals and the refund time', (tester) async {
    await tester.pumpWidget(host(detail(claims: claims)));
    expect(find.byKey(FlareRedPacketDetail.amountKey), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(FlareRedPacketDetail.summaryKey)).data,
      '已领取 2/5 个，共 ¥3.88/¥10.00',
    );
    expect(find.byKey(FlareRedPacketDetail.noteKey), findsOneWidget);
  });

  testWidgets(
    'lists claims with name, time and amount; only the best is marked',
    (tester) async {
      await tester.pumpWidget(host(detail(claims: claims)));
      for (final text in ['阿花', '大壮', '¥0.62', '¥0.88']) {
        expect(find.text(text), findsOneWidget);
      }
      expect(find.text('手气最佳'), findsOneWidget);
      final best = tester.getRect(find.text('手气最佳'));
      final row = tester.getRect(find.text('¥0.88'));
      expect(best.top, greaterThan(row.top));
      expect((best.right - row.right).abs(), lessThan(1));
      expect(find.text('暂无人领取'), findsNothing);
    },
  );

  testWidgets('says nobody has claimed yet when the list is shown empty', (
    tester,
  ) async {
    await tester.pumpWidget(host(detail()));
    expect(find.text('暂无人领取'), findsOneWidget);
  });

  testWidgets('each claim row reads as one node', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(host(detail(claims: claims)));
      final node = tester.getSemantics(find.text('大壮'));
      expect(node.label, contains('大壮'));
      expect(node.label, contains('¥0.88'));
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
              id: 'sender-open-claimed-own-share',
              claims: [
                ...claims,
                const FlareRedPacketClaim(
                  id: 'u3',
                  name: '一个名字特别特别特别长的群成员',
                  amountMinor: '150',
                  claimedAtMs: 1792632780000,
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
            body: SingleChildScrollView(child: detail(onBack: () => backs++)),
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
              child: detail(title: 'Lucky packet', onBack: () {}),
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
