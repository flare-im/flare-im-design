import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Behaviour mirrored from the Vue kit during the device comparison round.
void main() {
  testWidgets('a menu at a point opens from it towards the end', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late BuildContext host;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              host = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    const point = Offset(200, 100);
    FlareActionMenu.show(
      host,
      label: 'menu',
      anchor: Rect.fromLTWH(point.dx, point.dy, 0, 0),
      presentation: FlareActionMenuPresentation.anchored,
      items: const [FlareActionItem(id: 'pin', label: '置顶')],
    );
    await tester.pumpAndSettle();
    // Vue opens a secondary-click menu at x/y: its start edge at the pointer.
    expect(tester.getTopLeft(find.text('置顶')).dx, greaterThan(point.dx));
  });

  testWidgets('typing searches after a short pause, once', (tester) async {
    final searches = <FlareSearchCriteria>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareSearchPanel(
            snapshot: const FlareSearchSnapshot(
              criteria: FlareSearchCriteria(query: '', filterId: 'all'),
              state: FlareSearchState.idle,
            ),
            filters: const {'all': '全部', 'text': '文本'},
            onSearch: searches.add,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '签');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), '签到');
    await tester.pump(const Duration(milliseconds: 200));
    expect(searches, isEmpty);
    await tester.pump(const Duration(milliseconds: 150));
    expect(searches, [const FlareSearchCriteria(query: '签到', filterId: 'all')]);
  });
}
