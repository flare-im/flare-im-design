import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> walletJson() =>
    ((jsonDecode(File('../../spec/wallet-card-vectors.json').readAsStringSync())
                as Map)['cases']
            as List)
        .cast<Map>()
        .first['view']
        .cast<String, Object?>();

FlarePluginPageViewModel realFlow(String id) {
  final cases =
      (jsonDecode(
                File('../../spec/wallet-flow-vectors.json').readAsStringSync(),
              )
              as Map)['cases']
          as List;
  return FlarePluginPageViewModel.fromJson(
    (cases.cast<Map>().firstWhere(
              (c) =>
                  c['id'] == id &&
                  c['locale'] == 'zh-CN' &&
                  c['variant'] == 'default',
            )['view']
            as Map)
        .cast<String, Object?>(),
  );
}

FlarePluginPageViewModel formView({
  bool confirm = false,
  bool password = false,
  bool missing = false,
  bool multiple = false,
  bool readOnly = false,
}) => FlarePluginPageViewModel.fromJson({
  'available': true,
  'title': '资料',
  'data': {'revision': 7},
  if (readOnly) 'unavailableReason': 'unbound_copy',
  'inputs': [
    {'id': 'unlisted', 'label': '不应出现', 'kind': 'text'},
    {
      'id': 'first',
      'label': '第一项',
      'kind': password ? 'password' : 'text',
      'required': true,
    },
    {'id': 'second', 'label': '第二项', 'kind': 'text', 'required': true},
  ],
  'actions': [
    {
      'id': 'submit',
      'label': '提交申请',
      'style': 'primary',
      'form': ['second', 'first', if (missing) 'absent'],
      if (confirm) 'confirm': '确认后填写资料',
    },
    if (multiple) {'id': 'other', 'label': '其他主操作', 'style': 'primary'},
  ],
  'presentation': {
    'renderer': 'account',
    'props': {'layout': 'flow'},
    'actions': {'submit': 'submit'},
  },
});

Widget page(
  FlarePluginPageViewModel view, {
  String? busy,
  String? error,
  List<FlarePluginFormError> errors = const [],
  int settle = 0,
  FlarePluginPageActionCallback? onAction,
}) => FlarePluginPage(
  page: const FlarePluginPageRef(pluginId: 'test.wallet', page: 'fixture.home'),
  view: view,
  busyActionId: busy,
  actionError: error,
  formErrors: errors,
  settleToken: settle,
  onAction: onAction,
);

Widget host(Widget child, {bool dark = false}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    fontFamily: Platform.environment.containsKey('FLARE_WALLET_TEST_FONT')
        ? 'WalletReview'
        : null,
  ),
  home: Scaffold(body: child),
);

void surface(WidgetTester tester, double width, {double height = 1200}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> fonts(WidgetTester tester) async => tester.runAsync(() async {
  for (final (variable, family) in [
    ('FLARE_WALLET_TEST_FONT', 'WalletReview'),
    ('FLARE_WALLET_ICON_FONT', 'MaterialIcons'),
  ]) {
    if (Platform.environment[variable] case final path?) {
      await (FontLoader(
        family,
      )..addFont(File(path).readAsBytes().then(ByteData.sublistView))).load();
    }
  }
});

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  if (Platform.environment['FLARE_WALLET_SCREENSHOTS'] case final output?) {
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }
}

Finder input(String id) => find.descendant(
  of: find.byKey(ValueKey('flare-plugin-input-$id')),
  matching: find.byType(EditableText),
);

