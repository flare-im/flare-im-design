import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';

void main() {
  test('Unicode and literal query highlighting preserves original text', () {
    for (final pair in [
      ('İX', 'x'),
      ('a.b[a.b', 'a.b'),
      ('👋HELLO', 'hello'),
      ('abc', '  '),
    ]) {
      final spans = FlareSearchResults.highlightSpans(
        pair.$1,
        pair.$2,
        baseColor: Colors.black,
        matchColor: Colors.blue,
      );
      expect(spans.map((s) => s.text).join(), pair.$1);
    }
    final spans = FlareSearchResults.highlightSpans(
      'İX',
      'x',
      baseColor: Colors.black,
      matchColor: Colors.blue,
    );
    expect(
      spans.where((s) => s.style?.fontWeight == FontWeight.w600).single.text,
      'X',
    );
  });
  testWidgets(
    'filter change hides stale results, retries the submitted criteria, fits large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const original = FlareSearchCriteria(query: '11', filterId: 'all');
      var snapshot = const FlareSearchSnapshot(
        criteria: original,
        state: FlareSearchState.success,
        groups: [
          FlareSearchResultGroup(
            kind: FlareSearchResultKind.message,
            label: '消息',
            items: [
              FlareSearchResultItem(
                id: '1',
                kind: FlareSearchResultKind.message,
                title: '旧文本结果',
              ),
            ],
          ),
        ],
      );
      final requests = <FlareSearchCriteria>[];
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    update = setState;
                    return FlareSearchPanel(
                      snapshot: snapshot,
                      filters: const {'all': '全部', 'file': '文件'},
                      onSearch: requests.add,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('旧文本结果'), findsOneWidget);
      await tester.tap(find.text('文件'));
      await tester.pump();
      expect(
        requests.single,
        const FlareSearchCriteria(query: '11', filterId: 'file'),
      );
      expect(find.text('旧文本结果'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      update(
        () => snapshot = FlareSearchSnapshot(
          criteria: requests.last,
          state: FlareSearchState.failure,
          error: '连接中断，请重试',
        ),
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, '搜索').last);
      await tester.pump();
      expect(requests.length, 2);
      expect(requests.first, requests.last);
      update(
        () => snapshot = FlareSearchSnapshot(
          criteria: requests.last,
          state: FlareSearchState.success,
          groups: const [
            FlareSearchResultGroup(
              kind: FlareSearchResultKind.message,
              label: '文件',
              items: [
                FlareSearchResultItem(
                  id: 'f',
                  kind: FlareSearchResultKind.message,
                  title: '报告11.pdf',
                ),
              ],
            ),
          ],
        ),
      );
      await tester.pump();
      expect(find.text('旧文本结果'), findsNothing);
      expect(find.byType(FlareSearchResults), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
