import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

final _invitees = [
  FlareInvitee(userId: 'u1', displayName: 'Ann', joinedAt: DateTime(2026, 9, 24, 12).millisecondsSinceEpoch),
  FlareInvitee(userId: 'u2', displayName: 'Bob', joinedAt: DateTime(2026, 1, 5, 12).millisecondsSinceEpoch),
];
const _stats = FlareReferralStats(direct: 5, l2: 12, l3: 40, total: 57);

void main() {
  testWidgets('shows the code and link, dispatches copy / share / select', (tester) async {
    final events = <String>[];
    await tester.pumpWidget(_host(FlareMyInvitePanel(
      code: 'AB12CD',
      shareUrl: 'https://flare.example/r/t1/AB12CD',
      invitees: _invitees,
      onCopy: (c) => events.add('copy:$c'),
      onShare: (u) => events.add('share:$u'),
      onSelect: (id) => events.add('select:$id'),
    )));
    expect(find.text('AB12CD'), findsOneWidget);
    expect(find.text('https://flare.example/r/t1/AB12CD'), findsOneWidget);
    expect(find.text('2026-09-24 加入'), findsOneWidget);
    expect(find.text('2026-01-05 加入'), findsOneWidget);
    await tester.tap(find.text('复制'));
    await tester.tap(find.text('分享'));
    await tester.tap(find.text('Bob'));
    expect(events, ['copy:AB12CD', 'share:https://flare.example/r/t1/AB12CD', 'select:u2']);
  });

  testWidgets('shares the code itself when the host built no link', (tester) async {
    final events = <String>[];
    await tester.pumpWidget(_host(FlareMyInvitePanel(code: 'AB12CD', invitees: const [], onShare: events.add)));
    await tester.tap(find.text('分享'));
    expect(events, ['AB12CD']);
  });

  testWidgets('lists depth rows per maxDepthShown and always ends with the total', (tester) async {
    await tester.pumpWidget(_host(const FlareMyInvitePanel(code: 'AB12CD', invitees: [], stats: _stats)));
    for (final label in ['直接邀请', '二级', '三级', '团队总数']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('57'), findsOneWidget);
    await tester.pumpWidget(_host(const FlareMyInvitePanel(code: 'AB12CD', invitees: [], stats: _stats, maxDepthShown: 1)));
    expect(find.text('二级'), findsNothing);
    expect(find.text('三级'), findsNothing);
    expect(find.text('团队总数'), findsOneWidget);
    await tester.pumpWidget(_host(const FlareMyInvitePanel(code: 'AB12CD', invitees: [])));
    expect(find.text('团队总数'), findsNothing);
  });

  testWidgets('count-only mode replaces the list with the direct count', (tester) async {
    await tester.pumpWidget(_host(FlareMyInvitePanel(
      code: 'AB12CD',
      invitees: _invitees,
      showProfiles: false,
      stats: const FlareReferralStats(direct: 9, l2: 0, l3: 0, total: 9),
    )));
    expect(find.text('9 人'), findsOneWidget);
    expect(find.text('Ann'), findsNothing);
  });

  testWidgets('loading and empty are different states', (tester) async {
    await tester.pumpWidget(_host(const FlareMyInvitePanel(code: '', invitees: [], loading: true)));
    expect(find.text('还没有人通过你的邀请码加入'), findsNothing);
    expect(find.bySemanticsLabel('正在加载邀请信息'), findsOneWidget);
    await tester.pumpWidget(_host(const FlareMyInvitePanel(code: 'AB12CD', invitees: [])));
    expect(find.text('还没有人通过你的邀请码加入'), findsOneWidget);
  });

  testWidgets('regenerate is offered only when allowed, disabled and explained while cooling down', (tester) async {
    final events = <String>[];
    await tester.pumpWidget(_host(FlareMyInvitePanel(code: 'AB12CD', invitees: const [], onRegenerate: () => events.add('regenerate'))));
    expect(find.text('重新生成'), findsNothing);

    final soon = DateTime.now().millisecondsSinceEpoch + 15 * 60 * 1000;
    await tester.pumpWidget(_host(FlareMyInvitePanel(
      code: 'AB12CD', invitees: const [], canRegenerate: true, regenerateAvailableAt: soon,
      onRegenerate: () => events.add('regenerate'),
    )));
    expect(find.text('15 分钟 后可重新生成'), findsOneWidget);
    await tester.tap(find.text('重新生成'), warnIfMissed: false);
    expect(events, isEmpty);

    await tester.pumpWidget(_host(FlareMyInvitePanel(
      code: 'AB12CD', invitees: const [], canRegenerate: true,
      onRegenerate: () => events.add('regenerate'),
    )));
    expect(find.textContaining('后可重新生成'), findsNothing);
    await tester.tap(find.text('重新生成'));
    expect(events, ['regenerate']);

    await tester.pumpWidget(_host(const FlareMyInvitePanel(code: 'AB12CD', invitees: [], canRegenerate: true, regenerating: true)));
    expect(find.text('生成中…'), findsOneWidget);
  });

  testWidgets('load more shows only while another page exists', (tester) async {
    final events = <String>[];
    await tester.pumpWidget(_host(FlareMyInvitePanel(code: 'AB12CD', invitees: _invitees, onLoadMore: () => events.add('more'))));
    expect(find.text('加载更多'), findsNothing);
    await tester.pumpWidget(_host(FlareMyInvitePanel(code: 'AB12CD', invitees: _invitees, hasMore: true, onLoadMore: () => events.add('more'))));
    await tester.tap(find.text('加载更多'));
    expect(events, ['more']);
  });

  testWidgets('a host override changes the copy', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FlareStringsScope(
          strings: const FlareStrings().copyWith(
            myInviteTitle: 'My invite',
            myInviteEmpty: 'No one has joined with your code yet',
          ),
          child: const FlareMyInvitePanel(code: 'AB12CD', invitees: []),
        ),
      ),
    ));
    expect(find.text('My invite'), findsOneWidget);
    expect(find.text('No one has joined with your code yet'), findsOneWidget);
  });
}
