import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// A settings row can carry a count badge (pending requests on an entry) and
// mark the entry whose pane is on screen beside it (an entry rail): the count
// follows spec/count-badge-vectors.json, as a filter tab's badge does.

Widget _row(FlareSettingsItem item) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 360,
      child: FlareSettingsRow(item: item, onSelect: (_) {}),
    ),
  ),
);

final _count = find.byKey(const ValueKey('flare-settings-row-count'));

void main() {
  testWidgets('a count badge sits between the value and the chevron', (
    tester,
  ) async {
    await tester.pumpWidget(
      _row(
        const FlareSettingsItem(
          key: 'groups',
          label: '群聊',
          detail: '12',
          badgeCount: 3,
        ),
      ),
    );
    expect(_count, findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    final value = tester.getRect(find.text('12'));
    final badge = tester.getRect(_count);
    final chevron = tester.getRect(find.byIcon(Icons.chevron_right));
    expect(badge.left, greaterThanOrEqualTo(value.right));
    expect(badge.right, lessThanOrEqualTo(chevron.left));
    // The count replaces the dot: one signal, not two.
    expect(find.bySemanticsLabel(RegExp('有新内容')), findsNothing);
  });

  testWidgets('more than the count reads 99+, as every count badge does', (
    tester,
  ) async {
    await tester.pumpWidget(
      _row(
        const FlareSettingsItem(
          key: 'requests',
          label: '新的好友',
          badgeCount: 40,
          badgeMore: true,
        ),
      ),
    );
    expect(find.text('99+'), findsOneWidget);
  });

  test('a zero count, a toggle and the default draw no count badge', () {
    expect(
      FlareSettingsRow.drawsCountBadge(
        const FlareSettingsItem(key: 'groups', label: '群聊', badgeCount: 0),
      ),
      isFalse,
    );
    expect(
      FlareSettingsRow.drawsCountBadge(
        const FlareSettingsItem(
          key: 'mute',
          label: '免打扰',
          kind: FlareSettingKind.toggle,
          badgeCount: 2,
        ),
      ),
      isFalse,
    );
    expect(
      FlareSettingsRow.drawsCountBadge(
        const FlareSettingsItem(key: 'about', label: '关于'),
      ),
      isFalse,
    );
  });

  testWidgets('the current entry is drawn and announced as selected', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _row(const FlareSettingsItem(key: 'friends', label: '好友', current: true)),
    );
    final colors = FlareColors.of(
      tester.element(find.byType(FlareSettingsRow)),
    );
    final surface = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(FlareSettingsRow),
            matching: find.byType(Container),
          )
          .first,
    );
    expect((surface.decoration as BoxDecoration?)?.color, colors.bgSelected);
    expect(
      tester.getSemantics(find.byType(FlareSettingsRow)),
      isSemantics(isSelected: true),
    );
    handle.dispose();
  });
}
