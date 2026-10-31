import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';

void main() {
  const all = FlareMemberActions(
    canRemove: true,
    canMute: true,
    canChangeRole: true,
    canTransferOwner: true,
  );
  List<FlareMemberRoleAction> ids(
    FlareGroupMemberRole role, [
    FlareMemberActions? actions = all,
    bool muted = false,
  ]) => memberRoleActions(role, muted, actions).map((e) => e.action).toList();

  group('memberRoleActions', () {
    test('offers nothing the host did not answer for this member', () {
      expect(ids(FlareGroupMemberRole.member, null), isEmpty);
      expect(
        ids(FlareGroupMemberRole.member, FlareMemberActions.none),
        isEmpty,
      );
    });

    test('decides nothing by rank: what the host allows is offered', () {
      // The owner's protection and admins not managing each other come from
      // the host's answer, not from the kit.
      expect(ids(FlareGroupMemberRole.admin), [
        FlareMemberRoleAction.demote,
        FlareMemberRoleAction.mute,
        FlareMemberRoleAction.transferOwner,
        FlareMemberRoleAction.remove,
      ]);
      expect(ids(FlareGroupMemberRole.member), [
        FlareMemberRoleAction.promote,
        FlareMemberRoleAction.mute,
        FlareMemberRoleAction.transferOwner,
        FlareMemberRoleAction.remove,
      ]);
    });

    test('promote only for a member, demote only for an admin, neither for '
        'the owner', () {
      const role = FlareMemberActions(canChangeRole: true);
      expect(ids(FlareGroupMemberRole.member, role), [
        FlareMemberRoleAction.promote,
      ]);
      expect(ids(FlareGroupMemberRole.admin, role), [
        FlareMemberRoleAction.demote,
      ]);
      expect(ids(FlareGroupMemberRole.owner, role), isEmpty);
    });

    test('mute and unmute are mutually exclusive by state', () {
      const mute = FlareMemberActions(canMute: true);
      expect(ids(FlareGroupMemberRole.member, mute), [
        FlareMemberRoleAction.mute,
      ]);
      expect(ids(FlareGroupMemberRole.member, mute, true), [
        FlareMemberRoleAction.unmute,
      ]);
    });

    test('each answer reveals exactly its action', () {
      expect(
        ids(
          FlareGroupMemberRole.member,
          const FlareMemberActions(canRemove: true),
        ),
        [FlareMemberRoleAction.remove],
      );
      expect(
        ids(
          FlareGroupMemberRole.member,
          const FlareMemberActions(canTransferOwner: true),
        ),
        [FlareMemberRoleAction.transferOwner],
      );
    });

    test('transferOwner and remove are the trailing danger group', () {
      final entries = memberRoleActions(
        FlareGroupMemberRole.member,
        false,
        all,
      );
      expect(entries.where((e) => e.danger).map((e) => e.action).toList(), [
        FlareMemberRoleAction.transferOwner,
        FlareMemberRoleAction.remove,
      ]);
      expect(entries.last.action, FlareMemberRoleAction.remove);
    });
  });

  testWidgets('mute expands host durations and dispatches the chosen one', (
    tester,
  ) async {
    final received = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareMemberRoleSheet(
            member: FlareGroupMemberSnapshot(
              id: 'm1',
              name: '李雷',
              role: FlareGroupMemberRole.member,
            ),
            actions: all,
            muteDurations: const [
              FlareMemberMuteDuration(id: '1h', label: '1 小时'),
              FlareMemberMuteDuration(id: '1d', label: '1 天'),
            ],
            onAction: (id, action, duration) =>
                received.add('$id/${action.name}/${duration ?? '-'}'),
          ),
        ),
      ),
    );
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
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareMemberRoleSheet(
            member: FlareGroupMemberSnapshot(
              id: 'm1',
              name: '李雷',
              role: FlareGroupMemberRole.member,
            ),
            actions: all,
            onAction: (id, action, duration) {},
          ),
        ),
      ),
    );
    expect(find.text('禁言'), findsNothing);
    expect(find.text('移出群聊'), findsOneWidget);
    expect(find.text('转让群主'), findsOneWidget);
  });

  testWidgets(
    'busy blocks every action; nothing allowed reads as the empty reason',
    (tester) async {
      final received = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlareMemberRoleSheet(
              member: FlareGroupMemberSnapshot(
                id: 'm1',
                name: '李雷',
                role: FlareGroupMemberRole.member,
              ),
              actions: all,
              busy: true,
              onAction: (id, action, duration) => received.add(action.name),
            ),
          ),
        ),
      );
      await tester.tap(find.text('移出群聊'));
      await tester.pump();
      expect(received, isEmpty);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlareMemberRoleSheet(
              member: FlareGroupMemberSnapshot(
                id: 'm1',
                name: '李雷',
                role: FlareGroupMemberRole.member,
              ),
              // A viewer the host allows nothing on this member.
              actions: FlareMemberActions.none,
              onAction: (id, action, duration) {},
            ),
          ),
        ),
      );
      expect(find.text('你没有管理权限'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlareMemberRoleSheet(
              member: FlareGroupMemberSnapshot(
                id: 'o1',
                name: '张三',
                role: FlareGroupMemberRole.owner,
              ),
              actions: FlareMemberActions.none,
              onAction: (id, action, duration) {},
            ),
          ),
        ),
      );
      expect(find.text('群主不可被管理'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
