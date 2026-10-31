import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _labels = FlareGroupDetailLabels();

FlareGroupDetailModel _model({
  List<String> adminIds = const [],
  List<String> mutedIds = const [],
}) => FlareGroupDetailModel(
  groupId: 'g1',
  name: 'Team',
  memberCount: 3,
  members: const [
    FlareContact(id: 'owner', name: 'Olivia'),
    FlareContact(id: 'u2', name: 'Bob'),
    FlareContact(id: 'u3', name: 'Cai'),
  ],
  ownerId: 'owner',
  adminIds: adminIds,
  mutedIds: mutedIds,
  capabilities: const FlareGroupCapabilities(
    canManageInfo: true,
    canManageJoinSettings: true,
    canManageJoinRequests: true,
    canInvite: true,
    canDissolve: true,
  ),
  memberActions: const {
    'u2': FlareMemberActions(
      canRemove: true,
      canMute: true,
      canChangeRole: true,
      canTransferOwner: true,
    ),
    'u3': FlareMemberActions(
      canRemove: true,
      canMute: true,
      canChangeRole: true,
      canTransferOwner: true,
    ),
  },
);

Widget _host(FlareGroupDetailModel model, List<(String, String, bool)> log) =>
    MaterialApp(
      home: Scaffold(
        body: FlareGroupDetail(
          model: model,
          onPromoteMember: (id, admin) => log.add(('promote', id, admin)),
          onMuteMember: (id, muted) => log.add(('mute', id, muted)),
        ),
      ),
    );

