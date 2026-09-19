import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// B5.2 (FR-084, X23): a settings row is a control only when it does something.
// `navigation` opens a page or picker (button + chevron), `toggle` is a switch,
// `action` runs in place (button, no chevron), `value` is read-only
// information — not a button, no chevron, and a tap does nothing.

const _long = '发版当天所有问题统一在本群同步，线上告警请直接 @徐知远。';

Widget _row(
  FlareSettingsItem item, {
  ValueChanged<FlareSettingsItem>? onSelect,
}) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 360,
      child: FlareSettingsRow(
        item: item,
        onSelect: onSelect ?? (_) {},
        onToggle: (_, _) {},
      ),
    ),
  ),
);

SemanticsNode _rowSemantics(WidgetTester tester) =>
    tester.getSemantics(find.byType(FlareSettingsRow));

IconData get _chevron => Icons.chevron_right;

void main() {
  testWidgets('a value row is not a control: no tap, no button role', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final selected = <String>[];
    await tester.pumpWidget(
      _row(
        const FlareSettingsItem(
          key: 'gateway',
          label: '网关地址',
          icon: 'info',
          kind: FlareSettingKind.value,
          detail: 'wss://im.example',
        ),
        onSelect: (item) => selected.add(item.key),
      ),
    );
    expect(find.byIcon(_chevron), findsNothing);
    expect(find.byType(InkWell), findsNothing);
    final node = _rowSemantics(tester);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    expect(
      node.getSemanticsData().flagsCollection.isButton,
      isFalse,
      reason: 'information must not announce as an action',
    );
    // Label and value read as one thing.
    expect(node.getSemanticsData().label, contains('网关地址'));
    expect(node.getSemanticsData().label, contains('wss://im.example'));
    await tester.tap(find.byType(FlareSettingsRow), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
    handle.dispose();
  });

  testWidgets('an action row is a button with no chevron', (tester) async {
    final selected = <String>[];
    await tester.pumpWidget(
      _row(
        const FlareSettingsItem(
          key: 'logout',
          label: '退出登录',
          icon: 'logout',
          kind: FlareSettingKind.action,
          danger: true,
        ),
        onSelect: (item) => selected.add(item.key),
      ),
    );
    expect(find.byIcon(_chevron), findsNothing);
    expect(find.byType(InkWell), findsOneWidget);
    // Destructive steps keep the danger colour.
    final label = tester.widget<Text>(find.text('退出登录'));
    expect(label.style?.color, isNotNull);
    await tester.tap(find.byType(FlareSettingsRow));
    await tester.pumpAndSettle();
    expect(selected, ['logout']);
  });

  testWidgets('a navigation row keeps its chevron and its tap', (tester) async {
    final selected = <String>[];
    await tester.pumpWidget(
      _row(
        const FlareSettingsItem(key: 'privacy', label: '隐私', icon: 'lock'),
        onSelect: (item) => selected.add(item.key),
      ),
    );
    expect(find.byIcon(_chevron), findsOneWidget);
    await tester.tap(find.byType(FlareSettingsRow));
    await tester.pumpAndSettle();
    expect(selected, ['privacy']);
  });

  testWidgets('a long value still stacks under the label, in every kind that '
      'carries one', (tester) async {
    for (final kind in const [
      FlareSettingKind.value,
      FlareSettingKind.action,
      FlareSettingKind.navigation,
    ]) {
      await tester.pumpWidget(
        _row(
          FlareSettingsItem(
            key: 'announcement',
            label: '群公告',
            icon: 'announcement',
            kind: kind,
            detail: _long,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final label = tester.getRect(find.text('群公告'));
      final value = tester.getRect(find.text(_long));
      expect(value.top, greaterThanOrEqualTo(label.bottom), reason: '$kind');
      expect(value.left, label.left, reason: '$kind');
    }
  });
}
