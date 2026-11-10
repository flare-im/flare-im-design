import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

FlarePluginPageViewModel wallet({String? unavailableReason}) =>
    FlarePluginPageViewModel.fromJson({
      'available': true,
      'title': '钱包',
      'data': {'walletId': 'opaque-wallet'},
      if (unavailableReason != null) 'unavailableReason': unavailableReason,
      'fields': [
        {'label': '可用余额', 'value': '¥1,000.00'},
        {'label': '资金类型与币种', 'value': 'CNY · cash'},
        {'label': '当前钱包', 'value': 'primary'},
      ],
      'actions': [
        {'id': 'deposit', 'label': '充值', 'style': 'primary'},
        {'id': 'cashout', 'label': '提现'},
        {'id': 'destinations', 'label': '收款方式'},
        {'id': 'activity', 'label': '充值与提现记录'},
        {'id': 'security', 'label': '支付密码'},
      ],
      'blocks': [
        {
          'kind': 'rows',
          'columns': [
            {'label': '余额'},
            {'label': '钱包'},
            {'label': '币种'},
          ],
          'rows': [
            {
              'key': 'wallet-01',
              'cells': [
                {'text': '¥1,000.00'},
                {'text': '余额钱包'},
                {'text': 'CNY'},
              ],
            },
          ],
        },
      ],
      'presentation': {
        'renderer': 'account',
        'props': {
          'layout': 'wallet',
          'summaryTitle': '余额钱包',
          'description': '余额、充值与提现统一管理。',
          'sectionTitle': '我的钱包',
          'servicesTitle': '钱包服务',
        },
        'actions': {
          'primary': 'deposit',
          'secondary': 'cashout',
          'tertiary': 'destinations',
          'unavailable': 'not-declared',
        },
      },
    });

FlarePluginPageViewModel flow({bool form = false}) =>
    FlarePluginPageViewModel.fromJson({
      'available': true,
      'title': '提现',
      'data': {'walletId': 'opaque-wallet', 'revision': 7},
      'fields': [
        {'label': '可提现余额', 'value': '¥800.00'},
        {'label': '收款方式', 'value': '已绑定银行卡'},
      ],
      'inputs': [
        {'id': 'amount', 'label': '提现金额', 'kind': 'text', 'required': true},
      ],
      'actions': [
        {
          'id': 'cashout',
          'label': '下一步',
          'style': 'primary',
          if (form) 'confirm': '核对提现信息后继续',
          if (form) 'form': ['amount'],
        },
        {'id': 'recovery', 'label': '查看待确认操作'},
      ],
      'blocks': [
        {'kind': 'note', 'text': '有一笔操作正在确认，请先查看处理进度。', 'tone': 'warning'},
      ],
      'presentation': {
        'renderer': 'account',
        'props': {
          'layout': 'flow',
          'stepLabel': '填写信息',
          'description': '选择收款方式并填写提现金额，下一步核对后提交。',
          'servicesTitle': '更多操作',
        },
        'actions': {'submit': 'cashout'},
      },
    });

Widget host(
  FlarePluginPageViewModel view, {
  bool dark = false,
  double scale = 1,
  String? fontFamily,
  String? busy,
  String? error,
  int settleToken = 0,
  FlarePluginPageActionCallback? onAction,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    fontFamily: fontFamily,
  ),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(
    body: FlarePluginPage(
      page: const FlarePluginPageRef(pluginId: 'test.wallet', page: 'wallet'),
      view: view,
      busyActionId: busy,
      actionError: error,
      settleToken: settleToken,
      onAction: onAction,
    ),
  ),
);