Future<void> _act(WidgetTester tester, String member, String action) async {
  await tester.tap(find.text(member));
  await tester.pumpAndSettle();
  await tester.tap(find.text(action));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('role and mute intents carry the state their buttons name', (
    tester,
  ) async {
    final log = <(String, String, bool)>[];
    await tester.pumpWidget(
      _host(_model(adminIds: ['u2'], mutedIds: ['u3']), log),
    );
    await _act(tester, 'Bob', _labels.unsetAdmin);
    await _act(tester, 'Bob', _labels.mute);
    await _act(tester, 'Cai', _labels.setAdmin);
    await _act(tester, 'Cai', _labels.unmute);
    expect(log, [
      ('promote', 'u2', false),
      ('mute', 'u2', true),
      ('promote', 'u3', true),
      ('mute', 'u3', false),
    ]);
  });

  testWidgets('removing a member and leaving are emitted as tapped', (
    tester,
  ) async {
    final log = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareGroupDetail(
            model: _model(),
            onRemoveMember: (id) => log.add('remove $id'),
            onLeave: () => log.add('leave'),
          ),
        ),
      ),
    );
    await _act(tester, 'Bob', _labels.removeMember);
    // The host confirms these with its own presenter; the kit asks nothing.
    expect(find.byType(FlareDangerConfirm), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(log, ['remove u2']);

    final leave = find.widgetWithText(FlareButton, _labels.dissolve);
    await tester.scrollUntilVisible(
      leave,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(leave);
    await tester.pumpAndSettle();
    expect(find.byType(FlareDangerConfirm), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(log, ['remove u2', 'leave']);
  });

  testWidgets('transferring ownership still asks before it is emitted', (
    tester,
  ) async {
    final transfers = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareGroupDetail(
            model: _model(),
            onTransferOwner: transfers.add,
          ),
        ),
      ),
    );
    await _act(tester, 'Bob', _labels.transferOwner);
    // The kit's own confirmation, on the kit's short-task surface.
    expect(find.byType(FlareDangerConfirm), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text(_labels.transferConfirm('Bob')), findsOneWidget);
    expect(transfers, isEmpty);

    await tester.tap(find.text(_labels.cancel));
    await tester.pumpAndSettle();
    expect(find.byType(FlareDangerConfirm), findsNothing);
    expect(transfers, isEmpty);

    await _act(tester, 'Bob', _labels.transferOwner);
    await tester.tap(find.text(_labels.confirmTransfer));
    await tester.pumpAndSettle();
    expect(transfers, ['u2']);
  });

  testWidgets('an open sheet follows the model; the intent follows its label', (
    tester,
  ) async {
    final log = <(String, String, bool)>[];
    await tester.pumpWidget(_host(_model(adminIds: ['u2']), log));
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();
    expect(find.text(_labels.unsetAdmin), findsOneWidget);

    // Someone else revoked the role while the sheet was open.
    await tester.pumpWidget(_host(_model(), log));
    await tester.pumpAndSettle();
    expect(find.text(_labels.unsetAdmin), findsNothing);
    await tester.tap(find.text(_labels.setAdmin));
    await tester.pumpAndSettle();
    expect(log, [('promote', 'u2', true)]);
  });

  testWidgets('each member offers only the actions the host allows on it', (
    tester,
  ) async {
    // An admin who may only mute: the host answered mute for the plain member
    // and nothing for the peer admin or the owner.
    final log = <(String, String, bool)>[];
    const model = FlareGroupDetailModel(
      groupId: 'g1',
      name: 'Team',
      memberCount: 3,
      members: [
        FlareContact(id: 'owner', name: 'Olivia'),
        FlareContact(id: 'peer', name: 'Pat'),
        FlareContact(id: 'kim', name: 'Kim'),
      ],
      ownerId: 'owner',
      adminIds: ['me', 'peer'],
      memberActions: {
        'kim': FlareMemberActions(canMute: true),
        'peer': FlareMemberActions(),
      },
    );
    await tester.pumpWidget(_host(model, log));
    await tester.tap(find.text('Kim'));
    await tester.pumpAndSettle();
    expect(find.text(_labels.memberManage), findsOneWidget);
    expect(find.text(_labels.mute), findsOneWidget);
    for (final label in [
      _labels.setAdmin,
      _labels.unsetAdmin,
      _labels.transferOwner,
      _labels.removeMember,
    ]) {
      expect(find.text(label), findsNothing, reason: label);
    }
    await tester.tap(find.text(_labels.mute));
    await tester.pumpAndSettle();
    expect(log, [('mute', 'kim', true)]);

    for (final name in ['Pat', 'Olivia']) {
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
      expect(find.text(_labels.memberManage), findsNothing, reason: name);
    }
  });

  testWidgets('each management row shows only for the capability naming it', (
    tester,
  ) async {
    Future<(List<String>, bool, bool)> rowsFor(
      FlareGroupCapabilities capabilities,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlareGroupDetail(
              model: FlareGroupDetailModel(
                groupId: 'g1',
                name: 'Team',
                memberCount: 1,
                members: const [FlareContact(id: 'owner', name: 'Olivia')],
                ownerId: 'owner',
                capabilities: capabilities,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final lists = tester.widgetList<FlareSettingsList>(
        find.byType(FlareSettingsList),
      );
      final keys = [
        for (final list in lists)
          for (final section in list.sections.skip(2))
            for (final item in section.items) item.key,
      ];
      final grid = tester.widget<FlareGroupMemberGrid>(
        find.byType(FlareGroupMemberGrid),
      );
      final dissolve = find
          .widgetWithText(FlareButton, _labels.dissolve, skipOffstage: false)
          .evaluate()
          .isNotEmpty;
      return (keys, grid.showAdd, dissolve);
    }

    // An admin with the join permission alone sees join requests, nothing else.
    final join = await rowsFor(
      const FlareGroupCapabilities(canManageJoinRequests: true),
    );
    expect(join.$1, ['joinRequests']);
    expect((join.$2, join.$3), (false, false));
    // A member of a group that lets members share its card may invite.
    final invite = await rowsFor(const FlareGroupCapabilities(canInvite: true));
    expect(invite.$1, ['inviteLink']);
    expect((invite.$2, invite.$3), (true, false));
    // The info permission edits the switches, not the join policy.
    expect(
      (await rowsFor(const FlareGroupCapabilities(canManageInfo: true))).$1,
      ['muteAll', 'atAll', 'pinPerm', 'shareCard'],
    );
    expect(
      (await rowsFor(
        const FlareGroupCapabilities(canManageJoinSettings: true),
      )).$1,
      ['discoverable', 'joinPolicy'],
    );
    // Only the capability to dissolve turns leaving into dissolving.
    expect(
      (await rowsFor(const FlareGroupCapabilities(canDissolve: true))).$3,
      isTrue,
    );
    final none = await rowsFor(FlareGroupCapabilities.none);
    expect(none.$1, isEmpty);
    expect((none.$2, none.$3), (false, false));
  });
}
