import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';

// DoD 21 / 22 — 图标默认是装饰性的：装在已有标签的控件里时不进语义树，
// 只有它自己就是内容时才带名字。四端同一条规则（Vue ariaLabel / Compose
// contentDescription / SwiftUI accessibilityLabel）。
void main() {
  testWidgets('a decorative icon stays out of the semantics tree', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FlareIcon('search'))),
    );

    expect(
      find.bySemanticsLabel('search'),
      findsNothing,
      reason: '装饰性图标不能把图标 id 念出来',
    );
    handle.dispose();
  });

  testWidgets('a named icon carries its own accessible name', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FlareIcon('search', semanticLabel: 'Search')),
      ),
    );

    expect(find.bySemanticsLabel('Search'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a labelled control is announced once, not twice', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Semantics(
            label: 'Clear search',
            button: true,
            child: GestureDetector(
              onTap: () {},
              child: const FlareIcon('close'),
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Clear search'), findsOneWidget);
    expect(find.bySemanticsLabel('close'), findsNothing);
    handle.dispose();
  });
}
