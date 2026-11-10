import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'wallet_composition_test.dart' as review;

FlarePluginPageViewModel walletView({
  bool second = true,
  bool empty = false,
  bool readOnly = false,
  bool confirm = false,
  bool form = false,
  String? firstAmount,
  Map<String, String> shortcuts = const {},
}) => FlarePluginPageViewModel.fromJson({
  'available': true,
  'title': '钱包',
  if (readOnly) 'unavailableReason': 'unbound_copy',
  'fields': [
    {'label': '可用余额', 'value': '900.00'},
  ],
  'actions': [
    {'id': 'deposit', 'label': '充值', 'style': 'primary'},
    {'id': 'withdraw', 'label': '提现'},
    {'id': 'profiles', 'label': '收款方式'},
    {'id': 'transactions', 'label': '交易记录'},
    {'id': 'recharges', 'label': '充值记录'},
    {'id': 'withdrawals', 'label': '提现记录'},
    {'id': 'opening', 'label': '开户进度'},
    {'id': 'open', 'label': '开户'},
    {'id': 'pending', 'label': '待确认操作'},
    {'id': 'password', 'label': '支付密码'},
  ],
  'blocks': [
    {
      'kind': 'rows',
      'columns': [
        {'label': '余额'},
        {'label': '钱包'},
        {'label': '资产'},
        {'label': '状态'},
      ],
      'actions': [
        {
          'id': 'wallet',
          'label': '查看明细',
          if (confirm) 'confirm': '确认查看',
          if (form) 'form': ['note'],
        },
      ],
      'rows': [
        if (!empty)
          for (final (id, title, amount, asset) in [
            ('cny', '零钱钱包', firstAmount ?? '1000.00', 'CNY · 现金'),
            if (second) ('usd', '旅行钱包', '88.50', 'USD · 现金'),
          ])
            {
              'key': id,
              'cells': [
                {'text': amount},
                {'text': title},
                {'text': asset},
                {'text': '可用'},
              ],
              'actions': [
                {
                  'id': 'wallet',
                  'input': {'walletId': 'opaque-$id', 'revision': 7},
                },
              ],
            },
      ],
    },
  ],
  'presentation': {
    'renderer': 'account',
    'props': {
      'layout': 'wallet',
      'sectionTitle': '我的钱包',
      'shortcutsTitle': '账单与记录',
      'servicesTitle': '账户与安全',
      'informationTitle': '账户信息',
      'rowEntryAction': 'wallet',
      'detailTitle': '本钱包信息',
      'emptyTitle': '尚无钱包',
    },
    'actions': {
      'primary': 'deposit',
      'secondary': 'withdraw',
      'tertiary': 'profiles',
      'shortcutPrimary': 'transactions',
      'shortcutSecondary': 'recharges',
      'shortcutTertiary': 'withdrawals',
      ...shortcuts,
    },
  },
});

Finder card(String id) => find.byKey(ValueKey('account-entry:0/$id'));
Finder action(String id) => find.byKey(ValueKey('flare-plugin-action-$id'));

