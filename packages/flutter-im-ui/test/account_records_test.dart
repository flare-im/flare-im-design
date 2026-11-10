import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

FlarePluginPageViewModel records({
  bool separate = true,
  String? cursor,
  bool direct = false,
  bool confirm = false,
  bool mask = false,
}) => FlarePluginPageViewModel.fromJson({
  'available': true,
  'title': '记录',
  'data': {'revision': 9},
  if (cursor != null) 'nextCursor': cursor,
  if (mask)
    'fields': [
      {'label': '可用概览', 'value': '1000.00'},
    ],
  'actions': [
    {'id': 'more', 'label': '更多信息'},
  ],
  'inputs': [
    {
      'id': 'direction',
      'label': '资金方向',
      'kind': 'select',
      'choices': [
        {'value': 'credit', 'label': '收入'},
        {'value': 'debit', 'label': '支出'},
      ],
    },
    {
      'id': 'state',
      'label': '审核进度',
      'kind': 'select',
      'choices': [
        {'value': 'pending', 'label': '待审核'},
        {'value': 'done', 'label': '已完成'},
      ],
    },
  ],
  'blocks': [
    {
      'kind': 'rows',
      'filters': ['direction', 'state'],
      'columns': [
        {'label': '申请金额'},
        {'label': '业务'},
        {'label': '币种'},
        {'label': '创建时间', 'format': 'time'},
        {'label': '原因'},
      ],
      'rows': [
        {
          'key': 'record-01',
          'badge': {'text': '待审核', 'tone': 'warning'},
          'cells': [
            {'text': '-USD 12345678901234567890.001'},
            {'text': '提现'},
            {'text': 'USD'},
            {'text': '', 'timeMs': 1794099600000},
            {'text': '资料已提交'},
          ],
          'actions': [
            {
              'id': 'inspect',
              'input': {'recordId': 'opaque-01', 'revision': 3},
            },
          ],
        },
      ],
      'actions': [
        {'id': 'inspect', 'label': '查看原单', if (confirm) 'confirm': '核对原单'},
      ],
    },
  ],
  'presentation': {
    'renderer': 'account',
    'props': {
      'layout': 'ledger',
      'sectionTitle': '资金明细',
      'servicesTitle': '更多操作',
      if (separate) 'rowBadgePlacement': 'separate',
      'rowBadgeLabel': '审核状态',
      if (direct) 'rowEntryAction': 'inspect',
      'maskRowAmounts': mask,
    },
  },
});

