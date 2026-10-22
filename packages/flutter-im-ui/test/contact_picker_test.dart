import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _me = FlareContactPickerEntry(userId: 'u0', name: '林晓', isSelf: true);
const _ivy = FlareContactPickerEntry(userId: 'u1', name: 'Ivy Chen', subtitle: '设计组');
const _zhou = FlareContactPickerEntry(userId: 'u2', name: '周屿', subtitle: '产品');
const _groups = [
  FlareContactPickerGroup(id: flareContactPickerFriends, entries: [_ivy, _zhou]),
  FlareContactPickerGroup(id: flareContactPickerGroupMembers, entries: [_me, _ivy]),
];

class _Harness {
  final selections = <List<FlareContactPickerEntry>>[];
  var cancels = 0;

  Widget build({
    List<FlareContactPickerGroup> groups = _groups,
    bool searchable = true,
    bool multiple = false,
    FlareStrings? strings,
  }) {
    final picker = FlareContactPicker(
      groups: groups,
      searchable: searchable,
      multiple: multiple,
      onSelect: selections.add,
      onCancel: () => cancels += 1,
    );
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 640,
          child: strings == null ? picker : FlareStringsScope(strings: strings, child: picker),
        ),
      ),
    );
  }
}

Finder _row(String userId) => find.byKey(ValueKey('flare-contact-picker-$userId'));

void main() {
  testWidgets('shows a tab per group, the friends first, and switches', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.build());
    expect(find.text('好友'), findsOneWidget);
    expect(find.text('群成员'), findsOneWidget);
    expect(_row('u1'), findsOneWidget);
    expect(_row('u2'), findsOneWidget);
    expect(_row('u0'), findsNothing);
    await tester.tap(find.text('群成员'));
    await tester.pump();
    expect(_row('u0'), findsOneWidget);
    expect(find.textContaining('林晓（我）', findRichText: true), findsOneWidget);
  });

  testWidgets('draws no tabs for a single group and keeps a host label', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(
      harness.build(groups: const [FlareContactPickerGroup(id: 'colleagues', label: '同事', entries: [_ivy])]),
    );
    expect(find.byType(FlareFilterTabs), findsNothing);
    expect(find.bySemanticsLabel('同事'), findsOneWidget);
  });

  testWidgets('answers one tap with that person in single mode', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.build());
    await tester.tap(_row('u2'));
    expect(harness.selections, [
      [_zhou],
    ]);
  });

  testWidgets('searches names and subtitles, and says when nothing matches', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.build());
    await tester.enterText(find.byType(TextField), '设计');
    await tester.pump();
    expect(_row('u1'), findsOneWidget);
    expect(_row('u2'), findsNothing);
    await tester.enterText(find.byType(TextField), 'ivy');
    await tester.pump();
    expect(_row('u1'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '没有这个人');
    await tester.pump();
    expect(find.text('没有联系人'), findsOneWidget);
  });

  testWidgets('hides the search when off, and shows the empty state for an empty group', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(
      harness.build(searchable: false, groups: const [FlareContactPickerGroup(id: flareContactPickerFriends, entries: [])]),
    );
    expect(find.byType(FlareSearchBar), findsNothing);
    expect(find.text('没有联系人'), findsOneWidget);
  });

  testWidgets('toggles rows in multiple mode and answers from the confirm key', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.build(multiple: true));
    expect(find.text('确定'), findsOneWidget);
    await tester.tap(_row('u1'));
    await tester.tap(_row('u2'));
    await tester.tap(_row('u1'));
    await tester.pump();
    expect(tester.getSemantics(_row('u2')), isSemantics(hasCheckedState: true, isChecked: true));
    expect(harness.selections, isEmpty);
    await tester.tap(find.text('确定 (1)'));
    expect(harness.selections, [
      [_zhou],
    ]);
  });

  testWidgets('builds only the rows in view for a long list', (tester) async {
    final harness = _Harness();
    final many = [
      for (var i = 0; i < 500; i++) FlareContactPickerEntry(userId: 'u$i', name: '联系人 $i'),
    ];
    await tester.pumpWidget(harness.build(groups: [FlareContactPickerGroup(id: flareContactPickerFriends, entries: many)]));
    final built = find.byWidgetPredicate((widget) => widget.key is ValueKey<String> &&
        (widget.key! as ValueKey<String>).value.startsWith('flare-contact-picker-u'));
    expect(built.evaluate().length, inInclusiveRange(1, 40));
  });

  testWidgets('cancels, and speaks English', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.build(strings: flareStringsEnglish));
    expect(find.text('Choose a contact'), findsOneWidget);
    expect(find.text('Friends'), findsOneWidget);
    expect(find.text('Group members'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    expect(harness.cancels, 1);
  });
}
