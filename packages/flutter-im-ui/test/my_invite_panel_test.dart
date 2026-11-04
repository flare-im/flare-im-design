import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

final _invitees = [
  FlareInvitee(
    userId: 'u1',
    displayName: 'Ann',
    joinedAt: DateTime(2026, 9, 24, 12).millisecondsSinceEpoch,
  ),
  FlareInvitee(
    userId: 'u2',
    displayName: 'Bob',
    joinedAt: DateTime(2026, 1, 5, 12).millisecondsSinceEpoch,
  ),
];
const _stats = FlareReferralStats(direct: 5, l2: 12, l3: 40, total: 57);

void main() {
  testWidgets('keeps the URL in the QR and copies only the code', (
    tester,
  ) async {
    final events = <String>[];
    const url = 'https://flare.example/r/t1/AB23CD';
    await tester.pumpWidget(
      _host(
        FlareMyInvitePanel(
          code: 'AB23CD',
          shareUrl: url,
          invitees: _invitees,
          onCopy: (code) => events.add('copy:$code'),
          onSelect: (id) => events.add('select:$id'),
        ),
      ),
    );
    expect(find.text('AB23CD'), findsOneWidget);
    expect(find.bySemanticsLabel('二维码, 我的邀请'), findsOneWidget);
    expect(find.text('扫码注册'), findsOneWidget);
    expect(find.text(url), findsNothing);
    expect(find.text('邀请链接'), findsNothing);
    expect(find.text('分享'), findsNothing);
    expect(find.text('重新生成'), findsNothing);
    expect(find.text('2026-09-24 加入'), findsOneWidget);
    expect(find.text('2026-01-05 加入'), findsOneWidget);
    await tester.tap(find.text('复制'));
    await tester.ensureVisible(find.text('Bob'));
    await tester.tap(find.text('Bob'));
    expect(events, ['copy:AB23CD', 'select:u2']);
  });

  testWidgets('fits a 12-character code and one copy action without a QR', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const code = 'AB23CD45EF67';
    final copied = <String>[];
    await tester.pumpWidget(
      _host(
        FlareMyInvitePanel(code: code, invitees: const [], onCopy: copied.add),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('扫码注册'), findsNothing);
    expect(find.text(code), findsOneWidget);
    await tester.tap(find.text('复制'));
    expect(copied, [code]);
  });

  testWidgets(
    'lists depth rows per maxDepthShown and always ends with the total',
    (tester) async {
      await tester.pumpWidget(
        _host(
          const FlareMyInvitePanel(code: 'AB12CD', invitees: [], stats: _stats),
        ),
      );
      for (final label in ['直接邀请', '二级', '三级', '团队总数']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('57'), findsOneWidget);
      await tester.pumpWidget(
        _host(
          const FlareMyInvitePanel(
            code: 'AB12CD',
            invitees: [],
            stats: _stats,
            maxDepthShown: 1,
          ),
        ),
      );
      expect(find.text('二级'), findsNothing);
      expect(find.text('三级'), findsNothing);
      expect(find.text('团队总数'), findsOneWidget);
      await tester.pumpWidget(
        _host(const FlareMyInvitePanel(code: 'AB12CD', invitees: [])),
      );
      expect(find.text('团队总数'), findsNothing);
    },
  );

  testWidgets('count-only mode shows statistics without the list', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        FlareMyInvitePanel(
          code: 'AB12CD',
          invitees: _invitees,
          showProfiles: false,
          stats: const FlareReferralStats(direct: 9, l2: 0, l3: 0, total: 9),
        ),
      ),
    );
    expect(find.text('9'), findsNWidgets(2));
    expect(find.text('直接邀请的人'), findsNothing);
    expect(find.text('Ann'), findsNothing);
  });

  testWidgets('unavailable code hides a stale link and all invite actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        FlareMyInvitePanel(
          code: '',
          shareUrl: 'https://flare.example/r/t1/AB12CD',
          invitees: _invitees,
          showProfiles: false,
          stats: _stats,
          onCopy: (_) {},
        ),
      ),
    );
    expect(find.text('邀请码暂不可用'), findsOneWidget);
    expect(find.text('我的团队'), findsOneWidget);
    expect(find.text('复制'), findsNothing);
    expect(find.text('分享'), findsNothing);
    expect(find.text('重新生成'), findsNothing);
    expect(find.bySemanticsLabel('二维码, 我的邀请'), findsNothing);
  });

  testWidgets('loading and empty are different states', (tester) async {
    await tester.pumpWidget(
      _host(const FlareMyInvitePanel(code: '', invitees: [], loading: true)),
    );
    expect(find.text('还没有人通过你的邀请码加入'), findsNothing);
    expect(find.bySemanticsLabel('正在加载邀请信息'), findsOneWidget);
    await tester.pumpWidget(
      _host(const FlareMyInvitePanel(code: 'AB12CD', invitees: [])),
    );
    expect(find.text('还没有人通过你的邀请码加入'), findsOneWidget);
  });

  testWidgets('expands nested invitees and pages each branch independently', (
    tester,
  ) async {
    const first = FlareInvitee(
      userId: 'a',
      displayName: 'Alice',
      joinedAt: 0,
      hasChildren: true,
    );
    const child = FlareInvitee(
      userId: 'b',
      displayName: 'Bea',
      joinedAt: 0,
      hasChildren: true,
    );
    const grandchild = FlareInvitee(
      userId: 'c',
      displayName: 'Cleo',
      joinedAt: 0,
      hasChildren: true,
    );
    const sibling = FlareInvitee(userId: 'd', displayName: 'Dara', joinedAt: 0);
    final requests = <(String, String?)>[];
    Future<FlareInviteeBranchPage> load(String parent, String? cursor) async {
      requests.add((parent, cursor));
      return switch ((parent, cursor)) {
        ('a', null) => const FlareInviteeBranchPage(
          invitees: [child],
          nextCursor: 'page-2',
        ),
        ('a', 'page-2') => const FlareInviteeBranchPage(invitees: [sibling]),
        ('b', null) => const FlareInviteeBranchPage(invitees: [grandchild]),
        _ => throw StateError('Unexpected branch request'),
      };
    }

    Widget panel({bool showProfiles = true}) => _host(
      FlareMyInvitePanel(
        code: 'AB23CD',
        invitees: const [first],
        showProfiles: showProfiles,
        onLoadChildren: load,
      ),
    );
    await tester.pumpWidget(panel());
    expect(find.text('邀请关系'), findsOneWidget);
    expect(find.text('直接邀请的人'), findsNothing);
    expect(find.text('当前用户'), findsNothing);
    expect(find.text('邀请人'), findsNothing);
    expect(find.text('Bea'), findsNothing);
    await tester.tap(find.bySemanticsLabel('展开 Alice'));
    await tester.pumpAndSettle();
    expect(requests, [('a', null)]);
    await tester.tap(find.bySemanticsLabel('展开 Bea'));
    await tester.pumpAndSettle();
    expect(find.text('Cleo'), findsOneWidget);
    expect(find.bySemanticsLabel('展开 Cleo'), findsNothing);
    await tester.ensureVisible(find.text('加载更多'));
    await tester.tap(find.text('加载更多'));
    await tester.pumpAndSettle();
    expect(find.text('Dara'), findsOneWidget);
    expect(requests, [('a', null), ('b', null), ('a', 'page-2')]);
    await tester.tap(find.bySemanticsLabel('收起 Alice'));
    await tester.pumpAndSettle();
    expect(find.text('Bea'), findsNothing);
    await tester.tap(find.bySemanticsLabel('展开 Alice'));
    await tester.pumpAndSettle();
    expect(find.text('Bea'), findsOneWidget);
    expect(requests, hasLength(3));

    await tester.pumpWidget(panel(showProfiles: false));
    expect(find.text('邀请关系'), findsNothing);
    expect(find.text('Alice'), findsNothing);
    expect(find.text('Dara'), findsNothing);
  });

  testWidgets('retries a failed branch without dropping its parent', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      _host(
        FlareMyInvitePanel(
          code: 'AB23CD',
          invitees: const [
            FlareInvitee(
              userId: 'a',
              displayName: 'Alice',
              joinedAt: 0,
              hasChildren: true,
            ),
          ],
          onLoadChildren: (_, _) async {
            attempts++;
            if (attempts == 1) throw StateError('offline');
            return const FlareInviteeBranchPage(invitees: []);
          },
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('展开 Alice'));
    await tester.pumpAndSettle();
    expect(find.text('Alice'), findsOneWidget);
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('暂无下级'), findsOneWidget);
  });

  testWidgets('load more shows only while another page exists', (tester) async {
    final events = <String>[];
    await tester.pumpWidget(
      _host(
        FlareMyInvitePanel(
          code: 'AB12CD',
          invitees: _invitees,
          onLoadMore: () => events.add('more'),
        ),
      ),
    );
    expect(find.text('加载更多'), findsNothing);
    await tester.pumpWidget(
      _host(
        FlareMyInvitePanel(
          code: 'AB12CD',
          invitees: _invitees,
          hasMore: true,
          onLoadMore: () => events.add('more'),
        ),
      ),
    );
    await tester.tap(find.text('加载更多'));
    expect(events, ['more']);
  });

  testWidgets('a host override changes the copy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareStringsScope(
            strings: const FlareStrings().copyWith(
              myInviteTitle: 'My invite',
              myInviteEmpty: 'No one has joined with your code yet',
            ),
            child: const FlareMyInvitePanel(code: 'AB12CD', invitees: []),
          ),
        ),
      ),
    );
    expect(find.text('My invite'), findsOneWidget);
    expect(find.text('No one has joined with your code yet'), findsOneWidget);
  });
}