Widget host(Widget body) => MaterialApp(home: Scaffold(body: body));
void surface(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget page(
  FlarePluginPageViewModel view, {
  Map<String, Object?> filters = const {},
  ValueChanged<Map<String, Object?>>? onFilter,
  FlarePluginPageActionCallback? onAction,
}) => FlarePluginPage(
  page: const FlarePluginPageRef(pluginId: 'fixture', page: 'records'),
  view: view,
  filters: filters,
  onFilter: onFilter,
  onAction: onAction,
);

void main() {
  test(
    'separate badge preserves business title while default badge semantics stay unchanged',
    () {
      final separate = flareAccountEntries(records()).single;
      expect(separate.title, '提现');
      expect(separate.subtitle, 'USD');
      expect(separate.amount, '-USD 12345678901234567890.001');
      final legacy = flareAccountEntries(records(separate: false)).single;
      expect(legacy.title, '待审核');
      expect(legacy.subtitle, '提现 · USD');
    },
  );

  testWidgets(
    'status is an independent tag and detail keeps amount label, metadata and row binding',
    (tester) async {
      surface(tester);
      final view = records();
      FlarePluginPageActionPayload? payload;
      await tester.pumpWidget(
        host(page(view, onAction: (_, p) => payload = p)),
      );
      await tester.pumpAndSettle();
      final entry = find.byKey(const ValueKey('account-entry:0/record-01'));
      expect(
        find.descendant(of: entry, matching: find.text('提现')),
        findsOneWidget,
      );
      final tag = find.descendant(of: entry, matching: find.byType(FlareTag));
      expect(tester.widget<FlareTag>(tag).tone, FlareStatusTone.warning);
      expect(
        find.descendant(of: entry, matching: find.text('待审核')),
        findsOneWidget,
      );
      final amount = find.descendant(
        of: entry,
        matching: find.text('-USD 12345678901234567890.001'),
      );
      expect(tester.widget<Text>(amount).maxLines, isNull);
      expect(
        tester.widget<Text>(amount).overflow,
        isNot(TextOverflow.ellipsis),
      );
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(find.text('申请金额'), findsOneWidget);
      expect(find.text('审核状态'), findsOneWidget);
      expect(find.text('创建时间'), findsOneWidget);
      expect(find.text('原因'), findsOneWidget);
      expect(find.text('资料已提交'), findsOneWidget);
      expect(find.text('1794099600000'), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('flare-plugin-action-inspect')),
      );
      await tester.pumpAndSettle();
      expect(payload!.row!.key, 'record-01');
      expect(payload!.row!.input, {'recordId': 'opaque-01', 'revision': 3});
      expect(payload!.data, {'revision': 9});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'declared row entry emits only its current original binding directly',
    (tester) async {
      surface(tester);
      String? action;
      FlarePluginPageActionPayload? payload;
      await tester.pumpWidget(
        host(
          page(
            records(direct: true),
            onAction: (id, p) {
              action = id;
              payload = p;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(payload, isNull);
      await tester.tap(find.byKey(const ValueKey('account-entry:0/record-01')));
      await tester.pumpAndSettle();
      expect(action, 'inspect');
      expect(payload!.row!.key, 'record-01');
      expect(payload!.row!.input, {'recordId': 'opaque-01', 'revision': 3});
      expect(payload!.data, {'revision': 9});
      expect(find.text('审核状态'), findsNothing);
    },
  );

  testWidgets(
    'row entry with confirmation retains local detail and the guarded runner',
    (tester) async {
      surface(tester);
      var calls = 0;
      await tester.pumpWidget(
        host(
          page(
            records(direct: true, confirm: true),
            onAction: (_, _) => calls++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account-entry:0/record-01')));
      await tester.pumpAndSettle();
      expect(find.text('审核状态'), findsOneWidget);
      expect(calls, 0);
      await tester.tap(
        find.byKey(const ValueKey('flare-plugin-action-inspect')),
      );
      await tester.pumpAndSettle();
      expect(find.text('核对原单'), findsOneWidget);
      expect(calls, 0);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(calls, 0);
    },
  );

  testWidgets('maskRowAmounts is respected in the local record detail', (
    tester,
  ) async {
    surface(tester);
    await tester.pumpWidget(
      host(page(records(mask: true), onAction: (_, _) {})),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is FlareIconButton && widget.semanticLabel == '隐藏余额',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('-USD 12345678901234567890.001'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('account-entry:0/record-01')));
    await tester.pumpAndSettle();
    expect(find.text('-USD 12345678901234567890.001'), findsNothing);
    expect(find.text('申请金额'), findsOneWidget);
    expect(find.text('••••'), findsWidgets);
  });

  testWidgets(
    'each server filter has a visible label and emits the full query without local filtering',
    (tester) async {
      surface(tester);
      Map<String, Object?>? chosen;
      await tester.pumpWidget(
        host(
          page(
            records(),
            filters: const {'state': 'pending'},
            onFilter: (f) => chosen = f,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('资金方向'), findsOneWidget);
      expect(find.text('审核进度'), findsOneWidget);
      final tabs = tester.widget<FlareFilterTabs>(
        find.byKey(FlarePluginPage.filterKey('direction')),
      );
      tabs.onSelect.call('credit');
      expect(chosen, {'state': 'pending', 'direction': 'credit'});
      expect(
        find.byKey(const ValueKey('account-entry:0/record-01')),
        findsOneWidget,
      );
    },
  );

  testWidgets('ledger records precede secondary services', (tester) async {
    surface(tester);
    await tester.pumpWidget(host(page(records(), onAction: (_, _) {})));
    await tester.pumpAndSettle();
    final entry = find.byKey(const ValueKey('account-entry:0/record-01'));
    final services = find.byKey(const ValueKey('flare-account-services'));
    expect(
      tester.getBottomLeft(entry).dy,
      lessThanOrEqualTo(tester.getTopLeft(services).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'same-frame repeated query errors release only the page cursor guard',
    (tester) async {
      surface(tester);
      var requests = 0;
      String? error;
      late StateSetter rebuild;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return FlarePluginPage(
                page: const FlarePluginPageRef(
                  pluginId: 'fixture',
                  page: 'records',
                ),
                view: records(cursor: 'next'),
                error: error,
                actionError: '原操作失败',
                busyActionId: 'operation',
                settleToken: 7,
                onLoadMore: (_) {
                  requests++;
                  rebuild(() => error = '分页失败');
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var count = 1; count <= 2; count++) {
        await tester.tap(find.byKey(FlarePluginPage.loadMoreKey));
        await tester.pump();
        expect(requests, count);
        expect(
          tester
              .widget<FlareButton>(find.byKey(FlarePluginPage.loadMoreKey))
              .loading,
          isFalse,
        );
        final account = tester.widget<FlareAccountView>(
          find.byType(FlareAccountView),
        );
        expect(account.busyActionId, 'operation');
        expect(account.settleToken, 7);
        expect(account.error, '原操作失败');
      }
    },
  );

  testWidgets(
    'loaded query error retries through the shared banner while retaining financial state',
    (tester) async {
      surface(tester);
      var refreshes = 0;
      var refreshing = false;
      late StateSetter rebuild;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return FlarePluginPage(
                page: const FlarePluginPageRef(
                  pluginId: 'fixture',
                  page: 'records',
                ),
                view: records(),
                error: '记录读取失败',
                refreshing: refreshing,
                busyActionId: 'operation',
                settleToken: 7,
                actionError: '原操作失败',
                onRefresh: () => refreshes++,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final banner = tester.widget<FlareStatusBanner>(
        find.byKey(FlarePluginPage.bannerKey),
      );
      expect(banner.actionText, '重试');
      banner.onAction!();
      expect(refreshes, 1);
      expect(
        find.byKey(const ValueKey('account-entry:0/record-01')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FlareAccountView>(find.byType(FlareAccountView))
            .busyActionId,
        'operation',
      );
      expect(
        tester
            .widget<FlareAccountView>(find.byType(FlareAccountView))
            .settleToken,
        7,
      );
      rebuild(() => refreshing = true);
      await tester.pump();
      final pending = tester.widget<FlareStatusBanner>(
        find.byKey(FlarePluginPage.bannerKey),
      );
      expect(pending.actionText, isNull);
      expect(pending.onAction, isNull);
    },
  );

  testWidgets(
    'refresh disables the paging footer without clearing financial busy',
    (tester) async {
      surface(tester);
      var requests = 0;
      await tester.pumpWidget(
        host(
          FlarePluginPage(
            page: const FlarePluginPageRef(
              pluginId: 'fixture',
              page: 'records',
            ),
            view: records(cursor: 'next'),
            refreshing: true,
            busyActionId: 'operation',
            onLoadMore: (_) => requests++,
          ),
        ),
      );
      await tester.pump();
      final footer = tester.widget<FlareButton>(
        find.byKey(FlarePluginPage.loadMoreKey),
      );
      expect(footer.disabled, isTrue);
      footer.onPressed?.call();
      expect(requests, 0);
      expect(
        tester
            .widget<FlareAccountView>(find.byType(FlareAccountView))
            .busyActionId,
        'operation',
      );
    },
  );

  testWidgets(
    'paging token releases fast repeated completion with unchanged loading and errors',
    (tester) async {
      surface(tester);
      var pagingToken = 0;
      var requests = 0;
      late StateSetter rebuild;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return FlarePluginPage(
                page: const FlarePluginPageRef(
                  pluginId: 'fixture',
                  page: 'records',
                ),
                view: records(cursor: 'next'),
                pagingToken: pagingToken,
                actionError: '原操作失败',
                busyActionId: 'operation',
                settleToken: 7,
                onLoadMore: (_) {
                  requests++;
                  rebuild(() => pagingToken++);
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var count = 1; count <= 2; count++) {
        await tester.tap(find.byKey(FlarePluginPage.loadMoreKey));
        await tester.pump();
        expect(requests, count);
        expect(
          tester
              .widget<FlareButton>(find.byKey(FlarePluginPage.loadMoreKey))
              .loading,
          isFalse,
        );
        final account = tester.widget<FlareAccountView>(
          find.byType(FlareAccountView),
        );
        expect(account.busyActionId, 'operation');
        expect(account.settleToken, 7);
        expect(account.error, '原操作失败');
      }
    },
  );
}
