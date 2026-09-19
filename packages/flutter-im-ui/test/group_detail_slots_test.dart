import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _labels = FlareGroupDetailLabels();
const _afterInfo = ValueKey('after-info');
const _footer = ValueKey('footer');

const _model = FlareGroupDetailModel(
  groupId: 'g1',
  name: 'Team',
  memberCount: 2,
  members: [
    FlareContact(id: 'owner', name: 'Olivia'),
    FlareContact(id: 'u2', name: 'Bob'),
  ],
  ownerId: 'owner',
  canManage: true,
  isOwner: true,
);

Widget _host(FlareGroupDetail detail) =>
    MaterialApp(home: Scaffold(body: detail));

Finder get _page => find.byType(Scrollable).first;

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: _page);
  await tester.pumpAndSettle();
}

Future<void> _scrollToEnd(WidgetTester tester) async {
  final position = tester.state<ScrollableState>(_page).position;
  position.jumpTo(position.maxScrollExtent);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('afterInfo follows the group information section, inset like '
      'its card, and scrolls with the page', (tester) async {
    // Tall enough to lay the whole page out at once.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 2400);
    addTearDown(tester.view.reset);
    const detail = FlareGroupDetail(
      model: _model,
      afterInfo: SizedBox(key: _afterInfo, height: 40),
    );
    await tester.pumpWidget(_host(detail));
    final slot = find.byKey(_afterInfo);
    final rect = tester.getRect(slot);
    // After the last row of 群信息 (its member count row), before the next
    // section's title.
    final infoRow = find.ancestor(
      of: find.text(_labels.memberCount(2)),
      matching: find.byType(FlareSettingsRow),
    );
    expect(rect.top, greaterThan(tester.getBottomLeft(infoRow).dy));
    expect(
      rect.bottom,
      lessThan(tester.getTopLeft(find.text(_labels.myInGroup)).dy),
    );
    expect(rect.left, FlareSizes.spacingMd);
    expect(rect.right, 800 - FlareSizes.spacingMd);
    // The section cards share that inset.
    expect(tester.getTopLeft(infoRow).dx, rect.left);
    expect(tester.getTopRight(infoRow).dx, rect.right);

    expect(find.descendant(of: _page, matching: slot), findsOneWidget);
    tester.view.physicalSize = const Size(800, 600);
    await tester.pumpWidget(_host(detail));
    // Brought to the top of the page, the slot moves when the page does.
    await _reveal(tester, slot);
    final before = tester.getTopLeft(slot).dy;
    await tester.drag(_page, const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(slot).dy, greaterThan(before));
  });

  testWidgets('footer follows the message and leave buttons, inset like them', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        FlareGroupDetail(
          model: _model,
          onOpenChat: (_, _) {},
          footer: const SizedBox(key: _footer, height: 40),
        ),
      ),
    );
    await _scrollToEnd(tester);
    final slot = tester.getRect(find.byKey(_footer));
    final leave = tester.getRect(
      find.widgetWithText(FlareButton, _labels.dissolve),
    );
    final message = tester.getRect(
      find.widgetWithText(FlareButton, _labels.message),
    );
    expect(message.bottom, lessThanOrEqualTo(leave.top));
    expect(slot.top, greaterThanOrEqualTo(leave.bottom));
    expect(slot.left, FlareSizes.spacingLg);
    expect(slot.left, leave.left);
    expect(slot.right, leave.right);
    expect(
      find.descendant(of: _page, matching: find.byKey(_footer)),
      findsOneWidget,
    );
    // The page still ends a spacing below its last content.
    expect(
      tester.getRect(_page).bottom - slot.bottom,
      closeTo(FlareSizes.spacingLg, 0.01),
    );
  });

  testWidgets('empty slots draw nothing', (tester) async {
    await tester.pumpWidget(
      _host(FlareGroupDetail(model: _model, onOpenChat: (_, _) {})),
    );
    // The settings stay one list: nothing is spliced in after 群信息.
    expect(find.byType(FlareSettingsList), findsOneWidget);
    await _scrollToEnd(tester);
    final leave = tester.getRect(
      find.widgetWithText(FlareButton, _labels.dissolve),
    );
    // Nothing after the buttons but their own inset.
    expect(
      tester.getRect(_page).bottom - leave.bottom,
      closeTo(FlareSizes.spacingLg, 0.01),
    );
  });

  testWidgets('the message button is drawn only when the host opens chats', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const FlareGroupDetail(model: _model)));
    await _scrollToEnd(tester);
    expect(find.widgetWithText(FlareButton, _labels.message), findsNothing);
    expect(find.widgetWithText(FlareButton, _labels.dissolve), findsOneWidget);

    final opened = <(List<String>, String)>[];
    await tester.pumpWidget(
      _host(
        FlareGroupDetail(
          model: _model,
          onOpenChat: (ids, name) => opened.add((ids, name)),
        ),
      ),
    );
    await _scrollToEnd(tester);
    final message = find.widgetWithText(FlareButton, _labels.message);
    expect(message, findsOneWidget);
    await tester.tap(message);
    await tester.pump();
    expect(opened, hasLength(1));
    expect(opened.single.$1, ['owner', 'u2']);
    expect(opened.single.$2, 'Team');
  });
}
