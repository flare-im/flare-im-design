import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> fixture() =>
    (jsonDecode(
              File('../../spec/account-view-vectors.json').readAsStringSync(),
            )['view']
            as Map)
        .cast<String, Object?>();
FlarePluginPageViewModel ledger() => FlarePluginPageViewModel.fromJson({
  ...fixture(),
  'data': {'revision': 'original'},
});
Widget host(Widget body, {bool dark = false, String? fontFamily}) =>
    MaterialApp(
      theme: ThemeData(
        brightness: dark ? Brightness.dark : Brightness.light,
        fontFamily: fontFamily,
      ),
      home: Scaffold(body: body),
    );
void surface(WidgetTester tester, {double width = 390}) {
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget page({
  FlarePluginPageViewModel? view,
  void Function(String, FlarePluginPageActionPayload)? onAction,
  String? error,
}) => FlarePluginPage(
  page: const FlarePluginPageRef(pluginId: 'test.account', page: 'test.wallet'),
  appearance: FlarePluginPageAppearance.account,
  view: view ?? ledger(),
  error: error,
  onAction: onAction,
);
void main() {
  if (Platform.environment['FLARE_WALLET_SCREENSHOTS'] case final output?) {
    for (final dark in [false, true]) {
      testWidgets('capture wallet ${dark ? 'dark' : 'light'}', (tester) async {
        surface(tester);
        await tester.runAsync(() async {
          final font = Platform.environment['FLARE_WALLET_TEST_FONT'];
          if (font != null)
            await (FontLoader('WalletReview')..addFont(
                  File(font).readAsBytes().then((b) => ByteData.sublistView(b)),
                ))
                .load();
          final icons = Platform.environment['FLARE_WALLET_ICON_FONT'];
          if (icons != null)
            await (FontLoader('MaterialIcons')..addFont(
                  File(
                    icons,
                  ).readAsBytes().then((b) => ByteData.sublistView(b)),
                ))
                .load();
        });
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: host(
              page(onAction: (_, _) {}),
              dark: dark,
              fontFamily:
                  Platform.environment.containsKey('FLARE_WALLET_TEST_FONT')
                  ? 'WalletReview'
                  : null,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '$output/flutter-wallet-${dark ? 'dark' : 'light'}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }

  test(
    'resolved ledger keeps exact currencies, unknown dates and deduplicates row keys',
    () {
      final view = ledger();
      final block = view.blocks.whereType<FlarePluginRowsBlock>().first;
      final duplicate = FlarePluginViewModel(
        available: true,
        title: 'wallet',
        blocks: [
          FlarePluginRowsBlock(
            columns: block.columns,
            rows: [...block.rows, block.rows.first],
          ),
        ],
      );
      final entries = flareAccountEntries(duplicate);
      expect(entries.length, block.rows.length);
      expect(entries.first.amount, '+¥88.88');
      expect(entries.last.amount, r'+$0.88');
      final unknown = flareAccountEntries(
        const FlarePluginViewModel(
          available: true,
          title: '',
          blocks: [
            FlarePluginRowsBlock(rows: [FlarePluginRow(key: 'unknown')]),
          ],
        ),
      ).single;
      expect(unknown.timeMs, isNull);
    },
  );
  testWidgets('balance toggle removes overview values', (tester) async {
    surface(tester);
    await tester.pumpWidget(host(page()));
    await tester.pumpAndSettle();
    final eye = find.byWidgetPredicate(
      (w) => w is FlareIconButton && w.semanticLabel == '隐藏余额',
    );
    await tester.tap(eye);
    await tester.pumpAndSettle();
    for (final element in find.byWidgetPredicate((w) => w is FlareButton && w.appearance == FlareButtonAppearance.text).evaluate()) {
      expect(tester.getSize(find.byWidget(element.widget)).height, greaterThanOrEqualTo(FlareSizes.touchTarget));
    }
    expect(find.text('¥1,288.66'), findsNothing);
    expect(find.text('¥68.00'), findsNothing);
    expect(find.text('+¥88.88'), findsOneWidget);
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is FlareIconButton && w.semanticLabel == '显示余额',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('¥1,288.66'), findsOneWidget);
  });
  testWidgets(
    'transaction details forward original row binding and original page data',
    (tester) async {
      surface(tester);
      String? action;
      FlarePluginPageActionPayload? payload;
      await tester.pumpWidget(
        host(
          page(
            onAction: (id, p) {
              action = id;
              payload = p;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account-entry:0/tx-01')));
      await tester.pumpAndSettle();
      expect(find.text('tx-01'), findsOneWidget);
      await tester.tap(find.text('查看红包'));
      await tester.pumpAndSettle();
      expect(action, 'open');
      expect(payload!.row!.key, 'tx-01');
      expect(payload!.row!.input, {'packetId': 'packet-01'});
      expect(payload!.data, {'revision': 'original'});
      expect(payload!.page.page, 'test.wallet');
    },
  );
  testWidgets(
    'entry without a packet action has honest local details and closes',
    (tester) async {
      surface(tester);
      await tester.pumpWidget(host(page()));
      await tester.pumpAndSettle();
      final deposit = find.byKey(const ValueKey('account-entry:0/tx-04'));
      await tester.ensureVisible(deposit);
      await tester.tap(deposit);
      await tester.pumpAndSettle();
      expect(find.text('tx-04'), findsOneWidget);
      expect(find.text('查看红包'), findsNothing);
      expect(find.text('充值'), findsNothing);
      expect(find.text('提现'), findsNothing);
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is FlareIconButton && w.semanticLabel == '关闭',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('tx-04'), findsNothing);
    },
  );
  testWidgets(
    '320px and dark display have no layout errors; refresh failure retains ledger',
    (tester) async {
      surface(tester, width: 320);
      await tester.pumpWidget(host(page(error: '网络暂时不可用'), dark: true));
      await tester.pumpAndSettle();
      expect(find.text('¥1,288.66'), findsOneWidget);
      expect(find.text('网络暂时不可用'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('empty and unavailable account states do not invent a ledger', (
    tester,
  ) async {
    surface(tester);
    await tester.pumpWidget(
      host(
        page(
          view: const FlarePluginPageViewModel(
            available: true,
            title: '钱包',
            fields: [FlarePluginField(label: '余额', value: '¥1,288.66')],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('¥1,288.66'), findsOneWidget);
    expect(find.text('暂无交易记录'), findsOneWidget);
    await tester.pumpWidget(
      host(
        page(
          view: const FlarePluginPageViewModel(
            available: false,
            title: '钱包',
            unavailableReason: FlarePluginUnavailableReason.disabled,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('¥1,288.66'), findsNothing);
    expect(find.byType(FlareAccountView), findsNothing);
  });
}
