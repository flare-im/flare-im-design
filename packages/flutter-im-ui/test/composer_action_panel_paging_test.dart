import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The "+" panel pages on a phone (rows × columns per page, page dots) and
// shows at most three scrolling rows on a desktop; a new list keeps the page.
Widget _host(Widget child) => MaterialApp(
  home: FlareStringsScope(
    strings: const FlareStrings(),
    child: Scaffold(
      body: Align(alignment: Alignment.topCenter, child: child),
    ),
  ),
);

List<FlareComposerAction> _actions(int count, {String prefix = 'a'}) => [
  for (var i = 0; i < count; i++)
    FlareComposerAction(id: '$prefix$i', label: '$prefix$i', icon: 'plugin'),
];

int _tiles(WidgetTester tester) => tester
    .widgetList(
      find.descendant(
        of: find.byType(FlareComposerActionPanel),
        matching: find.byType(InkWell),
      ),
    )
    .length;

Iterable<Key> _dots(WidgetTester tester) => tester
    .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
    .map((dot) => dot.key)
    .whereType<Key>();

double _dotWidth(WidgetTester tester, int index) => tester
    .widget<AnimatedContainer>(
      find.byKey(ValueKey('flare-action-panel-dot-$index')),
    )
    .constraints!
    .maxWidth;

void main() {
  testWidgets('a phone pages eight tiles at a time with page dots', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(FlareComposerActionPanel(actions: _actions(11))),
    );
    expect(_tiles(tester), 8);
    expect(find.text('a7'), findsOneWidget);
    expect(find.text('a8'), findsNothing);
    expect(_dots(tester), hasLength(2));
    expect(_dotWidth(tester, 0), 12);
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('a8'), findsOneWidget);
    expect(find.text('a10'), findsOneWidget);
    expect(_dotWidth(tester, 1), 12);
  });

  testWidgets('one page draws no dots, and rows and columns are the host\'s', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(FlareComposerActionPanel(actions: _actions(8))),
    );
    expect(_dots(tester), isEmpty);
    await tester.pumpWidget(
      _host(
        FlareComposerActionPanel(
          actions: _actions(8),
          rows: 1,
          crossAxisCount: 5,
        ),
      ),
    );
    expect(_tiles(tester), 5);
    expect(_dots(tester), hasLength(2));
  });

  testWidgets('a desktop shows every tile in at most three scrolling rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        FlareComposerActionPanel(
          actions: _actions(17),
          formFactor: FlareComposerPanelFormFactor.desktop,
        ),
      ),
    );
    expect(find.byType(PageView), findsNothing);
    expect(_dots(tester), isEmpty);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    final scroller = tester.getSize(find.byType(SingleChildScrollView));
    expect(
      scroller.height,
      3 * FlareComposerActionPanel.rowExtent + 2 * FlareSizes.spacingLg,
    );
    await tester.scrollUntilVisible(
      find.text('a16'),
      100,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('a16'), findsOneWidget);
  });

  testWidgets('a new list keeps the page, and clamps when pages go away', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(FlareComposerActionPanel(actions: _actions(12))),
    );
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('a8'), findsOneWidget);
    await tester.pumpWidget(
      _host(FlareComposerActionPanel(actions: _actions(12).sublist(1))),
    );
    await tester.pumpAndSettle();
    expect(find.text('a9'), findsOneWidget);
    expect(_dotWidth(tester, 1), 12);
    await tester.pumpWidget(
      _host(FlareComposerActionPanel(actions: _actions(4))),
    );
    await tester.pumpAndSettle();
    expect(find.text('a0'), findsOneWidget);
    expect(_dots(tester), isEmpty);
  });

  testWidgets('a tile that appears fades in, the ones already there do not', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(FlareComposerActionPanel(actions: _actions(2))),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      _host(
        FlareComposerActionPanel(
          actions: [
            ..._actions(2),
            ..._actions(1, prefix: 'new'),
          ],
        ),
      ),
    );
    FadeTransition fade(String label) => tester.widget<FadeTransition>(
      find
          .ancestor(of: find.text(label), matching: find.byType(FadeTransition))
          .first,
    );
    expect(fade('a0').opacity.value, 1);
    expect(fade('new0').opacity.value, 0);
    await tester.pump(FlareMotion.fast);
    expect(fade('new0').opacity.value, 1);
  });

  testWidgets('the composer hides "+" when its menu is empty', (tester) async {
    Widget composer(List<FlareComposerAction> actions) =>
        _host(SizedBox(width: 390, child: FlareComposer(actions: actions)));
    await tester.pumpWidget(composer(_actions(1)));
    expect(find.byTooltip('更多'), findsOneWidget);
    await tester.pumpWidget(composer(const []));
    expect(find.byTooltip('更多'), findsNothing);
  });
}
