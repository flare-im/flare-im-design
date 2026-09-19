import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// FR-089 (K5): the grid previews at most 20 cells; the 群成员 row opens every
// member with search, and a member chosen there opens the grid's actions.

const _labels = FlareGroupDetailLabels();
const _strings = FlareStrings();

FlareGroupDetailModel _model(int count, {bool canManage = true}) =>
    FlareGroupDetailModel(
      groupId: 'g1',
      name: 'Big group',
      memberCount: count,
      members: [
        const FlareContact(id: 'owner', name: 'Owner'),
        for (var i = 1; i < count; i++)
          FlareContact(id: 'u$i', name: 'Member $i'),
      ],
      ownerId: 'owner',
      canManage: canManage,
      isOwner: canManage,
    );

Future<List<(String, String, bool)>> _pump(
  WidgetTester tester,
  FlareGroupDetailModel model,
) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final log = <(String, String, bool)>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: FlareGroupDetail(
          model: model,
          onMuteMember: (id, muted) => log.add(('mute', id, muted)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return log;
}

List<FlareContact> _gridMembers(WidgetTester tester) => tester
    .widget<FlareGroupMemberGrid>(find.byType(FlareGroupMemberGrid))
    .members;

void main() {
  testWidgets('the grid previews 19 members and the add tile for a manager, '
      '20 otherwise, and counts everyone', (tester) async {
    await _pump(tester, _model(500));
    final grid = tester.widget<FlareGroupMemberGrid>(
      find.byType(FlareGroupMemberGrid),
    );
    expect(grid.members, hasLength(19));
    expect(grid.showAdd, isTrue);
    expect(find.text(_strings.memberCount(500)), findsOneWidget);

    await _pump(tester, _model(500, canManage: false));
    expect(_gridMembers(tester), hasLength(20));

    await _pump(tester, _model(3));
    expect(_gridMembers(tester), hasLength(3));
  });

  testWidgets('the members row opens every member with search; a choice '
      'opens the member actions', (tester) async {
    final log = await _pump(tester, _model(30));
    final row = find.ancestor(
      of: find.text(_labels.memberCount(30)),
      matching: find.byType(FlareSettingsRow),
    );
    expect(
      find.descendant(of: row, matching: find.byIcon(Icons.chevron_right)),
      findsOneWidget,
    );
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text(_strings.groupDetailMembersTitle(30)), findsOneWidget);
    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.byType(FlareSearchBar)),
      findsOneWidget,
    );

    await tester.enterText(
      find.descendant(of: sheet, matching: find.byType(TextField)),
      'member 27',
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: sheet, matching: find.byType(FlareContactItem)),
      findsOneWidget,
    );
    await tester.enterText(
      find.descendant(of: sheet, matching: find.byType(TextField)),
      'nobody',
    );
    await tester.pumpAndSettle();
    expect(find.text(_strings.groupDetailNoMatchingMembers), findsOneWidget);

    await tester.enterText(
      find.descendant(of: sheet, matching: find.byType(TextField)),
      'Member 27',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: sheet,
        matching: find.widgetWithText(FlareContactItem, 'Member 27'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(_labels.memberManage), findsOneWidget);
    await tester.tap(find.text(_labels.mute));
    await tester.pumpAndSettle();
    expect(log, [('mute', 'u27', true)]);
  });

  testWidgets('the members sheet can use host-backed member search', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareGroupDetail(
            model: _model(30),
            onSearchMembers: (keyword) async {
              calls.add(keyword);
              return const [FlareContact(id: 'remote', name: 'Remote Alice')];
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final row = find.ancestor(
      of: find.text(_labels.memberCount(30)),
      matching: find.byType(FlareSettingsRow),
    );
    await tester.tap(row);
    await tester.pumpAndSettle();
    final sheet = find.byType(BottomSheet);

    await tester.enterText(
      find.descendant(of: sheet, matching: find.byType(TextField)),
      'alice',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(calls, ['alice']);
    expect(
      find.descendant(of: sheet, matching: find.text('Remote Alice')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Member 1')),
      findsNothing,
    );
  });

  testWidgets('editing the group name goes through the prompt presenter and '
      'waits for a name', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final names = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareGroupDetail(model: _model(3), onUpdateName: names.add),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(_labels.name));
    await tester.pumpAndSettle();
    expect(find.byType(FlareDialog), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(FlareDialog),
        matching: find.byType(TextField),
      ),
      '  ',
    );
    await tester.pump();
    final save = find.widgetWithText(FlareButton, _labels.save);
    expect(tester.widget<FlareButton>(save).disabled, isTrue);
    await tester.enterText(
      find.descendant(
        of: find.byType(FlareDialog),
        matching: find.byType(TextField),
      ),
      ' Release room ',
    );
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.byType(FlareDialog), findsNothing);
    expect(names, ['Release room']);
  });
}
