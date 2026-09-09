import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/src/components/flare_member_role_sheet.dart';

void main() {
  const all = FlareMemberRoleCapabilities(
    promote: true,
    demote: true,
    mute: true,
    unmute: true,
    remove: true,
    transferOwner: true,
  );
  FlareGroupMemberSnapshot member(FlareGroupMemberRole role, {bool muted = false}) =>
      FlareGroupMemberSnapshot(
          id: 'u-${role.name}', name: role.name, role: role, muted: muted);
  List<FlareMemberRoleAction> ids(
    FlareGroupMemberSnapshot m,
    FlareGroupMemberRole viewer, [
    FlareMemberRoleCapabilities caps = all,
  ]) =>
      memberRoleActions(m, viewer, caps).map((e) => e.action).toList();

  group('memberRoleActions', () {
    test('never offers an action against the owner, whoever is looking', () {
      for (final viewer in FlareGroupMemberRole.values) {
        expect(ids(member(FlareGroupMemberRole.owner), viewer), isEmpty);
        expect(ids(member(FlareGroupMemberRole.owner, muted: true), viewer), isEmpty);
      }
    });

    test('gives a plain member no management action at all', () {
      expect(ids(member(FlareGroupMemberRole.member), FlareGroupMemberRole.member), isEmpty);
      expect(ids(member(FlareGroupMemberRole.admin), FlareGroupMemberRole.member), isEmpty);
    });

    test('stops an admin at a peer admin and never lets one transfer ownership', () {
      expect(ids(member(FlareGroupMemberRole.admin), FlareGroupMemberRole.admin), isEmpty);
      expect(ids(member(FlareGroupMemberRole.member), FlareGroupMemberRole.admin), [
        FlareMemberRoleAction.promote,
        FlareMemberRoleAction.mute,
        FlareMemberRoleAction.remove,
      ]);
    });

    test('lets the owner manage members and admins, transfer included', () {
      expect(ids(member(FlareGroupMemberRole.member), FlareGroupMemberRole.owner), [
        FlareMemberRoleAction.promote,
        FlareMemberRoleAction.mute,
        FlareMemberRoleAction.transferOwner,
        FlareMemberRoleAction.remove,
      ]);
      expect(ids(member(FlareGroupMemberRole.admin), FlareGroupMemberRole.owner), [
        FlareMemberRoleAction.demote,
        FlareMemberRoleAction.mute,
        FlareMemberRoleAction.transferOwner,
        FlareMemberRoleAction.remove,
      ]);
    });

    test('promote only for a member, demote only for an admin', () {
      const caps = FlareMemberRoleCapabilities(promote: true, demote: true);
      expect(ids(member(FlareGroupMemberRole.member), FlareGroupMemberRole.owner, caps),
          [FlareMemberRoleAction.promote]);
      expect(ids(member(FlareGroupMemberRole.admin), FlareGroupMemberRole.owner, caps),
          [FlareMemberRoleAction.demote]);
    });

    test('mute and unmute are mutually exclusive by state', () {
      const caps = FlareMemberRoleCapabilities(mute: true, unmute: true);
      expect(ids(member(FlareGroupMemberRole.member), FlareGroupMemberRole.owner, caps),
          [FlareMemberRoleAction.mute]);
      expect(
          ids(member(FlareGroupMemberRole.member, muted: true), FlareGroupMemberRole.owner, caps),
          [FlareMemberRoleAction.unmute]);
    });

    test('nothing without capabilities; each switch reveals exactly its action', () {
      expect(
          ids(member(FlareGroupMemberRole.member), FlareGroupMemberRole.owner,
              const FlareMemberRoleCapabilities()),
          isEmpty);
      expect(
          ids(member(FlareGroupMemberRole.member), FlareGroupMemberRole.owner,
              const FlareMemberRoleCapabilities(remove: true)),
          [FlareMemberRoleAction.remove]);
      expect(
          ids(member(FlareGroupMemberRole.member), FlareGroupMemberRole.owner,
              const FlareMemberRoleCapabilities(transferOwner: true)),
          [FlareMemberRoleAction.transferOwner]);
    });

    test('transferOwner and remove are the trailing danger group', () {
      final entries = memberRoleActions(
          member(FlareGroupMemberRole.member), FlareGroupMemberRole.owner, all);
      expect(entries.where((e) => e.danger).map((e) => e.action).toList(),
          [FlareMemberRoleAction.transferOwner, FlareMemberRoleAction.remove]);
      expect(entries.last.action, FlareMemberRoleAction.remove);
    });
  });

  testWidgets('mute expands host durations and dispatches the chosen one', (tester) async {
    final received = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FlareMemberRoleSheet(
          member: FlareGroupMemberSnapshot(
              id: 'm1', name: '李雷', role: FlareGroupMemberRole.member),
          viewerRole: FlareGroupMemberRole.owner,
          capabilities: all,
          muteDurations: const [
            FlareMemberMuteDuration(id: '1h', label: '1 小时'),
            FlareMemberMuteDuration(id: '1d', label: '1 天'),
          ],
          onAction: (id, action, duration) =>
              received.add('$id/${action.name}/${duration ?? '-'}'),
        ),
      ),
    ));
    expect(find.text('1 小时'), findsNothing);

    await tester.tap(find.text('禁言'));
    await tester.pump();
    expect(received, isEmpty);
    expect(find.text('1 小时'), findsOneWidget);

    await tester.tap(find.text('1 天'));
    await tester.pump();
    expect(received, ['m1/mute/1d']);
  });

  testWidgets('without durations mute is not offered at all', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FlareMemberRoleSheet(
          member: FlareGroupMemberSnapshot(
              id: 'm1', name: '李雷', role: FlareGroupMemberRole.member),
          viewerRole: FlareGroupMemberRole.owner,
          capabilities: all,
          onAction: (id, action, duration) {},
        ),
      ),
    ));
    expect(find.text('禁言'), findsNothing);
    expect(find.text('移出群聊'), findsOneWidget);
    expect(find.text('转让群主'), findsOneWidget);
  });

  testWidgets('busy blocks every action; a member viewer gets the empty reason',
      (tester) async {
    final received = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FlareMemberRoleSheet(
          member: FlareGroupMemberSnapshot(
              id: 'm1', name: '李雷', role: FlareGroupMemberRole.member),
          viewerRole: FlareGroupMemberRole.owner,
          capabilities: all,
          busy: true,
          onAction: (id, action, duration) => received.add(action.name),
        ),
      ),
    ));
    await tester.tap(find.text('移出群聊'));
    await tester.pump();
    expect(received, isEmpty);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FlareMemberRoleSheet(
          member: FlareGroupMemberSnapshot(
              id: 'm1', name: '李雷', role: FlareGroupMemberRole.member),
          viewerRole: FlareGroupMemberRole.member,
          capabilities: all,
          onAction: (id, action, duration) {},
        ),
      ),
    ));
    expect(find.text('你没有管理权限'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FlareMemberRoleSheet(
          member: FlareGroupMemberSnapshot(
              id: 'o1', name: '张三', role: FlareGroupMemberRole.owner),
          viewerRole: FlareGroupMemberRole.owner,
          capabilities: all,
          onAction: (id, action, duration) {},
        ),
      ),
    ));
    expect(find.text('群主不可被管理'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
