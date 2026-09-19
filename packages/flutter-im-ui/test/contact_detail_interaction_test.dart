import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// A contact profile offers an intent only when the host handles it: a host
// without calls draws no call buttons, and a stranger's profile (no remark,
// star or remove handlers) shows no friend-only controls. The Flare ID shown is
// the public handle the host passes; the account id is never shown.

const _labels = FlareContactDetailLabels();

Future<void> _pump(WidgetTester tester, FlareContactDetail detail) async {
  tester.view.physicalSize = const Size(320, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: detail)));
  expect(tester.takeException(), isNull);
}

List<String> _rowLabels(WidgetTester tester) => [
  for (final row in tester.widgetList<FlareSettingsRow>(
    find.byType(FlareSettingsRow),
  ))
    row.item.label,
];

Finder _button(String label) => find.widgetWithText(FlareButton, label);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  testWidgets('a stranger profile shows only the intents the host handles', (
    tester,
  ) async {
    var opens = 0;
    await _pump(
      tester,
      FlareContactDetail(
        contact: const FlareContact(id: 'u_lin', name: '林夏'),
        onMessage: () => opens++,
      ),
    );

    expect(find.byType(FlareButton), findsOneWidget);
    expect(_button(_labels.message), findsOneWidget);
    expect(find.text(_labels.voice), findsNothing);
    expect(find.text(_labels.video), findsNothing);
    expect(find.text(_labels.block), findsNothing);
    expect(find.text(_labels.remove), findsNothing);
    // No public handle and nothing else to show: no 资料 card at all, and the
    // account id appears nowhere.
    expect(find.byType(FlareSettingsList), findsNothing);
    expect(find.text('u_lin'), findsNothing);
    expect(find.byType(Switch), findsNothing);

    await _tap(tester, _button(_labels.message));
    expect(opens, 1);
  });

  testWidgets('without edit callbacks set values stay as read-only rows', (
    tester,
  ) async {
    await _pump(
      tester,
      const FlareContactDetail(
        contact: FlareContact(
          id: 'u_lin',
          name: '林夏',
          flareId: 'linxia',
          remark: '老林',
        ),
        description: '大学同学',
      ),
    );

    expect(find.byType(FlareButton), findsNothing, reason: 'no action row');
    expect(_rowLabels(tester), [
      _labels.flareId,
      _labels.remark,
      _labels.description,
    ]);
    expect(find.text('linxia'), findsOneWidget);
    expect(find.text('老林'), findsOneWidget);
    expect(find.text('大学同学'), findsOneWidget);
    expect(find.text(_labels.notSet), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    // The read-only rows take no taps.
    for (final ink in tester.widgetList<InkWell>(
      find.descendant(
        of: find.byType(FlareSettingsRow),
        matching: find.byType(InkWell),
      ),
    )) {
      expect(ink.onTap, isNull);
    }
  });

  testWidgets('a friend profile edits, stars and holds the danger zone', (
    tester,
  ) async {
    final events = <String>[];
    await _pump(
      tester,
      FlareContactDetail(
        contact: const FlareContact(id: 'u_lin', name: '林夏', flareId: 'linxia'),
        onMessage: () => events.add('message'),
        onEditRemark: () => events.add('remark'),
        onEditDescription: () => events.add('description'),
        onToggleStar: (value) => events.add('star $value'),
        onBlock: () => events.add('block'),
        onRemove: () => events.add('remove'),
      ),
    );

    expect(_rowLabels(tester), [
      _labels.flareId,
      _labels.remark,
      _labels.description,
      _labels.star,
    ]);
    expect(find.text('u_lin'), findsNothing);
    // Only the two editable rows navigate; unset values say so.
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    expect(find.text(_labels.notSet), findsNWidgets(2));
    expect(find.byType(Switch), findsOneWidget);
    expect(find.text(_labels.voice), findsNothing);
    expect(find.text(_labels.video), findsNothing);

    await _tap(tester, find.text(_labels.flareId));
    await _tap(tester, find.text(_labels.remark));
    await _tap(tester, find.text(_labels.description));
    await _tap(tester, find.text(_labels.star));
    await _tap(tester, _button(_labels.block));
    await _tap(tester, _button(_labels.remove));
    expect(events, ['remark', 'description', 'star true', 'block', 'remove']);
  });

  testWidgets('each action and danger button needs its own callback', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      FlareContactDetail(
        contact: const FlareContact(id: 'qa', name: 'QA Contact'),
        onCall: () => calls++,
        onVideo: () => calls++,
        onRemove: () {},
      ),
    );

    // Two actions share the narrow row without the message action.
    expect(find.text(_labels.message), findsNothing);
    expect(_button(_labels.voice), findsOneWidget);
    expect(_button(_labels.video), findsOneWidget);
    expect(_button(_labels.remove), findsOneWidget);
    expect(find.text(_labels.block), findsNothing);
    await _tap(tester, _button(_labels.voice));
    await _tap(tester, _button(_labels.video));
    expect(calls, 2);
  });

  testWidgets('the profile card shows the public handle and handled actions', (
    tester,
  ) async {
    const strings = FlareStrings();
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: FlareProfileCard(
              user: FlareContact(id: 'u_lin', name: '林夏', region: '上海'),
            ),
          ),
        ),
      ),
    );
    expect(find.text('上海'), findsOneWidget);
    expect(find.textContaining('u_lin'), findsNothing);
    expect(find.textContaining(_labels.flareId), findsNothing);
    expect(find.bySemanticsLabel(strings.sendMessage), findsNothing);
    expect(find.bySemanticsLabel(strings.contactDetailVoice), findsNothing);

    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FlareProfileCard(
              user: const FlareContact(
                id: 'u_lin',
                name: '林夏',
                flareId: 'linxia',
                region: '上海',
              ),
              onMessage: () => calls++,
              onCall: () => calls++,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Flare ID · linxia · 上海'), findsOneWidget);
    for (final name in [strings.sendMessage, strings.contactDetailVoice]) {
      final node = tester.getSemantics(find.bySemanticsLabel(name));
      expect(
        node,
        isSemantics(isButton: true, hasTapAction: true),
        reason: name,
      );
      expect(node.rect.height, greaterThanOrEqualTo(FlareSizes.touchTarget));
      await tester.tap(find.bySemanticsLabel(name));
    }
    expect(find.bySemanticsLabel(strings.contactDetailVideo), findsNothing);
    expect(calls, 2);
    handle.dispose();
  });
}