void surface(WidgetTester tester, {double width = 390, double height = 1000}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('wallet hierarchy stays compact at 320 and enlarged text', (
    tester,
  ) async {
    surface(tester, width: 320);
    await tester.pumpWidget(host(wallet(), scale: 1.4, onAction: (_, _) {}));
    await tester.pumpAndSettle();
    expect(find.text('充值'), findsOneWidget);
    expect(find.text('提现'), findsOneWidget);
    expect(find.text('收款方式'), findsOneWidget);
    expect(find.text('primary'), findsNothing);
    expect(find.text('CNY · cash'), findsNothing);
    expect(find.text('not-declared'), findsNothing);
    expect(find.text('其他记录'), findsNothing);
    for (final id in ['deposit', 'cashout', 'destinations']) {
      expect(
        tester.getSize(find.byKey(ValueKey('flare-plugin-action-$id'))).height,
        greaterThanOrEqualTo(FlareSizes.touchTargetMin),
      );
    }
    expect(
      tester
          .getSize(find.byKey(const ValueKey('flare-account-summary')))
          .height,
      lessThan(
        320,
      ), // Long copy and enlarged text may wrap without hiding actions.
    );
    final info = find.byKey(const ValueKey('flare-account-information'));
    await tester.ensureVisible(info);
    await tester.tap(info);
    await tester.pumpAndSettle();
    expect(find.text('primary'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop wallet content is centered and bounded', (tester) async {
    surface(tester, width: 1440);
    await tester.pumpWidget(host(wallet(), dark: true, onAction: (_, _) {}));
    await tester.pumpAndSettle();
    final summary = tester.getRect(
      find.byKey(const ValueKey('flare-account-summary')),
    );
    expect(
      summary.width,
      lessThanOrEqualTo(FlareSizes.directoryContentMaxWidth),
    );
    expect(summary.center.dx, 720);
    expect(summary.left, greaterThan(240));
    final title = find.descendant(
      of: find.byKey(const ValueKey('flare-account-summary')),
      matching: find.text('我的钱包'),
    );
    expect(
      tester.getCenter(title).dy,
      closeTo(
        tester
            .getCenter(
              find.byKey(const ValueKey('flare-plugin-action-deposit')),
            )
            .dy,
        1,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'flow uses receipt, preserves urgent notice and draws error once',
    (tester) async {
      surface(tester, width: 320);
      await tester.pumpWidget(host(flow(), error: '请重试', onAction: (_, _) {}));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('flare-account-receipt')),
        findsOneWidget,
      );
      expect(find.text('暂无交易记录'), findsNothing);
      expect(find.text('有一笔操作正在确认，请先查看处理进度。'), findsOneWidget);
      expect(find.text('请重试'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('new action layouts retain confirmation and exact form payload', (
    tester,
  ) async {
    surface(tester);
    final calls = <FlarePluginPageActionPayload>[];
    final actions = <String>[];
    final view = flow(form: true);
    await tester.pumpWidget(
      host(
        view,
        onAction: (id, payload) {
          actions.add(id);
          calls.add(payload);
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('flare-plugin-action-cashout')));
    await tester.pumpAndSettle();
    expect(find.text('核对提现信息后继续'), findsOneWidget);
    expect(calls, isEmpty);
    await tester.tap(find.widgetWithText(FlareButton, '下一步').last);
    await tester.pumpAndSettle();
    expect(find.byType(FlarePluginForm), findsOneWidget);
    await tester.enterText(find.byType(EditableText), '128.50');
    await tester.tap(find.byKey(const ValueKey('flare-plugin-form-submit')));
    await tester.pump();
    expect(actions, ['cashout']);
    expect(calls.single.formValues, {'amount': '128.50'});
    expect(calls.single.data, {'walletId': 'opaque-wallet', 'revision': 7});
    expect(calls.single.page.page, 'wallet');
    await tester.pumpWidget(
      host(view, error: '余额已变更', settleToken: 1, onAction: (_, _) {}),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FlarePluginForm), findsOneWidget);
    expect(
      find.text('余额已变更'),
      findsNWidgets(2),
    ); // One page banner and one form error.
  });

  testWidgets('busy and read-only states prevent all projected actions', (
    tester,
  ) async {
    surface(tester);
    final calls = <String>[];
    await tester.pumpWidget(
      host(wallet(), busy: 'deposit', onAction: (id, _) => calls.add(id)),
    );
    await tester.pump();
    for (final element in find.byType(FlareButton).evaluate()) {
      final button = element.widget as FlareButton;
      expect(button.disabled, isTrue);
    }
    expect(calls, isEmpty);
    await tester.pumpWidget(
      host(
        wallet(unavailableReason: 'unbound_copy'),
        onAction: (id, _) => calls.add(id),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('flare-plugin-action-deposit')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('flare-plugin-action-security')),
      findsNothing,
    );
    expect(calls, isEmpty);
  });

  testWidgets(
    'a visible replacement primary action stays in the flow receipt',
    (tester) async {
      surface(tester);
      const view = FlarePluginPageViewModel(
        available: true,
        title: '提现',
        actions: [
          FlarePluginAction(
            id: 'create',
            label: '确认提现',
            style: FlarePluginActionStyle.primary,
          ),
          FlarePluginAction(id: 'recovery', label: '查看待确认操作'),
        ],
        presentation: {
          'renderer': 'account',
          'props': {'layout': 'flow'},
          'actions': {'submit': 'authorize'},
        },
      );
      await tester.pumpWidget(host(view, onAction: (_, _) {}));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('flare-account-receipt')),
          matching: find.byKey(const ValueKey('flare-plugin-action-create')),
        ),
        findsOneWidget,
      );
      expect(find.text('authorize'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('ledger without overview fields has no duplicate summary card', (
    tester,
  ) async {
    surface(tester);
    const view = FlarePluginPageViewModel(
      available: true,
      title: '充值与提现记录',
      presentation: {
        'renderer': 'account',
        'props': {
          'layout': 'ledger',
          'description': '查看申请进度、到账金额与审核结果。',
          'sectionTitle': '充值与提现明细',
        },
      },
    );
    await tester.pumpWidget(host(view));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('flare-account-summary')), findsNothing);
    expect(find.text('充值与提现记录'), findsOneWidget);
    expect(find.text('查看申请进度、到账金额与审核结果。'), findsOneWidget);
    expect(find.text('充值与提现明细'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  FlarePluginPageViewModel sharedFixture(String id) {
    final vectors =
        jsonDecode(
              File('../../spec/wallet-flow-vectors.json').readAsStringSync(),
            )
            as Map;
    final item = (vectors['cases'] as List).cast<Map>().singleWhere(
      (item) =>
          item['id'] == id &&
          item['variant'] == 'default' &&
          item['locale'] == 'zh-CN',
    );
    return FlarePluginPageViewModel.fromJson(
      (item['view'] as Map).cast<String, Object?>(),
    );
  }

  for (final id in ['home', 'openings', 'lots', 'cashflow_history']) {
    for (final width in [320.0, 1440.0]) {
      testWidgets('shared wallet fixture $id at $width', (tester) async {
        surface(tester, width: width, height: 1000);
        final view = sharedFixture(id);
        await tester.runAsync(() async {
          if (Platform.environment['FLARE_WALLET_TEST_FONT'] case final path?) {
            await (FontLoader(
                  'WalletReview',
                )..addFont(File(path).readAsBytes().then(ByteData.sublistView)))
                .load();
          }
          if (Platform.environment['FLARE_WALLET_ICON_FONT'] case final path?) {
            await (FontLoader(
                  'MaterialIcons',
                )..addFont(File(path).readAsBytes().then(ByteData.sublistView)))
                .load();
          }
        });
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: host(
              view,
              dark: width == 1440,
              fontFamily:
                  Platform.environment.containsKey('FLARE_WALLET_TEST_FONT')
                  ? 'WalletReview'
                  : null,
              onAction: (_, _) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('暂无记录'), findsNothing);
        if (id == 'home') {
          final entry = find.byKey(
            ValueKey('account-entry:${flareAccountEntries(view).first.id}'),
          );
          final information = find.byKey(
            const ValueKey('flare-account-information'),
          );
          final services = find.byKey(const ValueKey('flare-account-services'));
          expect(
            tester.getBottomLeft(entry).dy,
            lessThanOrEqualTo(tester.getTopLeft(information).dy),
          );
          expect(
            tester.getBottomLeft(information).dy,
            lessThanOrEqualTo(tester.getTopLeft(services).dy),
          );
        } else if (id == 'openings') {
          for (final label in ['模板', '状态', '原因']) {
            expect(find.text(label), findsOneWidget);
          }
          expect(find.text('工资钱包'), findsOneWidget);
          expect(
            find.byKey(const ValueKey('flare-account-summary')),
            findsNothing,
          );
        } else {
          final entry = flareAccountEntries(view).single;
          expect(entry.amount, id == 'lots' ? '200.00' : '100.00');
          expect(entry.title, id == 'lots' ? 'CNY' : '提现');
          expect(entry.subtitle, id == 'lots' ? '可提现' : 'CNY');
          final entryCard = find.byKey(ValueKey('account-entry:${entry.id}'));
          if (id == 'cashflow_history') {
            expect(entry.row.badge?.text, '待审核');
            final badge = find.descendant(
              of: entryCard,
              matching: find.byType(FlareTag),
            );
            expect(badge, findsOneWidget);
            expect(
              find.descendant(of: badge, matching: find.text('待审核')),
              findsOneWidget,
            );
          }
          for (final text in [entry.title, entry.subtitle, entry.amount]) {
            expect(
              find.descendant(of: entryCard, matching: find.text(text)),
              findsOneWidget,
            );
          }
        }
        if (Platform.environment['FLARE_WALLET_SCREENSHOTS']
            case final output?) {
          await tester.runAsync(() async {
            final image =
                await (key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '$output/flutter-shared-$id-${width.toInt()}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      });
    }
  }

  testWidgets(
    'wallet error stays above entries after moving services below information',
    (tester) async {
      surface(tester, width: 320);
      final view = sharedFixture('home');
      await tester.pumpWidget(host(view, error: '余额更新失败', onAction: (_, _) {}));
      await tester.pumpAndSettle();
      final summary = find.byKey(const ValueKey('flare-account-summary'));
      final error = find.text('余额更新失败');
      final entry = find.byKey(
        ValueKey('account-entry:${flareAccountEntries(view).first.id}'),
      );
      expect(
        tester.getBottomLeft(summary).dy,
        lessThanOrEqualTo(tester.getTopLeft(error).dy),
      );
      expect(
        tester.getBottomLeft(error).dy,
        lessThan(tester.getTopLeft(entry).dy),
      );
      expect(find.text('余额更新失败'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shared wallet recovery keeps default-style bound submit in receipt',
    (tester) async {
      surface(tester, width: 320);
      final view = sharedFixture('recovery');
      expect(view.actions.single.style, isNull);
      await tester.pumpWidget(host(view, onAction: (_, _) {}));
      await tester.pumpAndSettle();
      final retry = find.byKey(const ValueKey('flare-plugin-action-retry'));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('flare-account-receipt')),
          matching: retry,
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<FlareButton>(retry).variant,
        FlareButtonVariant.secondary,
      );
      expect(find.text('有资金操作等待确认。请先查看原单，勿重新付款。'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  if (Platform.environment['FLARE_WALLET_SCREENSHOTS'] case final output?) {
    for (final (label, view, width, height, dark) in [
      ('mobile-light', wallet(), 390.0, 844.0, false),
      ('desktop-dark', wallet(), 1440.0, 960.0, true),
      ('withdrawal', flow(), 390.0, 844.0, false),
    ]) {
      testWidgets('capture structured wallet $label', (tester) async {
        surface(tester, width: width, height: height);
        await tester.runAsync(() async {
          if (Platform.environment['FLARE_WALLET_TEST_FONT'] case final path?) {
            await (FontLoader(
                  'WalletReview',
                )..addFont(File(path).readAsBytes().then(ByteData.sublistView)))
                .load();
          }
          if (Platform.environment['FLARE_WALLET_ICON_FONT'] case final path?) {
            await (FontLoader(
                  'MaterialIcons',
                )..addFont(File(path).readAsBytes().then(ByteData.sublistView)))
                .load();
          }
        });
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: host(
              view,
              dark: dark,
              fontFamily:
                  Platform.environment.containsKey('FLARE_WALLET_TEST_FONT')
                  ? 'WalletReview'
                  : null,
              onAction: (_, _) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '$output/flutter-wallet-$label.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }
}