void main() {
  for (final width in [320.0, 1440.0]) {
    testWidgets(
      'wallet cards preserve multiple currencies and overview at $width',
      (tester) async {
        surface(tester, width);
        await fonts(tester);
        final view = FlarePluginPageViewModel.fromJson(walletJson());
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: host(page(view, onAction: (_, _) {}), dark: width == 1440),
          ),
        );
        await tester.pumpAndSettle();
        final entries = flareAccountEntries(view);
        expect(entries, hasLength(2));
        expect(find.text('我的钱包'), findsOneWidget);
        expect(find.text('可用余额'), findsNothing);
        expect(find.text('900.00'), findsNothing);
        expect(find.text('余额'), findsNWidgets(2));
        for (final value in [
          '零钱钱包',
          '旅行钱包',
          '1000.00',
          '88.50',
          'CNY · cash',
          'USD · cash',
        ]) {
          expect(find.text(value), findsOneWidget);
        }
        final first = find.byKey(ValueKey('account-entry:${entries.first.id}'));
        final second = find.byKey(ValueKey('account-entry:${entries.last.id}'));
        if (width == 1440) {
          expect(tester.getTopLeft(first).dy, tester.getTopLeft(second).dy);
          expect(
            tester.getTopLeft(second).dx,
            greaterThan(tester.getTopRight(first).dx),
          );
        } else {
          expect(
            tester.getTopLeft(second).dy,
            greaterThan(tester.getBottomLeft(first).dy),
          );
        }
        expect(
          find.byWidgetPredicate(
            (w) => w is FlareIconButton && w.semanticLabel == '隐藏余额',
          ),
          findsOneWidget,
        );
        await capture(tester, key, 'flutter-wallet-cards-${width.toInt()}');
        await tester.tap(
          find.byKey(const ValueKey('flare-account-information')),
        );
        await tester.pumpAndSettle();
        expect(find.text('可用余额'), findsOneWidget);
        expect(find.text('900.00'), findsOneWidget);
        expect(find.text('1000.00'), findsOneWidget);
        await tester.tap(
          find.byWidgetPredicate(
            (w) => w is FlareIconButton && w.semanticLabel == '隐藏余额',
          ),
        );
        await tester.pumpAndSettle();
        for (final value in [
          '1000.00',
          '88.50',
          '900.00',
          'CNY · cash',
          'USD · cash',
          'active',
        ]) {
          expect(find.text(value), findsNothing);
        }
        expect(find.text('零钱钱包'), findsOneWidget);
        expect(find.text('旅行钱包'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('wallet local detail preserves its exact original row binding', (
    tester,
  ) async {
    surface(tester, 390);
    final json = walletJson();
    ((json['presentation'] as Map)['props'] as Map).remove('rowEntryAction');
    final view = FlarePluginPageViewModel.fromJson({
      ...json,
      'data': {'revision': 11},
    });
    String? action;
    FlarePluginPageActionPayload? payload;
    await tester.pumpWidget(
      host(
        page(
          view,
          onAction: (id, p) {
            action = id;
            payload = p;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        ValueKey('account-entry:${flareAccountEntries(view).last.id}'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('flare-plugin-action-wallet')));
    await tester.pumpAndSettle();
    expect(action, 'wallet');
    expect(payload!.row!.key, 'wallet-usd-fixture');
    expect(payload!.row!.input, {'walletId': 'wallet-usd-fixture'});
    expect(payload!.data, {'revision': 11});
    expect(payload!.page.page, 'fixture.home');
  });

  testWidgets('wallet without rows retains its overview and empty state', (
    tester,
  ) async {
    surface(tester, 320);
    final json = walletJson();
    for (final block in (json['blocks'] as List).cast<Map>()) {
      if (block['kind'] == 'rows') block['rows'] = [];
    }
    await tester.pumpWidget(
      host(page(FlarePluginPageViewModel.fromJson(json))),
    );
    await tester.pumpAndSettle();
    expect(find.text('900.00'), findsOneWidget);
    expect(find.text('尚未开通钱包'), findsOneWidget);
    expect(find.text('零钱钱包'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'inline form preserves order, payload and errors; locks repeats and resets on success',
    (tester) async {
      surface(tester, 390);
      final view = formView();
      String? busy;
      String? error;
      var errors = <FlarePluginFormError>[];
      var settle = 0;
      final calls = <FlarePluginPageActionPayload>[];
      late StateSetter rebuild;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return page(
                view,
                busy: busy,
                error: error,
                errors: errors,
                settle: settle,
                onAction: (_, payload) => calls.add(payload),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      expect(find.byType(FlarePluginForm), findsOneWidget);
      expect(
        find.byKey(const ValueKey('flare-plugin-action-submit')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('flare-plugin-form-cancel')),
        findsNothing,
      );
      expect(find.text('不应出现'), findsNothing);
      expect(
        tester.getTopLeft(input('second')).dy,
        lessThan(tester.getTopLeft(input('first')).dy),
      );
      await tester.enterText(input('first'), 'one');
      await tester.enterText(input('second'), 'two');
      await tester.tap(find.byKey(const ValueKey('flare-plugin-form-submit')));
      await tester.tap(find.byKey(const ValueKey('flare-plugin-form-submit')));
      expect(calls, hasLength(1));
      expect(calls.single.formValues, {'second': 'two', 'first': 'one'});
      expect(calls.single.data, {'revision': 7});
      expect(calls.single.page.page, 'fixture.home');
      await tester.pump();
      expect(
        tester.widget<FlarePluginForm>(find.byType(FlarePluginForm)).busy,
        isTrue,
      );
      rebuild(() => busy = 'submit');
      await tester.pump();
      rebuild(() {
        busy = null;
        error = '资料需要调整';
        errors = [
          const FlarePluginFormError(
            input: 'first',
            issue: FlarePluginFormIssue.tooLong,
          ),
        ];
        settle++;
      });
      await tester.pumpAndSettle();
      expect(
        tester.widget<EditableText>(input('first')).controller.text,
        'one',
      );
      expect(find.text('资料需要调整'), findsOneWidget);
      expect(
        tester.widget<FlarePluginForm>(find.byType(FlarePluginForm)).busy,
        isFalse,
      );
      expect(
        tester.widget<FlarePluginForm>(find.byType(FlarePluginForm)).errors,
        errors,
      );
      rebuild(() {
        error = null;
        errors = [];
      });
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('flare-plugin-form-submit')));
      expect(calls, hasLength(2));
      rebuild(() => settle++);
      await tester.pumpAndSettle();
      expect(
        tester.widget<EditableText>(input('first')).controller.text,
        isEmpty,
      );
      expect(
        tester.widget<EditableText>(input('second')).controller.text,
        isEmpty,
      );
      rebuild(() => busy = 'other');
      await tester.pump();
      expect(
        tester.widget<FlarePluginForm>(find.byType(FlarePluginForm)).busy,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'inline eligibility retains password, confirm, missing, multiple and read-only paths',
    (tester) async {
      surface(tester, 390);
      for (final view in [
        formView(password: true),
        formView(confirm: true),
        formView(missing: true),
        formView(multiple: true),
        formView(readOnly: true),
      ]) {
        await tester.pumpWidget(host(page(view, onAction: (_, _) {})));
        await tester.pumpAndSettle();
        expect(find.byType(FlarePluginForm), findsNothing);
      }
      await tester.pumpWidget(host(page(formView())));
      await tester.pumpAndSettle();
      expect(find.byType(FlarePluginForm), findsNothing);
      expect(
        tester
            .widget<FlareButton>(
              find.byKey(const ValueKey('flare-plugin-action-submit')),
            )
            .disabled,
        isTrue,
      );
      await tester.pumpWidget(
        host(page(formView(password: true), onAction: (_, _) {})),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('flare-plugin-action-submit')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FlarePluginForm), findsOneWidget);
      expect(
        tester.widget<FlarePluginForm>(find.byType(FlarePluginForm)).embedded,
        isFalse,
      );
      expect(tester.widget<EditableText>(input('first')).obscureText, isTrue);
    },
  );

  testWidgets('menu-only actions cannot be selected as inline forms', (
    tester,
  ) async {
    surface(tester, 390);
    final source = formView();
    final view = FlarePluginViewModel(
      available: true,
      title: 'menu',
      inputs: source.inputs,
      menuActions: source.actions,
    );
    await tester.pumpWidget(
      host(
        FlarePluginView(
          view: view,
          embedded: true,
          inlineFormActionId: 'submit',
          onAction: (_, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FlarePluginForm), findsNothing);
    expect(
      find.byKey(const ValueKey('flare-plugin-action-submit')),
      findsOneWidget,
    );
  });

  testWidgets(
    'an unmounted inline form cannot dispatch; read-only update removes editing',
    (tester) async {
      surface(tester, 390);
      var calls = 0;
      await tester.pumpWidget(
        host(page(formView(), onAction: (_, _) => calls++)),
      );
      await tester.pumpAndSettle();
      final submit = tester
          .widget<FlarePluginForm>(find.byType(FlarePluginForm))
          .onSubmit!;
      await tester.pumpWidget(
        host(page(formView(readOnly: true), onAction: (_, _) => calls++)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FlarePluginForm), findsNothing);
      submit({'first': 'stale', 'second': 'stale'});
      expect(calls, 0);
      await tester.pumpWidget(
        host(page(formView(), onAction: (_, _) => calls++)),
      );
      await tester.pumpAndSettle();
      final detached = tester
          .widget<FlarePluginForm>(find.byType(FlarePluginForm))
          .onSubmit!;
      await tester.pumpWidget(const SizedBox());
      detached({'first': 'stale', 'second': 'stale'});
      expect(calls, 0);
    },
  );

  testWidgets(
    'pending inline form recovers when eligibility changes with the same requested id',
    (tester) async {
      surface(tester, 390);
      final editable = formView();
      final readOnly = formView(readOnly: true);
      var restricted = false;
      String? busy;
      var calls = 0;
      late StateSetter rebuild;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return FlarePluginView(
                view: restricted ? readOnly : editable,
                embedded: true,
                inlineFormActionId: 'submit',
                busyActionId: busy,
                onAction: (_, _) => calls++,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(input('first'), 'one');
      await tester.enterText(input('second'), 'two');
      await tester.tap(find.byKey(const ValueKey('flare-plugin-form-submit')));
      await tester.pump();
      expect(calls, 1);
      expect(
        tester.widget<FlarePluginForm>(find.byType(FlarePluginForm)).busy,
        isTrue,
      );
      rebuild(() => restricted = true);
      await tester.pumpAndSettle();
      expect(find.byType(FlarePluginForm), findsNothing);
      rebuild(() {
        restricted = false;
        busy = 'external';
      });
      await tester.pump();
      expect(
        tester.widget<FlarePluginForm>(find.byType(FlarePluginForm)).busy,
        isTrue,
      );
      rebuild(() => busy = null);
      await tester.pumpAndSettle();
      expect(
        tester.widget<FlarePluginForm>(find.byType(FlarePluginForm)).busy,
        isFalse,
      );
      expect(
        tester.widget<EditableText>(input('first')).controller.text,
        isEmpty,
      );
      await tester.enterText(input('first'), 'again');
      await tester.enterText(input('second'), 'restored');
      await tester.tap(find.byKey(const ValueKey('flare-plugin-form-submit')));
      expect(calls, 2);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final id in ['recharge', 'withdrawal', 'payout_profiles']) {
    for (final width in [320.0, 1440.0]) {
      testWidgets('real $id form is directly editable at $width', (
        tester,
      ) async {
        surface(tester, width);
        await fonts(tester);
        final view = realFlow(id);
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: host(page(view, onAction: (_, _) {}), dark: width == 1440),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(FlarePluginForm), findsOneWidget);
        final form = tester.widget<FlarePluginForm>(
          find.byType(FlarePluginForm),
        );
        expect(form.embedded, isTrue);
        final action = view.actions.where((a) => a.form.isNotEmpty).single;
        expect(form.inputs.map((i) => i.id), action.form);
        expect(form.submitLabel, action.label);
        expect(
          find.byKey(ValueKey('flare-plugin-action-${action.id}')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('flare-plugin-form-cancel')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        await capture(tester, key, 'flutter-inline-$id-${width.toInt()}');
      });
    }
  }
}
