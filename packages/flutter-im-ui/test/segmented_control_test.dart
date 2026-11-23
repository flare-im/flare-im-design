import 'dart:ui' show SemanticsRole;

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// §4.7: a tab list — one focus stop, arrows move the selection, tab roles.

const _options = ['收到的', '发出的', '待确认'];

Widget _host({
  int initial = 0,
  bool enabled = true,
  TextDirection direction = TextDirection.ltr,
  bool reduceMotion = false,
  List<int>? picks,
}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => FlareSegmentedControl(
              options: _options,
              selectedIndex: picks == null || picks.isEmpty
                  ? initial
                  : picks.last,
              onSelect: enabled ? (i) => setState(() => picks?.add(i)) : null,
            ),
          ),
        ),
      ),
    ),
  ),
);

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

void main() {
  testWidgets('a tab bar of tabs, the selected one marked', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(initial: 1));
    for (final (i, label) in _options.indexed) {
      final node = tester.getSemantics(find.bySemanticsLabel(label));
      expect(node.getSemanticsData().role, SemanticsRole.tab);
      expect(
        node,
        isSemantics(
          label: label,
          isButton: true,
          isSelected: i == 1,
          hasTapAction: true,
        ),
      );
      expect(node.parent!.getSemanticsData().role, SemanticsRole.tabBar);
    }
    handle.dispose();
  });

  testWidgets('one focus stop; arrows wrap, Home and End jump', (tester) async {
    final picks = <int>[];
    await tester.pumpWidget(_host(picks: picks));
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    await _key(tester, LogicalKeyboardKey.home);
    await _key(tester, LogicalKeyboardKey.end);
    expect(picks, [1, 2, 0, 2, 0, 2]);
    // The keyboard's place carries a ring that does not move the label.
    final rings = tester
        .widgetList<AnimatedContainer>(
          find.descendant(
            of: find.byType(FlareSegmentedControl),
            matching: find.byType(AnimatedContainer),
          ),
        )
        .map((c) => c.foregroundDecoration != null)
        .toList();
    expect(rings, [false, false, true]);
  });

  testWidgets('arrows follow reading order right to left', (tester) async {
    final picks = <int>[];
    await tester.pumpWidget(_host(picks: picks, direction: TextDirection.rtl));
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(picks, [1, 0]);
  });

  testWidgets('without onSelect it takes no focus and no keys', (tester) async {
    final picks = <int>[];
    await tester.pumpWidget(_host(enabled: false, picks: picks));
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(picks, isEmpty);
  });

  testWidgets('the chip moves in FlareMotion.fast, at once when reduced', (
    tester,
  ) async {
    Duration duration() => tester
        .widget<AnimatedContainer>(
          find
              .descendant(
                of: find.byType(FlareSegmentedControl),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        )
        .duration;
    await tester.pumpWidget(_host());
    expect(duration(), FlareMotion.fast);
    await tester.pumpWidget(_host(reduceMotion: true));
    expect(duration(), Duration.zero);
  });
}