void main() {
  for (final width in [320.0, 1440.0]) {
    testWidgets('wallet hierarchy and grouped records fit $width', (
      tester,
    ) async {
      review.surface(tester, width);
      await review.fonts(tester);
      final capture = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: review.host(
            review.page(walletView(), onAction: (_, _) {}),
            dark: width == 1440,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('账单与记录'), findsOneWidget);
      expect(find.text('账户与安全'), findsOneWidget);
      final amount = tester.widget<Text>(find.text('1000.00'));
      final name = tester.widget<Text>(find.text('零钱钱包'));
      expect(amount.style!.fontSize, greaterThan(name.style!.fontSize!));
      expect(amount.overflow, isNot(TextOverflow.ellipsis));
      expect(find.text('余额'), findsNWidgets(2));
      expect(find.text('可用余额'), findsNothing);
      expect(find.text('查看明细'), findsNWidgets(2));
      final services = find.byKey(const ValueKey('flare-account-services'));
      final shortcuts = find.byKey(const ValueKey('flare-account-shortcuts'));
      for (final id in ['transactions', 'recharges', 'withdrawals']) {
        expect(action(id), findsOneWidget);
        expect(
          find.descendant(of: services, matching: action(id)),
          findsNothing,
        );
        expect(
          find.descendant(of: shortcuts, matching: action(id)),
          findsOneWidget,
        );
      }
      expect(
        tester.getTopLeft(shortcuts).dy,
        lessThan(tester.getTopLeft(services).dy),
      );
      expect(tester.takeException(), isNull);
      await review.capture(
        tester,
        capture,
        'flutter-wallet-navigation-${width.toInt()}',
      );
    });
  }

  testWidgets('single desktop wallet uses the available content width', (
    tester,
  ) async {
    review.surface(tester, 1440);
    await tester.pumpWidget(
      review.host(review.page(walletView(second: false), onAction: (_, _) {})),
    );
    await tester.pumpAndSettle();
    final header = find.byKey(const ValueKey('flare-account-summary'));
    expect(
      tester.getSize(card('cny')).width,
      closeTo(tester.getSize(header).width, 1),
    );
  });

  testWidgets('narrow enlarged text keeps the exact amount and masking', (
    tester,
  ) async {
    review.surface(tester, 320);
    const amount = '12345678901234567890.001';
    await tester.pumpWidget(
      review.host(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.4)),
            child: review.page(
              walletView(second: false, firstAmount: amount),
              onAction: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final value = tester.widget<Text>(find.text(amount));
    expect(value.maxLines, isNull);
    expect(value.overflow, isNot(TextOverflow.ellipsis));
    expect(find.text('CNY · 现金'), findsOneWidget);
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is FlareIconButton && w.semanticLabel == '隐藏余额',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(amount), findsNothing);
    expect(find.text('CNY · 现金'), findsNothing);
    expect(find.text('零钱钱包'), findsOneWidget);
    expect(find.text('查看明细'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wallet card dispatches the original wallet binding', (
    tester,
  ) async {
    review.surface(tester, 320);
    FlarePluginPageActionPayload? payload;
    String? id;
    await tester.pumpWidget(
      review.host(
        review.page(
          walletView(),
          onAction: (key, value) {
            id = key;
            payload = value;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(card('usd'));
    await tester.pumpAndSettle();
    expect(id, 'wallet');
    expect(payload!.row!.key, 'usd');
    expect(payload!.row!.input, {'walletId': 'opaque-usd', 'revision': 7});
    expect(find.text('本钱包信息'), findsNothing);
  });

  for (final guard in ['confirm', 'form', 'readOnly', 'noHandler']) {
    testWidgets('wallet entry $guard retains guarded local details', (
      tester,
    ) async {
      review.surface(tester, 320);
      var called = false;
      await tester.pumpWidget(
        review.host(
          review.page(
            walletView(
              second: false,
              confirm: guard == 'confirm',
              form: guard == 'form',
              readOnly: guard == 'readOnly',
            ),
            onAction: guard == 'noHandler' ? null : (_, _) => called = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('查看明细'), findsNothing);
      await tester.tap(card('cny'));
      await tester.pumpAndSettle();
      expect(called, isFalse);
      expect(find.text('本钱包信息'), findsOneWidget);
    });
  }

  testWidgets(
    'busy preserves the card footer while disabling activation and shortcuts',
    (tester) async {
      review.surface(tester, 320);
      var called = false;
      await tester.pumpWidget(
        review.host(
          review.page(
            walletView(second: false),
            busy: 'pending',
            onAction: (_, _) => called = true,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('查看明细'), findsOneWidget);
      await tester.tap(card('cny'));
      await tester.tap(action('transactions'));
      await tester.pump();
      expect(called, isFalse);
      expect(find.text('本钱包信息'), findsNothing);
      expect(
        tester.widget<FlareButton>(action('transactions')).disabled,
        isTrue,
      );
    },
  );

  testWidgets('shortcut slots deduplicate and missing slots invent no action', (
    tester,
  ) async {
    review.surface(tester, 1440);
    await tester.pumpWidget(
      review.host(
        review.page(
          walletView(
            shortcuts: {
              'shortcutPrimary': 'deposit',
              'shortcutSecondary': 'transactions',
              'shortcutTertiary': 'absent',
            },
          ),
          onAction: (_, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(action('deposit'), findsOneWidget);
    expect(action('transactions'), findsOneWidget);
    expect(find.text('absent'), findsNothing);
    final shortcuts = find.byKey(const ValueKey('flare-account-shortcuts'));
    expect(
      find.descendant(of: shortcuts, matching: action('deposit')),
      findsNothing,
    );
    expect(
      find.descendant(of: shortcuts, matching: action('transactions')),
      findsOneWidget,
    );
  });

  testWidgets(
    'empty wallets keep declared record shortcuts without invented cards',
    (tester) async {
      review.surface(tester, 320);
      await tester.pumpWidget(
        review.host(review.page(walletView(empty: true), onAction: (_, _) {})),
      );
      await tester.pumpAndSettle();
      expect(card('cny'), findsNothing);
      expect(find.text('尚无钱包'), findsOneWidget);
      expect(find.text('账单与记录'), findsOneWidget);
      expect(action('transactions'), findsOneWidget);
    },
  );

  testWidgets(
    'resolved home exposes declared records and wallet history entry',
    (tester) async {
      review.surface(tester, 1440);
      final view = review.realFlow('home');
      final bindings = view.presentation!['actions'] as Map;
      final entry = flareAccountEntries(view).first;
      FlarePluginPageActionPayload? payload;
      String? actionId;
      await tester.pumpWidget(
        review.host(
          review.page(
            view,
            onAction: (id, value) {
              actionId = id;
              payload = value;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final shortcuts = find.byKey(const ValueKey('flare-account-shortcuts'));
      for (final slot in [
        'shortcutPrimary',
        'shortcutSecondary',
        'shortcutTertiary',
      ]) {
        expect(bindings[slot], isA<String>());
        expect(
          find.descendant(
            of: shortcuts,
            matching: action(bindings[slot] as String),
          ),
          findsOneWidget,
        );
      }
      final requested = (view.presentation!['props'] as Map)['rowEntryAction'];
      final binding = entry.row.actions.firstWhere((a) => a.id == requested);
      expect(find.text('primary'), findsNothing);
      expect(find.text('active'), findsNothing);
      await tester.tap(find.byKey(ValueKey('account-entry:${entry.id}')));
      await tester.pumpAndSettle();
      expect(actionId, requested);
      expect(payload!.row!.key, entry.row.key);
      expect(payload!.row!.input, binding.input);
    },
  );

  for (final contextLabel in ['零钱钱包 · CNY · 现金', '']) {
    testWidgets(
      'ledger wallet context respects its declared label "$contextLabel"',
      (tester) async {
        review.surface(tester, 320);
        final view = FlarePluginPageViewModel.fromJson({
          'available': true,
          'title': '交易记录',
          'presentation': {
            'renderer': 'account',
            'props': {
              'layout': 'ledger',
              'description': '查看余额变动记录',
              'contextLabel': contextLabel,
            },
          },
        });
        await tester.pumpWidget(review.host(review.page(view)));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('flare-account-context')),
          contextLabel.isEmpty ? findsNothing : findsOneWidget,
        );
        if (contextLabel.isNotEmpty)
          expect(find.text(contextLabel), findsOneWidget);
      },
    );
  }

  final scoped =
      (jsonDecode(
                File(
                  '../../spec/wallet-scoped-history-vectors.json',
                ).readAsStringSync(),
              )
              as Map)['cases']
          as List;
  for (final raw in scoped.cast<Map>()) {
    testWidgets(
      'resolved ${raw['variant']}/${raw['locale']} preserves wallet scope',
      (tester) async {
        review.surface(tester, 320);
        // The SDK attaches the source result to the resolved page envelope;
        // top-level action pointers are bound there, unlike bound row inputs.
        final sourceData = (raw['sourceData'] as Map).cast<String, Object?>();
        final rawView = (raw['view'] as Map).cast<String, Object?>();
        final view = FlarePluginPageViewModel.fromJson({
          ...rawView,
          'data': sourceData,
        });
        final pageRef = FlarePluginPageRef(
          pluginId: 'flare.wallet',
          page: raw['page'] as String,
        );
        final entry = flareAccountEntries(view).single;
        final props = view.presentation!['props'] as Map;
        final binding = entry.row.actions.single;
        FlarePluginPageActionPayload? payload;
        String? actionId;
        await tester.pumpWidget(
          review.host(
            FlarePluginPage(
              page: pageRef,
              view: view,
              onAction: (id, value) {
                actionId = id;
                payload = value;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('flare-account-context')),
            matching: find.text(props['contextLabel'] as String),
          ),
          findsOneWidget,
        );
        expect(find.text('可用余额'), findsNothing);
        await tester.tap(find.byKey(ValueKey('account-entry:${entry.id}')));
        await tester.pumpAndSettle();
        expect(actionId, props['rowEntryAction']);
        expect(payload!.row!.key, entry.row.key);
        expect(payload!.row!.input, binding.input);
        expect(
          (payload!.row!.input as Map)['walletId'],
          (raw['arguments'] as Map)['walletId'],
        );
        final manage = (rawView['actions'] as List).cast<Map>().singleWhere(
          (action) => action['id'] == 'manageWallet',
        );
        expect(manage['target'], {
          'kind': 'page',
          'page': 'flare.wallet.page.wallet',
        });
        expect(manage['input'], {'walletId': '/walletId'});
        final manageButton = find.byKey(
          const ValueKey('flare-plugin-action-manageWallet'),
        );
        await tester.ensureVisible(manageButton);
        await tester.tap(manageButton);
        await tester.pumpAndSettle();
        expect(actionId, 'manageWallet');
        expect(payload!.page.toJson(), pageRef.toJson());
        expect(payload!.row, isNull);
        expect(payload!.data, sourceData);
        expect(
          payload!.data!['walletId'],
          (raw['arguments'] as Map)['walletId'],
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
