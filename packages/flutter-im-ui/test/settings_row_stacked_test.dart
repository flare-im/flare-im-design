import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// FR-084 (K4): a value longer than 16 characters goes under the label on up
// to three lines; a shorter one stays at the end on one line; toggles never
// stack.

const _long = '发版当天所有问题统一在本群同步，线上告警请直接 @徐知远。';

Widget _row(FlareSettingsItem item, {double width = 360}) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: width,
      child: FlareSettingsRow(
        item: item,
        onSelect: (_) {},
        onToggle: (_, _) {},
      ),
    ),
  ),
);

void main() {
  test(
    'stacks after 16 characters, counting characters, never for toggles',
    () {
      FlareSettingsItem item(String detail, FlareSettingKind kind) =>
          FlareSettingsItem(key: 'k', label: '群公告', kind: kind, detail: detail);
      expect(
        FlareSettingsRow.stacks(item('2.0 发版协调', FlareSettingKind.value)),
        isFalse,
      );
      // 16 characters, one of them an emoji of two code units: not stacked.
      expect(
        FlareSettingsRow.stacks(
          item('一二三四五六七八九十一二三四五😀', FlareSettingKind.value),
        ),
        isFalse,
      );
      expect(
        FlareSettingsRow.stacks(
          item('一二三四五六七八九十一二三四五六七', FlareSettingKind.value),
        ),
        isTrue,
      );
      expect(
        FlareSettingsRow.stacks(item(_long, FlareSettingKind.navigation)),
        isTrue,
      );
      expect(
        FlareSettingsRow.stacks(item(_long, FlareSettingKind.toggle)),
        isFalse,
      );
    },
  );

  testWidgets('a long value sits under the label, three lines at most, in the '
      'secondary colour', (tester) async {
    await tester.pumpWidget(
      _row(
        const FlareSettingsItem(
          key: 'announcement',
          label: '群公告',
          icon: 'announcement',
          kind: FlareSettingKind.value,
          detail: '$_long$_long$_long$_long',
        ),
      ),
    );
    final label = tester.getRect(find.text('群公告'));
    final value = find.textContaining('发版当天');
    final valueRect = tester.getRect(value);
    expect(valueRect.top, greaterThanOrEqualTo(label.bottom));
    expect(valueRect.left, label.left, reason: 'aligned with the label');
    final text = tester.widget<Text>(value);
    expect(text.maxLines, 3);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(
      text.style?.color,
      FlareColors.resolve(Brightness.light).textSecondary,
    );
    // The label keeps its line.
    expect(label.height, lessThan(valueRect.height));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a short value stays at the end on one line and truncates '
      'instead of squeezing the label', (tester) async {
    await tester.pumpWidget(
      _row(
        const FlareSettingsItem(
          key: 'name',
          label: '群名称',
          kind: FlareSettingKind.navigation,
          // 16 characters: stays on the row, and does not fit at this width.
          detail: 'Coordination xyz',
        ),
        width: 160,
      ),
    );
    final label = tester.getRect(find.text('群名称'));
    final value = find.text('Coordination xyz');
    final valueRect = tester.getRect(value);
    expect(valueRect.top, lessThan(label.bottom));
    expect(valueRect.left, greaterThan(label.right));
    final text = tester.widget<Text>(value);
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    // At most 60% of the row: the label keeps the rest.
    expect(valueRect.width, lessThanOrEqualTo(160 * 0.6));
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a toggle with a long detail stays one row', (tester) async {
    await tester.pumpWidget(
      _row(
        const FlareSettingsItem(
          key: 'mute',
          label: '消息免打扰',
          kind: FlareSettingKind.toggle,
          value: true,
          detail: '这是一段很长很长很长很长的说明文字',
        ),
      ),
    );
    expect(find.byType(Switch), findsOneWidget);
    expect(find.textContaining('很长'), findsNothing);
  });
}
