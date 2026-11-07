import 'dart:async';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// FR-089 (K5): the grid previews at most 20 cells; its header opens every
// member with search, and a member chosen there opens the grid's actions.

const _labels = FlareGroupDetailLabels();
const _strings = FlareStrings();

/// What the owner may manage, and do to each member, as the host answers it.
const _ownerCaps = FlareGroupCapabilities(
  canManageInfo: true,
  canManageJoinSettings: true,
  canManageJoinRequests: true,
  canInvite: true,
  canDissolve: true,
);
const _everything = FlareMemberActions(
  canRemove: true,
  canMute: true,
  canChangeRole: true,
  canTransferOwner: true,
);

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
      capabilities: canManage ? _ownerCaps : FlareGroupCapabilities.none,
      memberActions: {
        if (canManage)
          for (var i = 1; i < count; i++) 'u$i': _everything,
      },
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

Finder _memberHeader(int count) => find.ancestor(
  of: find.text(_strings.memberCount(count)),
  matching: find.byType(InkWell),
);

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

  testWidgets('the members header opens every member with search; a choice '
      'opens the member actions', (tester) async {
    final log = await _pump(tester, _model(30));
    final row = _memberHeader(30);
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

  testWidgets('an empty roster keeps one effective count and an accessible '
      'members sheet entry', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      const FlareGroupDetailModel(
        groupId: 'g1',
        name: 'Protected group',
        memberCount: 104,
        ownerId: 'owner',
      ),
    );
    expect(find.text(_strings.memberCount(104)), findsOneWidget);
    expect(find.text(_labels.memberCount(104)), findsNothing);
    final header = _memberHeader(104);
    expect(
      tester.getSemantics(header),
      matchesSemantics(
        label: '${_strings.groupMembers}\n${_strings.memberCount(104)}',
        textDirection: TextDirection.ltr,
        isButton: true,
        isFocusable: true,
        hasFocusAction: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(header);
    await tester.pumpAndSettle();
    expect(find.text(_strings.groupDetailMembersTitle(104)), findsOneWidget);
    expect(find.text(_strings.groupDetailNoMatchingMembers), findsOneWidget);
    semantics.dispose();
  });

  for (final (formFactor, width) in [('phone', 400.0), ('desktop', 1200.0)]) {
    testWidgets('the open $formFactor roster updates its title and members', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final unrestricted = _model(4, canManage: false);
      final model = ValueNotifier(unrestricted);
      addTearDown(model.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: model,
              builder: (_, detail, _) => FlareGroupDetail(model: detail),
            ),
          ),
        ),
      );
      await tester.tap(_memberHeader(4));
      await tester.pumpAndSettle();
      final sheet = find.byType(FlareBottomSheet);
      Finder inSheet(String label) =>
          find.descendant(of: sheet, matching: find.text(label));
      expect(inSheet(_strings.groupDetailMembersTitle(4)), findsOneWidget);
      expect(inSheet('Member 3'), findsOneWidget);

      model.value = const FlareGroupDetailModel(
        groupId: 'g1',
        name: 'Big group',
        memberCount: 104,
        membersRevision: 1,
        ownerId: 'owner',
        members: [FlareContact(id: 'owner', name: 'Owner')],
      );
      await tester.pumpAndSettle();
      expect(inSheet('Owner'), findsOneWidget);
      expect(inSheet('Member 3'), findsNothing);
      expect(inSheet(_strings.groupDetailMembersTitle(4)), findsNothing);
      expect(inSheet(_strings.groupDetailMembersTitle(104)), findsOneWidget);

      model.value = unrestricted;
      await tester.pumpAndSettle();
      expect(inSheet('Member 3'), findsOneWidget);
      expect(inSheet(_strings.groupDetailMembersTitle(4)), findsOneWidget);
      expect(inSheet(_strings.groupDetailMembersTitle(104)), findsNothing);
    });
  }

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
    await tester.tap(_memberHeader(30));
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

  testWidgets(
    'a fresh roster removes stale search results from an open sheet',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const restricted = FlareGroupDetailModel(
        groupId: 'g1',
        name: 'Big group',
        memberCount: 30,
        membersRevision: 1,
        ownerId: 'owner',
      );
      final model = ValueNotifier(_model(30));
      addTearDown(model.dispose);
      final searches = <Completer<List<FlareContact>>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: model,
              builder: (context, detail, _) => FlareGroupDetail(
                model: detail,
                onSearchMembers: (keyword) {
                  final search = Completer<List<FlareContact>>();
                  searches.add(search);
                  return search.future;
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(_memberHeader(30));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(TextField),
        ),
        'alice',
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(searches, hasLength(1));
      model.value = restricted;
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(searches, hasLength(2));

      searches.first.complete(const [
        FlareContact(id: 'hidden', name: 'Hidden Alice'),
      ]);
      await tester.pump();
      expect(find.text('Hidden Alice'), findsNothing);
      searches.last.complete(const [
        FlareContact(id: 'owner', name: 'Owner Alice'),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Owner Alice'), findsOneWidget);
    },
  );

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
    expect(find.byType(FlareBottomSheet), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(FlareBottomSheet),
        matching: find.byType(TextField),
      ),
      '  ',
    );
    await tester.pump();
    final save = find.widgetWithText(FlareButton, _labels.save);
    expect(tester.widget<FlareButton>(save).disabled, isTrue);
    await tester.enterText(
      find.descendant(
        of: find.byType(FlareBottomSheet),
        matching: find.byType(TextField),
      ),
      ' Release room ',
    );
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.byType(FlareBottomSheet), findsNothing);
    expect(names, ['Release room']);
  });
}
