import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// FlarePluginPage (spec Layout/PluginPage): the full-screen host of a
/// plugin's page contribution — header with back, the view drawn embedded,
/// pull to refresh, load more asked once per cursor.
FlarePluginViewModel wallet({String? cursor}) => FlarePluginViewModel.fromJson({
  'available': true,
  'title': '钱包',
  'fields': [
    {'label': '可用余额', 'value': '¥12.00'},
  ],
  'blocks': [
    {
      'kind': 'entries',
      'numbered': false,
      'total': 2,
      'more': false,
      'items': [
        {'index': 1, 'text': '收到红包 +¥2.30'},
        {'index': 2, 'text': '发出红包 -¥10.00'},
      ],
    },
  ],
  'nextCursor': ?cursor,
});

Widget host(Widget page) => MaterialApp(home: Scaffold(body: page));

void main() {
  testWidgets('the first load spins; a failure offers a retry', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(host(const FlarePluginPage(title: '钱包')));
    expect(find.byKey(FlarePluginPage.loadingKey), findsOneWidget);
    expect(find.text('钱包'), findsOneWidget);
    await tester.pumpWidget(
      host(FlarePluginPage(title: '钱包', error: '加载失败', onRetry: () => retries++)),
    );
    expect(find.byKey(FlarePluginPage.errorKey), findsOneWidget);
    await tester.tap(find.byKey(FlarePluginPage.retryKey));
    expect(retries, 1);
  });

  testWidgets('the view is drawn embedded under the page title and back key', (
    tester,
  ) async {
    var backs = 0;
    await tester.pumpWidget(
      host(FlarePluginPage(view: wallet(), onBack: () => backs++)),
    );
    expect(find.text('钱包'), findsOneWidget);
    expect(find.text('¥12.00'), findsOneWidget);
    expect(find.text('收到红包 +¥2.30'), findsOneWidget);
    final view = tester.widget<FlarePluginView>(find.byType(FlarePluginView));
    expect(view.embedded, isTrue);
    // No card shell: the page is the surface.
    expect(find.byKey(const ValueKey('flare-plugin-card')), findsNothing);
    await tester.tap(find.byIcon(Icons.arrow_back));
    expect(backs, 1);
    // Nothing the view does not declare: no load more on the last page.
    expect(find.byKey(FlarePluginPage.loadMoreKey), findsNothing);
  });

  testWidgets('load more asks once per cursor and again after it settles', (
    tester,
  ) async {
    final asked = <String>[];
    Widget page({bool loadingMore = false, String cursor = 'c1'}) => host(
      FlarePluginPage(
        view: wallet(cursor: cursor),
        loadingMore: loadingMore,
        onLoadMore: asked.add,
      ),
    );
    await tester.pumpWidget(page());
    await tester.tap(find.byKey(FlarePluginPage.loadMoreKey));
    await tester.pump();
    await tester.tap(find.byKey(FlarePluginPage.loadMoreKey));
    expect(asked, ['c1']);
    await tester.pumpWidget(page(loadingMore: true));
    await tester.pumpWidget(page());
    await tester.tap(find.byKey(FlarePluginPage.loadMoreKey));
    expect(asked, ['c1', 'c1']);
    await tester.pumpWidget(page(cursor: 'c2'));
    await tester.tap(find.byKey(FlarePluginPage.loadMoreKey));
    expect(asked, ['c1', 'c1', 'c2']);
  });

  testWidgets('a pull refreshes until the host says it is done', (
    tester,
  ) async {
    var refreshes = 0;
    var refreshing = false;
    late StateSetter update;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return FlarePluginPage(
              view: wallet(),
              refreshing: refreshing,
              onRefresh: () => setState(() {
                refreshes++;
                refreshing = true;
              }),
            );
          },
        ),
      ),
    );
    await tester.fling(find.text('¥12.00'), const Offset(0, 400), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(refreshes, 1);
    // The indicator stays while the host's refresh runs…
    expect(find.byType(RefreshProgressIndicator), findsOneWidget);
    // …and goes once it is done.
    update(() => refreshing = false);
    await tester.pumpAndSettle();
    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });

  testWidgets(
    'pointer devices get a refresh key in the header',
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    (tester) async {
      var refreshes = 0;
      await tester.pumpWidget(
        host(FlarePluginPage(view: wallet(), onRefresh: () => refreshes++)),
      );
      await tester.tap(find.byKey(FlarePluginPage.refreshKey));
      expect(refreshes, 1);
    },
  );

  testWidgets('actions on the page reach the host with the view settling', (
    tester,
  ) async {
    final calls = <String>[];
    await tester.pumpWidget(
      host(
        FlarePluginPage(
          view: FlarePluginViewModel.fromJson({
            'available': true,
            'title': '钱包',
            'actions': [
              {'id': 'history', 'label': '明细'},
            ],
          }),
          onAction: (id, _) => calls.add(id),
        ),
      ),
    );
    await tester.tap(find.text('明细'));
    expect(calls, ['history']);
  });
}
