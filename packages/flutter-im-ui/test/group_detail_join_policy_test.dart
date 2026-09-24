import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _labels = FlareGroupDetailLabels();

FlareGroupDetailModel _model(FlareGroupJoinPolicy? joinPolicy) =>
    FlareGroupDetailModel(
      groupId: 'g1',
      name: 'Team',
      memberCount: 1,
      members: const [FlareContact(id: 'owner', name: 'Olivia')],
      ownerId: 'owner',
      canManage: true,
      isOwner: true,
      joinPolicy: joinPolicy,
    );

Widget _host(
  FlareGroupJoinPolicy? joinPolicy,
  List<FlareGroupJoinPolicy> saved,
) => MaterialApp(
  home: Scaffold(
    body: FlareGroupDetail(
      model: _model(joinPolicy),
      onSetJoinPolicy: saved.add,
    ),
  ),
);

Finder get _joinRow => find.ancestor(
  of: find.text(_labels.joinMode),
  matching: find.byType(FlareSettingsRow),
);

Future<void> _openPicker(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text(_labels.joinMode),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(_joinRow);
  await tester.pumpAndSettle();
}

Finder get _save => find.widgetWithText(FlareButton, _labels.save);

Finder _choice(String label) => find.descendant(
  of: find.byType(FlareRadioGroup),
  matching: find.text(label),
);

void main() {
  testWidgets('the discoverability row reports the requested state', (
    tester,
  ) async {
    final saved = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareGroupDetail(
            model: _model(null),
            onToggleDiscoverable: saved.add,
          ),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text(_labels.discoverable),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    final row = find.ancestor(
      of: find.text(_labels.discoverable),
      matching: find.byType(FlareSettingsRow),
    );
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(saved, [true]);
  });

  testWidgets('the join-mode row names the policy, or says not set', (
    tester,
  ) async {
    await tester.pumpWidget(_host(FlareGroupJoinPolicy.approval, []));
    await tester.scrollUntilVisible(
      find.text(_labels.joinMode),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(of: _joinRow, matching: find.text(_labels.joinApproval)),
      findsOneWidget,
    );

    await tester.pumpWidget(_host(null, []));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: _joinRow, matching: find.text(_labels.notSet)),
      findsOneWidget,
    );
    for (final guess in [
      _labels.joinOpen,
      _labels.joinApproval,
      _labels.joinInvite,
    ]) {
      expect(
        find.descendant(of: _joinRow, matching: find.text(guess)),
        findsNothing,
      );
    }
  });

  testWidgets('an unknown policy opens with nothing selected; saving waits '
      'for a pick', (tester) async {
    final semantics = tester.ensureSemantics();
    final saved = <FlareGroupJoinPolicy>[];
    await tester.pumpWidget(_host(null, saved));
    await _openPicker(tester);

    // Display order: open, approval, invite.
    final tops = [
      for (final label in [
        _labels.joinOpen,
        _labels.joinApproval,
        _labels.joinInvite,
      ])
        tester.getTopLeft(_choice(label)).dy,
    ];
    expect(tops, [...tops]..sort());
    for (final label in [
      _labels.joinOpen,
      _labels.joinApproval,
      _labels.joinInvite,
    ]) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(label).last),
        isSemantics(hasCheckedState: true, isChecked: false),
      );
    }
    expect(tester.widget<FlareButton>(_save).disabled, isTrue);
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.byType(FlareRadioGroup), findsOneWidget, reason: 'still open');
    expect(saved, isEmpty);

    await tester.tap(_choice(_labels.joinApproval));
    await tester.pumpAndSettle();
    expect(tester.widget<FlareButton>(_save).disabled, isFalse);
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(find.byType(FlareRadioGroup), findsNothing);
    expect(saved, [FlareGroupJoinPolicy.approval]);
    semantics.dispose();
  });

  testWidgets('a known policy opens selected and reports the new pick', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final saved = <FlareGroupJoinPolicy>[];
    await tester.pumpWidget(_host(FlareGroupJoinPolicy.invite, saved));
    await _openPicker(tester);
    expect(
      tester.getSemantics(find.bySemanticsLabel(_labels.joinInvite).last),
      isSemantics(hasCheckedState: true, isChecked: true),
    );
    await tester.tap(_choice(_labels.joinOpen));
    await tester.pumpAndSettle();
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(saved, [FlareGroupJoinPolicy.open]);

    // Cancelling reports nothing.
    await _openPicker(tester);
    await tester.tap(_choice(_labels.joinApproval));
    await tester.tap(find.widgetWithText(FlareButton, _labels.cancel));
    await tester.pumpAndSettle();
    expect(saved, [FlareGroupJoinPolicy.open]);
    semantics.dispose();
  });
}
