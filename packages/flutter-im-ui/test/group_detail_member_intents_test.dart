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
  canManage: true,
  isOwner: true,
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
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(_labels.transferConfirm('Bob')), findsOneWidget);
    expect(transfers, isEmpty);

    await tester.tap(find.text(_labels.cancel));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
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
}
