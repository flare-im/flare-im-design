import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The 2026-11-19 fixes of docs/plugin-experience.md §12 on the Flutter
/// plugin page: the derived account (R12, §5.1, §5.2), the filtered empty
/// list and the 64 record row (§5.8), the status card's journal banner and
/// the step position (§6.1, §12.5), the card header (R5), the one PC
/// breakpoint and the form column (G-14).
const zh = FlareStrings();

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void surface(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

const ref = FlarePluginPageRef(pluginId: 'p', page: 'home');

/// The wallet home's structure: a maskable hero in a section, one rows
/// block of wallets, grouped destinations, a create action and its progress.
FlarePluginPageViewModel wallet({
  bool empty = false,
  bool two = false,
  bool keys = true,
}) => FlarePluginPageViewModel.fromJson({
  'available': true,
  'title': '钱包',
  'blocks': [
    {
      'kind': 'section',
      'label': '余额钱包',
      'blocks': [
        {
          'kind': 'hero',
          'label': '可用余额',
          'value': '¥1,000.00',
          'amount': true,
          'maskable': true,
          'tone': 'neutral',
        },
      ],
    },
    {
      'kind': 'rows',
      'columns': [
        {'label': '余额'},
        {'label': '钱包'},
        {'label': '资金类型与币种'},
        {'label': '状态'},
      ],
      'actions': [
        {
          'id': 'wallet',
          'label': '查看明细',
          'target': {'kind': 'page', 'page': 'p.wallet'},
        },
      ],
      'rows': [
        if (!empty)
          for (final (key, amount, name, kind) in [
            ('w1', '¥1,000.00', '零钱钱包', 'CNY · cash'),
            if (two) ('w2', r'$88.50', '旅行钱包', 'USD · cash'),
          ])
            {
              'key': key,
              'cells': [
                {'text': amount},
                {'text': name},
                {'text': kind},
                {'text': '正常', 'tone': 'success'},
              ],
              'actions': [
                {
                  'id': 'wallet',
                  'input': {'walletId': key},
                },
              ],
            },
      ],
    },
  ],
  'actions': [
    if (keys) ...[
      {
        'id': 'recharge',
        'label': '充值',
        'style': 'primary',
        'target': {'kind': 'page', 'page': 'p.recharge'},
      },
      {
        'id': 'withdrawal',
        'label': '提现',
        'style': 'primary',
        'target': {'kind': 'page', 'page': 'p.withdrawal'},
      },
    ],
    {
      'id': 'history',
      'label': '交易记录',
      'group': 'common',
      'icon': 'clock',
      'target': {'kind': 'page', 'page': 'p.history'},
    },
    {
      'id': 'security',
      'label': '支付密码',
      'group': 'records',
      'icon': 'lock',
      'target': {'kind': 'page', 'page': 'p.security'},
    },
    {
      'id': 'openings',
      'label': '开户进度',
      'group': 'records',
      'target': {'kind': 'page', 'page': 'p.openings'},
    },
    {
      'id': 'create',
      'label': '开户',
      'style': 'primary',
      'target': {'kind': 'operation', 'operation': 'create'},
      'form': ['name'],
    },
    {
      'id': 'close',
      'label': '关闭钱包',
      'style': 'danger',
      'target': {'kind': 'operation', 'operation': 'close'},
    },
  ],
  'inputs': [
    {'id': 'name', 'label': '钱包标识', 'kind': 'text'},
  ],
});

void main() {
  testWidgets('a derived account draws the wallet layout: quick keys in the '
      'wallet card, grouped list cards, the danger card last (R12, R2.1, '
      '§12.23)', (tester) async {
    surface(tester, 390);
    await tester.pumpWidget(
      host(FlarePluginPage(page: ref, view: wallet(), onAction: (_, _) {})),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FlareAccountView), findsOneWidget);
    // P-01: never a row of text keys.
    expect(
      find.byWidgetPredicate(
        (w) => w is FlareButton && w.appearance == FlareButtonAppearance.text,
      ),
      findsNothing,
    );
    // §12.23: converted to the wallet presentation first (Vue
    // flareAccountDocument): no hero block; on a phone the wallet card
    // closes with the quick keys (the two primary page actions).
    expect(find.byKey(const ValueKey('flare-plugin-hero-value')), findsNothing);
    final card = find.byKey(
      ValueKey(
        'account-entry:${flareAccountEntries(flareAccountDocument(wallet())).single.id}',
      ),
    );
    final quick = find.descendant(
      of: card,
      matching: find.byKey(const ValueKey('flare-plugin-quick')),
    );
    for (final label in ['充值', '提现']) {
      expect(
        find.descendant(of: quick, matching: find.text(label)),
        findsOneWidget,
      );
    }
    expect(
      tester.getTopLeft(quick).dy,
      greaterThan(
        tester
            .getBottomLeft(
              find.descendant(of: card, matching: find.text('¥1,000.00')),
            )
            .dy,
      ),
    );
    final common = find.byKey(const ValueKey('flare-plugin-list-common'));
    final records = find.byKey(const ValueKey('flare-plugin-list-records'));
    final danger = find.byKey(const ValueKey('flare-plugin-list-danger'));
    expect(
      find.descendant(of: common, matching: find.text('交易记录')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: records, matching: find.text('支付密码')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: danger, matching: find.text('关闭钱包')),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(danger).dy,
      greaterThan(tester.getBottomLeft(records).dy),
    );
    expect(find.text(zh.pluginViewGroupCommon), findsOneWidget);
    expect(find.text(zh.pluginViewGroupRecords), findsOneWidget);
  });

  test('the derived document is the wallet presentation (R12, §12.23)', () {
    final view = wallet(two: true);
    final document = flareAccountDocument(view);
    expect(document.presentation, {
      'renderer': 'account',
      'props': {
        'layout': 'wallet',
        'summaryTitle': '余额钱包',
        'rowEntryAction': 'wallet',
      },
      'actions': {'primary': 'recharge', 'secondary': 'withdrawal'},
    });
    // The hero leads the fields; the head section is dropped.
    expect(document.fields.single.label, '可用余额');
    expect(document.fields.single.value, '¥1,000.00');
    expect(document.blocks.single, isA<FlarePluginRowsBlock>());
    expect(document.actions, view.actions);
    // A view with a presentation, or without the structure, is kept.
    final explicit = FlarePluginViewModel(
      available: true,
      title: '',
      blocks: view.blocks,
      presentation: const {'renderer': 'account'},
    );
    expect(identical(flareAccountDocument(explicit), explicit), isTrue);
    final plain = FlarePluginViewModel(
      available: true,
      title: '',
      blocks: [view.blocks.last],
    );
    expect(identical(flareAccountDocument(plain), plain), isTrue);
  });

  Finder walletCard(String key) => find.byKey(
    ValueKey(
      'account-entry:${flareAccountEntries(flareAccountDocument(wallet(two: true))).firstWhere((e) => e.row.key == key).id}',
    ),
  );
  Finder eye() => find.byWidgetPredicate(
    (w) => w is FlareIconButton && w.semanticLabel == zh.accountHideBalance,
  );

  testWidgets('PC wallet home: no title row, two equal card columns, one '
      'foot line, the quick keys with the eye at their end (§12.23)', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    surface(tester, 1280);
    await tester.pumpWidget(
      host(
        FlarePluginPage(
          page: ref,
          view: wallet(two: true),
          onAction: (_, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final summary = find.byKey(const ValueKey('flare-account-summary'));
    // The page header names the page; the section keeps its name for the
    // reader only.
    expect(find.text('余额钱包'), findsNothing);
    expect(find.bySemanticsLabel('余额钱包'), findsOneWidget);
    final first = tester.getRect(walletCard('w1'));
    final second = tester.getRect(walletCard('w2'));
    expect(second.top, first.top);
    expect(second.width, closeTo(first.width, 0.1));
    expect(second.left - first.right, closeTo(FlareSizes.spacingMd, 0.1));
    for (final key in ['w1', 'w2']) {
      final card = walletCard(key);
      expect(tester.getSize(card).height, lessThanOrEqualTo(160));
      // The wallet and its name, the balance; no balance label and no
      // plain details (资金类型与币种).
      expect(
        find.descendant(
          of: card,
          matching: find.byWidgetPredicate(
            (w) => w is FlareIcon && w.name == 'wallet',
          ),
        ),
        findsOneWidget,
      );
      for (final text in ['余额', '资金类型与币种', 'CNY · cash', 'USD · cash']) {
        expect(
          find.descendant(of: card, matching: find.text(text)),
          findsNothing,
        );
      }
      // One foot line: the status Tag · 查看明细 ›.
      final tag = find.descendant(of: card, matching: find.byType(FlareTag));
      final link = find.descendant(of: card, matching: find.text('查看明细'));
      expect(tester.widget<FlareTag>(tag).label, '正常');
      expect(tester.widget<FlareTag>(tag).tone, FlareStatusTone.success);
      expect(tester.getCenter(link).dy, closeTo(tester.getCenter(tag).dy, 1));
      expect(
        tester.getTopLeft(link).dx,
        greaterThan(tester.getTopRight(tag).dx),
      );
    }
    // Under the cards: the quick keys from the start (R2.1 PC), the eye at
    // the row's end.
    final row = find.byKey(const ValueKey('flare-account-quick-row'));
    expect(tester.getTopLeft(row).dy, greaterThan(first.bottom));
    final recharge = find.byKey(const ValueKey('flare-plugin-action-recharge'));
    final withdrawal = find.byKey(
      const ValueKey('flare-plugin-action-withdrawal'),
    );
    expect(find.descendant(of: row, matching: recharge), findsOneWidget);
    expect(
      tester.getTopLeft(recharge).dx,
      closeTo(tester.getTopLeft(summary).dx, 0.1),
    );
    for (final key in [recharge, withdrawal]) {
      expect(
        tester.getSize(key).width,
        greaterThanOrEqualTo(FlareSizes.componentActionMinWidth),
      );
    }
    expect(find.descendant(of: row, matching: eye()), findsOneWidget);
    expect(
      tester.getTopRight(eye()).dx,
      closeTo(tester.getTopRight(summary).dx, 0.1),
    );
    // The eye still hides every balance.
    await tester.tap(eye());
    await tester.pumpAndSettle();
    expect(find.text('¥1,000.00'), findsNothing);
    expect(find.text(r'$88.50'), findsNothing);
    semantics.dispose();
  });

  testWidgets('PC: a single wallet is one PC card, and the eye ends the row '
      'alone without quick keys (§12.23)', (tester) async {
    surface(tester, 1280);
    await tester.pumpWidget(
      host(
        FlarePluginPage(
          page: ref,
          view: wallet(keys: false),
          onAction: (_, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final summary = tester.getRect(
      find.byKey(const ValueKey('flare-account-summary')),
    );
    final card = walletCard('w1');
    expect(tester.getSize(card).width, closeTo(summary.width, 0.1));
    expect(find.descendant(of: card, matching: find.text('余额')), findsNothing);
    expect(find.byKey(const ValueKey('flare-plugin-quick')), findsNothing);
    final row = find.byKey(const ValueKey('flare-account-quick-row'));
    expect(find.descendant(of: row, matching: eye()), findsOneWidget);
    expect(tester.getTopRight(eye()).dx, closeTo(summary.right, 0.1));
  });

  testWidgets('phone wallet home is unchanged: the title row with the eye, '
      'the overview card with its details and keys, other wallets (§5.1)', (
    tester,
  ) async {
    surface(tester, 390);
    await tester.pumpWidget(
      host(
        FlarePluginPage(
          page: ref,
          view: wallet(two: true),
          onAction: (_, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final summary = find.byKey(const ValueKey('flare-account-summary'));
    expect(
      find.descendant(of: summary, matching: find.text('余额钱包')),
      findsOneWidget,
    );
    expect(find.descendant(of: summary, matching: eye()), findsOneWidget);
    expect(find.byKey(const ValueKey('flare-account-quick-row')), findsNothing);
    final card = walletCard('w1');
    for (final text in ['余额', 'CNY · cash', '充值', '提现']) {
      expect(
        find.descendant(of: card, matching: find.text(text)),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey('flare-account-other-wallets')),
      findsOneWidget,
    );
    expect(find.text('旅行钱包'), findsOneWidget);
  });

  for (final width in [390.0, 1280.0]) {
    testWidgets('no account yet draws the setup state at $width (§5.2)', (
      tester,
    ) async {
      surface(tester, width);
      final runs = <String>[];
      await tester.pumpWidget(
        host(
          FlarePluginPage(
            page: ref,
            view: wallet(empty: true),
            onAction: (id, _) => runs.add(id),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('flare-account-setup')), findsOneWidget);
      expect(find.text(zh.walletSetupTitle), findsOneWidget);
      expect(find.text(zh.walletSetupBody), findsOneWidget);
      // W-01: no balance and no top-up or withdrawal.
      expect(find.text('¥1,000.00'), findsNothing);
      expect(find.text('充值'), findsNothing);
      expect(find.text('提现'), findsNothing);
      final create = find.byKey(const ValueKey('flare-account-setup-create'));
      final progress = find.byKey(
        const ValueKey('flare-account-setup-openings'),
      );
      expect(progress, findsOneWidget);
      expect(
        tester.getSize(create).width,
        width >= FlareSizes.appShellCompactMinWidth
            ? FlareSizes.componentAccountSetupActionWidth
            : greaterThan(FlareSizes.componentAccountSetupActionWidth),
      );
      await tester.tap(progress);
      await tester.pumpAndSettle();
      expect(runs, ['openings']);
    });
  }

  testWidgets('an empty list under a chosen filter offers to clear it (§5.8)', (
    tester,
  ) async {
    surface(tester, 390);
    Map<String, Object?>? asked;
    await tester.pumpWidget(
      host(
        FlarePluginPage(
          page: ref,
          view: FlarePluginPageViewModel.fromJson({
            'available': true,
            'title': '记录',
            'inputs': [
              {
                'id': 'direction',
                'label': '方向',
                'kind': 'select',
                'choices': [
                  {'value': 'in', 'label': '收入'},
                ],
              },
            ],
            'blocks': [
              {
                'kind': 'rows',
                'filters': ['direction'],
                'columns': [
                  {'label': '金额'},
                ],
                'rows': [],
              },
            ],
          }),
          filters: const {'direction': 'in', 'other': 1},
          onFilter: (next) => asked = next,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(zh.pluginViewFilterEmpty), findsOneWidget);
    await tester.tap(find.byKey(FlarePluginView.clearFiltersKey));
    expect(asked, {'other': 1});
  });

  testWidgets('a record row is 64 high (§5.8)', (tester) async {
    surface(tester, 390);
    await tester.pumpWidget(
      host(
        FlarePluginView(
          embedded: true,
          view: FlarePluginViewModel.fromJson({
            'available': true,
            'title': '',
            'blocks': [
              {
                'kind': 'rows',
                'icon': 'clock',
                'columns': [
                  {'label': '金额'},
                  {'label': '对方'},
                ],
                'rows': [
                  {
                    'key': 'r1',
                    'cells': [
                      {'text': '+¥1.00'},
                      {'text': '周屿'},
                    ],
                  },
                ],
              },
            ],
          }),
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(FlarePluginView.rowKey('r1'))).height,
      greaterThanOrEqualTo(FlareSizes.componentRecordRowHeight),
    );
  });

  testWidgets('the status card keeps the journal banner above it and the '
      'steps read their position (§6.1, §12.5)', (tester) async {
    final semantics = tester.ensureSemantics();
    surface(tester, 390);
    await tester.pumpWidget(
      host(
        FlarePluginView(
          embedded: true,
          actionLayout: FlarePluginActionLayout.roles,
          onAction: (_, _) {},
          view: FlarePluginViewModel.fromJson({
            'available': true,
            'title': '',
            'fields': [
              {'label': '状态', 'value': '审核中', 'tone': 'info'},
            ],
            'blocks': [
              {
                'kind': 'steps',
                'items': [
                  {'label': '填写资料', 'state': 'done'},
                  {'label': '核对资料', 'state': 'current'},
                ],
              },
              {
                'kind': 'banner',
                'tone': 'warning',
                'text': '有资金操作等待确认',
                'action': {
                  'id': 'resolve',
                  'label': '处理',
                  'target': {'kind': 'page', 'page': 'p.recovery'},
                },
              },
              {'kind': 'banner', 'tone': 'info', 'text': '旧版说明'},
            ],
          }),
        ),
      ),
    );
    final card = find.byKey(const ValueKey('flare-plugin-status-card'));
    final banner = find.text('有资金操作等待确认');
    expect(banner, findsOneWidget);
    expect(find.text('旧版说明'), findsNothing);
    expect(
      tester.getBottomLeft(banner).dy,
      lessThan(tester.getTopLeft(card).dy),
    );
    expect(
      find.bySemanticsLabel(RegExp(r'^第 2 步，共 2 步: 核对资料')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('a card title stays on one line before its detail key (R5)', (
    tester,
  ) async {
    surface(tester, 390);
    await tester.pumpWidget(
      host(
        Center(
          child: FlarePluginView(
            view: FlarePluginViewModel.fromJson({
              'available': true,
              'title': '一个很长很长很长很长很长很长很长很长很长很长很长很长的标题',
              'detail': true,
            }),
            onOpenDetail: () {},
          ),
        ),
      ),
    );
    final title = tester.widget<Text>(
      find.text('一个很长很长很长很长很长很长很长很长很长很长很长很长的标题'),
    );
    expect(title.maxLines, 1);
    expect(title.overflow, TextOverflow.ellipsis);
  });

  testWidgets('600–899 is a phone for the page too: the task primary is '
      'pinned (one PC breakpoint)', (tester) async {
    surface(tester, 700);
    await tester.pumpWidget(
      host(
        FlarePluginPage(
          page: ref,
          view: FlarePluginPageViewModel.fromJson({
            'available': true,
            'title': '核对',
            'fields': [
              {'label': '金额', 'value': '¥1.00'},
            ],
            'actions': [
              {
                'id': 'pay',
                'label': '确认并支付',
                'style': 'primary',
                'target': {'kind': 'operation', 'operation': 'pay'},
              },
            ],
          }),
          onAction: (_, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(FlarePluginPage.barKey), findsOneWidget);
  });

  testWidgets('a fields account: quick keys in the summary card, a closable '
      'failure on top, a toggle eye, ledger lines with a true minus (R2.1, '
      'R8, R10, §5.8)', (tester) async {
    surface(tester, 390);
    await tester.pumpWidget(
      host(
        FlarePluginPage(
          page: ref,
          appearance: FlarePluginPageAppearance.account,
          actionError: '余额不足',
          view: FlarePluginPageViewModel.fromJson({
            'available': true,
            'title': '钱包',
            'fields': [
              {'label': '可用余额', 'value': '¥1,288.66'},
            ],
            'blocks': [
              {
                'kind': 'rows',
                'columns': [
                  {'label': '金额'},
                  {'label': '备注'},
                ],
                'rows': [
                  {
                    'key': 'tx',
                    'cells': [
                      {'text': '-¥6.00'},
                      {'text': '红包'},
                    ],
                  },
                ],
              },
            ],
            'actions': [
              {
                'id': 'recharge',
                'label': '充值',
                'style': 'primary',
                'target': {'kind': 'page', 'page': 'p.recharge'},
              },
            ],
          }),
          onAction: (_, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final summary = find.byKey(const ValueKey('flare-account-summary'));
    expect(
      find.descendant(of: summary, matching: find.text('充值')),
      findsOneWidget,
    );
    expect(find.text('\u2212¥6.00'), findsOneWidget);
    final eye = find.byWidgetPredicate(
      (w) => w is FlareIconButton && w.semanticLabel == zh.accountHideBalance,
    );
    expect(tester.widget<FlareIconButton>(eye).toggled, isFalse);
    await tester.tap(eye);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FlareIconButton>(
            find.byWidgetPredicate(
              (w) =>
                  w is FlareIconButton &&
                  w.semanticLabel == zh.accountShowBalance,
            ),
          )
          .toggled,
      isTrue,
    );
    final error = find.byKey(const ValueKey('flare-account-error'));
    expect(
      tester.getTopLeft(error).dy,
      lessThan(tester.getTopLeft(summary).dy),
    );
    await tester.tap(
      find.descendant(of: error, matching: find.byType(FlareIconButton)),
    );
    await tester.pumpAndSettle();
    expect(error, findsNothing);
  });

  for (final still in [false, true]) {
    testWidgets('a refresh draws the 2-high bar on its 1.2 s loop '
        '${still ? '(reduced motion: still)' : ''} (R1, §7)', (tester) async {
      surface(tester, 390);
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: still),
              child: FlarePluginPage(
                page: ref,
                view: FlarePluginPageViewModel.fromJson({
                  'available': true,
                  'title': '记录',
                  'blocks': [
                    {
                      'kind': 'rows',
                      'columns': [
                        {'label': '金额'},
                      ],
                      'rows': [],
                    },
                  ],
                }),
                refreshing: true,
                onRefresh: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      final bar = find.byKey(FlarePluginPage.refreshBarKey);
      expect(bar, findsOneWidget);
      expect(tester.getSize(bar).height, 2);
      expect(tester.hasRunningAnimations, !still);
    });
  }
}
