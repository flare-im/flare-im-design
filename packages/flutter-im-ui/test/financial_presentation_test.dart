import 'dart:convert';
import 'dart:io';
import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> fixture(String name) =>
    (jsonDecode(
              File(
                '../../spec/financial-presentation-vectors.json',
              ).readAsStringSync(),
            )[name]
            as Map)
        .cast<String, Object?>();
Widget host(Widget body) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: body)),
);

Map<String, Object?> passwordPayment() {
  final raw = fixture('payment');
  raw['inputs'] = [
    {
      'id': 'opaque-pin',
      'kind': 'password',
      'label': '支付密码',
      'required': true,
      'maxLength': 6,
    },
  ];
  (raw['actions'] as List).first['form'] = ['opaque-pin'];
  return raw;
}

void main() {
  testWidgets(
    'resolved cards use the immutable brand and historical fallback',
    (tester) async {
      final raw = fixture('card');
      ((raw['presentation'] as Map)['props'] as Map)['brandName'] =
          'Company Gift';
      await tester.pumpWidget(
        host(FlarePluginView(view: FlarePluginViewModel.fromJson(raw))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Company Gift'), findsOneWidget);
      expect(find.text('Flare 红包'), findsNothing);
      ((raw['presentation'] as Map)['props'] as Map).remove('brandName');
      await tester.pumpWidget(
        host(FlarePluginView(view: FlarePluginViewModel.fromJson(raw))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Flare 红包'), findsOneWidget);
    },
  );

  testWidgets('long custom card brands remain inside the compact envelope', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 180,
          child: FlareRedPacketCard(
            blessing: 'Hello',
            kind: FlareRedPacketKind.exclusive,
            recipientName: 'Bob',
            brandName: 'Company gift for our community and friends',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final text = tester.widget<Text>(
      find.text('Company gift for our community and friends'),
    );
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a late cancel callback cannot pop the next page', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: Scaffold(
          body: FlarePluginView(
            view: FlarePluginViewModel.fromJson(passwordPayment()),
            onAction: (_, _) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final cancel = tester
        .widget<FlareRedPacketPayConfirm>(find.byType(FlareRedPacketPayConfirm))
        .onCancel!;
    cancel();
    await tester.pumpAndSettle();
    navigator.currentState!.push<void>(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('next page')),
      ),
    );
    await tester.pumpAndSettle();
    cancel();
    await tester.pumpAndSettle();
    expect(find.text('next page'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'synchronous confirmation navigation keeps the captured PIN and disposes safely',
    (tester) async {
      var visible = true;
      late StateSetter update;
      final calls = <FlarePluginActionPayload>[];
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, set) {
              update = set;
              return visible
                  ? FlarePluginView(
                      view: FlarePluginViewModel.fromJson(passwordPayment()),
                      onAction: (_, payload) {
                        calls.add(payload);
                        update(() => visible = false);
                      },
                    )
                  : const Text('next step');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), '839271');
      tester
          .widget<FlareRedPacketPayConfirm>(
            find.byType(FlareRedPacketPayConfirm),
          )
          .onConfirm!();
      await tester.pumpAndSettle();
      expect(find.text('next step'), findsOneWidget);
      expect(calls.single.formValues, {'opaque-pin': '839271'});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'removing payment before its overlay builds leaves no orphan route',
    (tester) async {
      var visible = true;
      late StateSetter update;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, set) {
              update = set;
              return visible
                  ? FlarePluginView(
                      view: FlarePluginViewModel.fromJson(passwordPayment()),
                      onAction: (_, _) {},
                    )
                  : const Text('remaining page');
            },
          ),
        ),
      );
      update(() => visible = false);
      await tester.pumpAndSettle();
      expect(find.byType(FlareRedPacketPayConfirm), findsNothing);
      expect(find.text('remaining page'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancelled payment stays closed after the same step refreshes', (
    tester,
  ) async {
    var raw = passwordPayment();
    late StateSetter update;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (_, set) {
            update = set;
            return FlarePluginView(
              view: FlarePluginViewModel.fromJson(raw),
              onAction: (_, _) {},
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '839271');
    tester
        .widget<FlareRedPacketPayConfirm>(find.byType(FlareRedPacketPayConfirm))
        .onCancel!();
    await tester.pumpAndSettle();
    update(() {
      raw = passwordPayment();
      ((raw['presentation'] as Map)['props'] as Map)['methodLabel'] =
          'Updated account';
    });
    await tester.pumpAndSettle();
    expect(find.byType(FlareRedPacketPayConfirm), findsNothing);
    await tester.tap(find.text('确认授权'));
    await tester.pumpAndSettle();
    final panel = tester.widget<FlareRedPacketPayConfirm>(
      find.byType(FlareRedPacketPayConfirm),
    );
    expect(panel.methodLabel, 'Updated account');
    expect(
      tester.widget<FlareInput>(find.byType(FlareInput)).controller!.text,
      isEmpty,
    );
  });

  testWidgets(
    'disposing a payment removes only its overlay and keeps the next route',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      var visible = true;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (_, set) {
                update = set;
                return visible
                    ? FlarePluginView(
                        view: FlarePluginViewModel.fromJson(passwordPayment()),
                        onAction: (_, _) {},
                      )
                    : const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), '839271');
      navigator.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('next page')),
        ),
      );
      update(() => visible = false);
      await tester.pumpAndSettle();
      expect(find.text('next page'), findsOneWidget);
      expect(find.byType(FlareRedPacketPayConfirm), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'busy payment locks cancel, scrim, Escape and duplicate dispatch',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final view = FlarePluginViewModel.fromJson(passwordPayment());
      var busy = false;
      late StateSetter update;
      final calls = <(String, FlarePluginActionPayload)>[];
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, set) {
              update = set;
              return FlarePluginView(
                view: view,
                busy: busy,
                onAction: (id, payload) => calls.add((id, payload)),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), '839271');
      update(() => busy = true);
      await tester.pump();
      await tester.pump();
      var panel = tester.widget<FlareRedPacketPayConfirm>(
        find.byType(FlareRedPacketPayConfirm),
      );
      expect(panel.busy, isTrue);
      expect(
        tester.widget<FlareInput>(find.byType(FlareInput)).disabled,
        isTrue,
      );
      panel.onCancel!();
      panel.onConfirm!();
      await tester.tapAt(const Offset(5, 5));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byType(FlareRedPacketPayConfirm), findsOneWidget);
      expect(calls, isEmpty);
      update(() => busy = false);
      await tester.pumpAndSettle();
      panel = tester.widget<FlareRedPacketPayConfirm>(
        find.byType(FlareRedPacketPayConfirm),
      );
      panel.onConfirm!();
      panel.onConfirm!();
      await tester.pumpAndSettle();
      expect(calls.single.$1, 'approve');
      expect(calls.single.$2.formValues, {'opaque-pin': '839271'});
      expect(find.byType(FlareRedPacketPayConfirm), findsNothing);
    },
  );

  for (final escape in [false, true]) {
    testWidgets(
      '${escape ? 'Escape' : 'scrim'} dismissal clears the payment PIN and leaves reopen',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final events = <String>[];
        await tester.pumpWidget(
          host(
            FlarePluginView(
              view: FlarePluginViewModel.fromJson(passwordPayment()),
              onAction: (id, _) => events.add(id),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), '839271');
        final controller = tester
            .widget<FlareInput>(find.byType(FlareInput))
            .controller!;
        if (escape) {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        } else {
          await tester.tapAt(const Offset(5, 5));
        }
        await tester.pumpAndSettle();
        expect(find.byType(FlareRedPacketPayConfirm), findsNothing);
        expect(controller.text, isEmpty);
        expect(events, isEmpty);
        await tester.tap(find.text('确认授权'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<FlareInput>(find.byType(FlareInput)).controller!.text,
          isEmpty,
        );
      },
    );
  }

  testWidgets(
    'redPacket.pay confirmation retains the original guarded request',
    (tester) async {
      final raw = fixture('payment');
      (raw['presentation'] as Map)['renderer'] = 'redPacket.pay';
      (raw['actions'] as List).first['confirm'] = '原声明确认';
      final events = <String>[];
      await tester.pumpWidget(
        host(
          FlarePluginView(
            view: FlarePluginViewModel.fromJson(raw),
            onAction: (id, _) => events.add(id),
          ),
        ),
      );
      await tester.pumpAndSettle();
      tester
          .widget<FlareRedPacketPayConfirm>(
            find.byType(FlareRedPacketPayConfirm),
          )
          .onConfirm!();
      await tester.pumpAndSettle();
      expect(events, isEmpty);
      expect(find.text('原声明确认'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(FlareDangerConfirm),
          matching: find.text('确认授权'),
        ),
      );
      await tester.pumpAndSettle();
      expect(events, ['approve']);
    },
  );

  testWidgets(
    'a newly unknown journal closes the confirmation and clears PIN',
    (tester) async {
      var raw = passwordPayment();
      late StateSetter update;
      final calls = <String>[];
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, set) {
              update = set;
              return FlarePluginView(
                view: FlarePluginViewModel.fromJson(raw),
                onAction: (id, _) => calls.add(id),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), '839271');
      final controller = tester
          .widget<FlareInput>(find.byType(FlareInput))
          .controller!;
      update(() {
        raw = passwordPayment();
        ((raw['presentation'] as Map)['props'] as Map)['journal'] = {
          'known': false,
        };
      });
      await tester.pumpAndSettle();
      expect(controller.text, isEmpty);
      expect(find.byType(FlareRedPacketPayConfirm), findsNothing);
      expect(calls, isEmpty);
    },
  );

  testWidgets(
    'payment sheet fits a narrow keyboard viewport without losing confirm',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          FlarePluginView(
            view: FlarePluginViewModel.fromJson(passwordPayment()),
            onAction: (_, _) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), '839271');
      await tester.ensureVisible(
        find.descendant(
          of: find.byType(FlareRedPacketPayConfirm),
          matching: find.text('确认授权'),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 1280.0]) {
    testWidgets(
      'payment confirmation opens an adaptive overlay at $width and cancel clears PIN',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final raw = fixture('payment');
        raw['inputs'] = [
          {
            'id': 'password',
            'kind': 'password',
            'label': '支付密码',
            'required': true,
            'maxLength': 6,
          },
        ];
        (raw['actions'] as List).first['form'] = ['password'];
        final events = <FlarePluginActionPayload>[];
        await tester.pumpWidget(
          host(
            FlarePluginView(
              view: FlarePluginViewModel.fromJson(raw),
              onAction: (_, p) => events.add(p),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.ancestor(
            of: find.byType(FlareRedPacketPayConfirm),
            matching: find.byType(FlareBottomSheet),
          ),
          findsOneWidget,
        );
        expect(
          find.byType(FlareModal),
          width == 1280 ? findsOneWidget : findsNothing,
        );
        await tester.enterText(find.byType(EditableText), '839271');
        await tester.pump();
        tester
            .widget<FlareRedPacketPayConfirm>(
              find.byType(FlareRedPacketPayConfirm),
            )
            .onCancel!();
        await tester.pumpAndSettle();
        expect(find.byType(FlareRedPacketPayConfirm), findsNothing);
        expect(events, isEmpty);
        await tester.tap(find.text('确认授权'));
        await tester.pumpAndSettle();
        final input = tester.widget<FlareInput>(find.byType(FlareInput));
        expect(input.controller!.text, isEmpty);
        expect(
          tester
              .widget<FlareRedPacketPayConfirm>(
                find.byType(FlareRedPacketPayConfirm),
              )
              .confirmDisabled,
          isTrue,
        );
      },
    );
  }

  testWidgets(
    'payment password is masked, required and cleared before dispatch',
    (tester) async {
      final raw = fixture('payment');
      raw['inputs'] = [
        {
          'id': 'password',
          'kind': 'password',
          'label': '支付密码',
          'required': true,
          'maxLength': 6,
        },
      ];
      (raw['actions'] as List).first['form'] = ['password'];
      final events = <FlarePluginActionPayload>[];
      await tester.pumpWidget(
        host(
          FlarePluginView(
            view: FlarePluginViewModel.fromJson(raw),
            onAction: (_, p) => events.add(p),
          ),
        ),
      );
      await tester.pumpAndSettle();
      var pay = tester.widget<FlareRedPacketPayConfirm>(
        find.byType(FlareRedPacketPayConfirm),
      );
      expect(pay.confirmDisabled, isTrue);
      final input = find.byType(FlareInput);
      expect(tester.widget<FlareInput>(input).secure, isTrue);
      await tester.enterText(
        find.descendant(of: input, matching: find.byType(EditableText)),
        '839271',
      );
      await tester.pump();
      pay = tester.widget<FlareRedPacketPayConfirm>(
        find.byType(FlareRedPacketPayConfirm),
      );
      final controller = tester.widget<FlareInput>(input).controller!;
      expect(pay.confirmDisabled, isFalse);
      pay.onConfirm!();
      pay.onConfirm!();
      await tester.pumpAndSettle();
      expect(events.single.formValues, {'password': '839271'});
      expect(controller.text, '');
      expect(find.byType(FlareRedPacketPayConfirm), findsNothing);
    },
  );

  testWidgets(
    'declared presentation uses the existing card and keeps its action ID',
    (tester) async {
      final events = <String>[];
      await tester.pumpWidget(
        host(
          FlarePluginView(
            view: FlarePluginViewModel.fromJson(fixture('card')),
            onAction: (id, payload) => events.add(id),
          ),
        ),
      );
      expect(find.byType(FlareRedPacketCard), findsOneWidget);
      await tester.tap(find.byType(FlareRedPacketCard));
      expect(events, ['open']);
    },
  );
  testWidgets('read-only presentation cannot invoke a card action', (
    tester,
  ) async {
    final raw = fixture('card');
    raw['actions'] = [];
    raw['unavailableReason'] = 'unbound_copy';
    (raw['presentation'] as Map)['actions'] = {};
    var called = false;
    await tester.pumpWidget(
      host(
        FlarePluginView(
          view: FlarePluginViewModel.fromJson(raw),
          onAction: (id, p) => called = true,
        ),
      ),
    );
    expect(
      tester
          .widget<FlareRedPacketCard>(find.byType(FlareRedPacketCard))
          .disabled,
      isTrue,
    );
    await tester.tap(find.byType(FlareRedPacketCard));
    expect(called, isFalse);
  });
  testWidgets(
    'authorization confirmation preserves a large decimal string and label',
    (tester) async {
      await tester.pumpWidget(
        host(
          FlarePluginView(
            view: FlarePluginViewModel.fromJson(fixture('payment')),
            onAction: (_, _) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final pay = tester.widget<FlareRedPacketPayConfirm>(
        find.byType(FlareRedPacketPayConfirm),
      );
      expect(pay.amount, '999999999999999999.99');
      expect(pay.confirmLabel, '确认授权');
    },
  );
  testWidgets(
    'unknown original payment is not offered for another confirmation',
    (tester) async {
      final raw = fixture('payment');
      ((raw['presentation'] as Map)['props'] as Map)['journal'] = {
        'known': false,
        'commandId': 'original',
      };
      await tester.pumpWidget(
        host(
          FlarePluginView(
            view: FlarePluginViewModel.fromJson(raw),
            onAction: (_, _) {},
          ),
        ),
      );
      expect(find.byType(FlareRedPacketPayConfirm), findsNothing);
    },
  );
  testWidgets(
    'failed submit blocks payment while the old journal projection is still visible',
    (tester) async {
      await tester.pumpWidget(
        host(
          FlarePluginView(
            view: FlarePluginViewModel.fromJson(fixture('payment')),
            error: 'Result not confirmed',
            onAction: (_, _) {},
          ),
        ),
      );
      expect(find.byType(FlareRedPacketPayConfirm), findsNothing);
    },
  );
  testWidgets('the composer opens directly and emits no funding selectors', (
    tester,
  ) async {
    final events = <(String, FlarePluginActionPayload)>[];
    await tester.pumpWidget(
      host(
        FlarePluginView(
          view: FlarePluginViewModel.fromJson(fixture('composer')),
          onAction: (id, p) => events.add((id, p)),
        ),
      ),
    );
    expect(find.byType(FlarePluginForm), findsNothing);
    var composer = tester.widget<FlareRedPacketComposer>(
      find.byType(FlareRedPacketComposer),
    );
    composer.onAmountChange!('0.23');
    composer.onCountChange!(2);
    await tester.pump();
    composer = tester.widget<FlareRedPacketComposer>(
      find.byType(FlareRedPacketComposer),
    );
    expect(composer.total, 'CNY 0.46');
    composer.onSubmit!();
    expect(events.single.$1, 'prepare');
    expect(events.single.$2.formValues, containsPair('decimalAmount', '0.23'));
    expect(events.single.$2.formValues, isNot(contains('sourceWalletId')));
    expect(events.single.$2.formValues, isNot(contains('assetId')));
    expect(events.single.$2.formValues, isNot(contains('lifetimeSeconds')));
  });
  test('page decode retains the presentation just like card decode', () {
    final page = FlarePluginPageViewModel.fromJson(fixture('payment'));
    expect(page.presentation?['renderer'], 'payment.confirm');
  });
}
