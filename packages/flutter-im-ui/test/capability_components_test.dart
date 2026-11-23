import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

final Map<String, Object?> vectors =
    (jsonDecode(
              File('../../spec/capability-ui-vectors.json').readAsStringSync(),
            )
            as Map)
        .cast<String, Object?>();

List<Map<String, Object?>> cases(String section) => [
  for (final c in ((vectors[section] as Map)['cases'] as List))
    (c as Map).cast<String, Object?>(),
];

Uint8List hex(String text) => Uint8List.fromList([
  for (var i = 0; i + 1 < text.length; i += 2)
    int.parse(text.substring(i, i + 2), radix: 16),
]);

Widget host(Widget body, {FlareStrings strings = flareStringsEnglish}) =>
    MaterialApp(
      home: FlareStringsScope(
        strings: strings,
        child: Scaffold(body: SizedBox(height: 900, child: body)),
      ),
    );

void main() {
  group('capability vectors', () {
    test('consent decisions answer the engine', () {
      for (final c in cases('consentDecision')) {
        final answer = flareCapabilityConsentAnswer(
          FlareCapabilityConsentDecision.values.byName(c['decision'] as String),
        );
        expect(answer, c['answer']);
      }
    });
    test('capability labels', () {
      for (final c in cases('capabilityLabel')) {
        final params = (c['params'] as Map?)?.cast<String, Object?>();
        expect(
          flareCapabilityLabelKey(c['capability'] as String, params),
          c['key'],
        );
        expect(
          flareCapabilityLabel(
            flareStringsEnglish,
            c['capability'] as String,
            params,
          ),
          isNot(c['capability']),
        );
      }
      for (final c in cases('consentAllowsAlways')) {
        expect(
          flareCapabilityConsentAllowsAlways(c['capability'] as String),
          c['always'],
        );
      }
    });
    test('payment amount and countdown', () {
      for (final c in cases('paymentAmount')) {
        expect(
          flarePaymentAmountText(
            c['amount'] as String,
            c['currency'] as String,
          ),
          c['text'],
          reason: '${c['amount']} ${c['currency']}',
        );
      }
      for (final c in cases('paymentCountdown')) {
        final r = flarePaymentCountdown((c['remainingMs'] as num).toInt());
        expect(r.text, c['text']);
        expect(r.expired, c['expired']);
      }
    });
    test('document frame, plan, names and accept', () {
      for (final c in cases('documentFrame')) {
        expect(
          flareDocumentFrameAspect(
            FlareDocumentSide.values.byName(c['side'] as String),
          ),
          closeTo((c['aspect'] as num).toDouble(), 0.001),
        );
      }
      final compression = vectors['documentCompression'] as Map;
      expect(
        [
          for (final (edge, quality) in flareDocumentCompressionPlan)
            [edge, quality],
        ],
        [
          for (final step in compression['plan'] as List)
            [(step as List)[0], (step[1] as num).toDouble()],
        ],
      );
      for (final c in (compression['fileName'] as List).cast<Map>()) {
        expect(
          flareDocumentFileName(
            FlareDocumentSide.values.byName(c['side'] as String),
          ),
          c['name'],
        );
      }
      for (final c in cases('documentAccept')) {
        expect(
          flareDocumentAcceptsJpeg((c['accept'] as List).cast<String>()),
          c['ok'],
        );
      }
    });
    test('the stripped JPEG rule matches the engine', () {
      for (final c in cases('jpegStripped')) {
        expect(
          flareJpegIsStripped(hex(c['hex'] as String)),
          c['stripped'],
          reason: c['note'] as String?,
        );
      }
      final section = vectors['jpegStripped'] as Map<String, Object?>;
      for (final c in (section['strip'] as List).cast<Map<String, Object?>>()) {
        expect(
          flareJpegStrippingMetadata(hex(c['hex'] as String)),
          hex(c['out'] as String),
          reason: c['note'] as String?,
        );
      }
      for (final c in cases(
        'jpegStripped',
      ).where((c) => c['stripped'] == true)) {
        expect(
          flareJpegIsStripped(
            flareJpegStrippingMetadata(hex(c['hex'] as String)),
          ),
          isTrue,
        );
      }
    });
    test('protected media addresses', () {
      for (final c in cases('protectedMediaSource')) {
        expect(
          flarePluginProtectedMediaSource(c['url'] as String) != null,
          c['native'],
          reason: c['url'] as String,
        );
      }
    });
    test('location input values', () {
      for (final c in cases('locationInput')) {
        final fix = FlarePluginLocationValue.of(
          c['value'],
          FlarePluginLocationPrecision.values.byName(c['precision'] as String),
        );
        expect(fix != null, c['ok'], reason: '${c['value']}');
        if (fix != null) expect(fix.text, c['text']);
      }
    });
    test('the vocabulary reports what the kit serves', () {
      final native = PLUGIN_UI_VOCABULARY['native'] as List;
      for (final name in [
        'documentCapture',
        'paymentConfirmation',
        'locationOnce',
      ]) {
        expect(native, contains(name));
      }
      expect(
        PLUGIN_UI_VOCABULARY['renderers'],
        containsAll([
          'redPacket.card',
          'redPacket.compose',
          'redPacket.detail',
          'redPacket.review',
        ]),
      );
      expect(PLUGIN_UI_VOCABULARY['inputs'] as List, contains('location'));
      expect(
        PLUGIN_UI_VOCABULARY['blocks'] as List,
        contains('protected-media'),
      );
    });
  });

  test(
    'a photo with EXIF comes out as a JPEG without it, within the limit',
    () async {
      final source = img.Image(width: 3000, height: 2000);
      img.fill(source, color: img.ColorRgb8(200, 180, 160));
      source.exif.imageIfd['Orientation'] = 6;
      source.exif.imageIfd['Make'] = 'Camera';
      final original = img.encodeJpg(source, quality: 95);
      expect(flareJpegIsStripped(original), isFalse);
      final file = await flareProcessDocumentPhoto(
        original,
        FlareDocumentSide.front,
        maxBytes: 400 * 1024,
        accept: const ['image/jpeg'],
      );
      expect(file.fileName, 'document-front.jpg');
      expect(file.contentType, 'image/jpeg');
      expect(file.bytes.length, lessThanOrEqualTo(400 * 1024));
      expect(flareJpegIsStripped(file.bytes), isTrue);
      final decoded = img.decodeJpg(file.bytes)!;
      // Orientation 6 is baked in: the long edge is now the height.
      expect(decoded.height, greaterThan(decoded.width));
      expect(decoded.height, lessThanOrEqualTo(2048));
    },
  );

  test(
    'a photo the input does not accept or that cannot fit is refused',
    () async {
      await expectLater(
        flareProcessDocumentPhoto(
          Uint8List.fromList([1, 2, 3]),
          FlareDocumentSide.back,
          maxBytes: 1000,
          accept: const ['image/png'],
        ),
        throwsA(
          isA<FlareDocumentProcessException>().having(
            (e) => e.error,
            'error',
            FlareDocumentProcessError.notAccepted,
          ),
        ),
      );
      await expectLater(
        flareProcessDocumentPhoto(
          Uint8List.fromList([1, 2, 3]),
          FlareDocumentSide.back,
          maxBytes: 1000,
        ),
        throwsA(isA<FlareDocumentProcessException>()),
      );
    },
  );

  testWidgets(
    'consent names the plugin and capability and hands back the choice',
    (tester) async {
      final decisions = <FlareCapabilityConsentDecision>[];
      await tester.pumpWidget(
        host(
          FlareCapabilityConsent(
            pluginName: 'Realname',
            capability: 'documentCapture',
            purpose: 'Verify who you are',
            onDecide: decisions.add,
          ),
        ),
      );
      expect(find.text('The camera, to photograph a document'), findsOneWidget);
      expect(find.text('Verify who you are'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('flare-consent-always')));
      await tester.tap(find.byKey(const ValueKey('flare-consent-once')));
      await tester.tap(find.byKey(const ValueKey('flare-consent-deny')));
      expect(decisions, [
        FlareCapabilityConsentDecision.always,
        FlareCapabilityConsentDecision.once,
        FlareCapabilityConsentDecision.deny,
      ]);
      await tester.pumpWidget(
        host(
          const FlareCapabilityConsent(
            pluginName: 'Check-in',
            capability: 'locationOnce',
            params: {'precision': 'fine'},
          ),
        ),
      );
      expect(find.byKey(const ValueKey('flare-consent-always')), findsNothing);
    },
  );

  testWidgets(
    'document picking locks duplicates and discards a previous side result',
    (tester) async {
      final pending = Completer<Uint8List?>();
      var calls = 0;
      var side = FlareDocumentSide.front;
      late StateSetter change;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, update) {
              change = update;
              return FlareDocumentCapture(
                side: side,
                maxBytes: 1000000,
                pickPhoto: () {
                  calls++;
                  return pending.future;
                },
              );
            },
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('flare-doc-album')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('flare-doc-album')));
      await tester.pump();
      expect(calls, 1);
      change(() => side = FlareDocumentSide.back);
      await tester.pump();
      pending.complete(Uint8List.fromList([1, 2, 3]));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('flare-doc-review')), findsNothing);
      expect(
        find.text(flareStringsEnglish.documentCaptureFailed),
        findsNothing,
      );
    },
  );

  testWidgets('an initially expired payment notifies once', (tester) async {
    var expires = 0;
    await tester.pumpWidget(
      host(
        FlarePaymentConfirmation(
          order: FlarePaymentOrder(
            orderId: 'expired',
            amount: '0.01',
            currency: 'CNY',
            payee: 'Sandbox',
            title: 'Acceptance',
            expiresAtMs: FlareServerClock.nowMs() - 1000,
          ),
          onExpire: () => expires++,
        ),
      ),
    );
    expect(expires, 1);
    await tester.pump(const Duration(seconds: 3));
    expect(expires, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('payment confirmation draws the order and stops at expiry', (
    tester,
  ) async {
    var confirms = 0, expired = 0;
    final order = FlarePaymentOrder(
      orderId: 'ord-1',
      amount: '1234.50',
      currency: 'CNY',
      payee: 'Wallet',
      title: 'Red packet',
      expiresAtMs: FlareServerClock.nowMs() + 2500,
    );
    await tester.pumpWidget(
      host(
        FlarePaymentConfirmation(
          order: order,
          pluginName: 'Red Packet',
          onConfirm: () => confirms++,
          onExpire: () => expired++,
        ),
      ),
    );
    expect(find.text('¥1,234.50'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('flare-payment-countdown')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('flare-payment-confirm')));
    expect(confirms, 1);
  });

  testWidgets('payment confirmation refuses an amount it cannot read', (
    tester,
  ) async {
    var confirms = 0;
    await tester.pumpWidget(
      host(
        FlarePaymentConfirmation(
          order: FlarePaymentOrder(
            orderId: 'o',
            amount: '1e5',
            currency: 'CNY',
            payee: 'P',
            title: '',
            expiresAtMs: FlareServerClock.nowMs() + 60000,
          ),
          onConfirm: () => confirms++,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('flare-payment-confirm')));
    expect(confirms, 0);
    expect(
      find.text(flareStringsEnglish.paymentConfirmationInvalid),
      findsOneWidget,
    );
  });

  testWidgets('payment confirmation shows an already expired order', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        FlarePaymentConfirmation(
          order: FlarePaymentOrder(
            orderId: 'o',
            amount: '1',
            currency: 'CNY',
            payee: 'P',
            title: '',
            expiresAtMs: FlareServerClock.nowMs() - 1,
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('flare-payment-expired')), findsOneWidget);
  });

  FlarePaymentOrder payOrder({int inMs = 600000}) => FlarePaymentOrder(
    orderId: 'ord-42',
    amount: '26.64',
    currency: 'CNY',
    payee: 'Wallet',
    title: '',
    expiresAtMs: FlareServerClock.nowMs() + inMs,
  );

  testWidgets('insufficient: confirm is off, the shortfall reads above it, '
      'top up emits', (tester) async {
    var confirms = 0, topUps = 0;
    await tester.pumpWidget(
      host(
        FlarePaymentConfirmation(
          order: payOrder(),
          shortfall: '¥6.64',
          onConfirm: () => confirms++,
          onTopUp: () => topUps++,
        ),
      ),
    );
    expect(find.text('Not enough balance — ¥6.64 short'), findsOneWidget);
    final confirm = tester.widget<FlareButton>(
      find.byKey(const ValueKey('flare-payment-confirm')),
    );
    expect(confirm.disabled, isTrue);
    await tester.tap(
      find.byKey(const ValueKey('flare-payment-confirm')),
      warnIfMissed: false,
    );
    expect(confirms, 0);
    await tester.tap(find.byKey(const ValueKey('flare-payment-top-up')));
    expect(topUps, 1);
  });

  // §12.19: only a shortfall above zero counts.
  test('a shortfall owes something only above zero', () {
    for (final (text, owed) in const [
      ('¥6.64', true),
      ('0.01 CNY', true),
      ('¥0.00', false),
      ('0', false),
      ('', false),
      ('-¥1.00', false),
      ('−¥1.00', false),
    ]) {
      expect(flarePaymentShortfallOwed(text), owed, reason: text);
    }
    expect(flarePaymentShortfallOwed(null), isFalse);
  });

  testWidgets('a zero shortfall leaves the panel payable', (tester) async {
    var confirms = 0;
    await tester.pumpWidget(
      host(
        FlarePaymentConfirmation(
          order: payOrder(),
          shortfall: '¥0.00',
          onConfirm: () => confirms++,
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('flare-payment-insufficient')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('flare-payment-top-up')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('flare-payment-confirm')));
    expect(confirms, 1);
  });

  testWidgets('cancel is a secondary key', (tester) async {
    await tester.pumpWidget(host(FlarePaymentConfirmation(order: payOrder())));
    expect(
      tester
          .widget<FlareButton>(
            find.byKey(const ValueKey('flare-payment-cancel')),
          )
          .variant,
      FlareButtonVariant.secondary,
    );
  });

  testWidgets('the PIN cells fit a 320-wide panel, never under 36', (
    tester,
  ) async {
    for (final (width, cell) in const [
      // 320 less the panel's 16 gutters: (288 − 5 × 8) / 6.
      (320.0, (288 - 40) / 6),
      // Narrower than six 36s and five 8s: the cells hold 36, the gaps give.
      (264.0, 36.0),
    ]) {
      await tester.pumpWidget(
        host(
          Center(
            child: SizedBox(
              width: width,
              child: FlarePaymentConfirmation(
                order: payOrder(),
                credential: const FlarePinInput(
                  label: '支付密码',
                  autoFocus: false,
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: '$width');
      await tester.enterText(find.byType(TextField), '1');
      await tester.pump();
      final box = find
          .ancestor(
            of: find.byKey(FlarePinInput.dotKey(0)),
            matching: find.byType(Container),
          )
          .first;
      expect(tester.getSize(box).width, closeTo(cell, 0.01), reason: '$width');
    }
  });

  testWidgets('short of room (the keyboard up) the keys stay on screen and '
      'the password cells stay in view', (tester) async {
    await tester.pumpWidget(
      host(
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 360,
            height: 300,
            child: FlarePaymentConfirmation(
              order: payOrder(),
              error: 'wrong',
              credential: const FlarePinInput(label: '支付密码', autoFocus: false),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    for (final key in ['flare-payment-confirm', 'flare-payment-cancel']) {
      final rect = tester.getRect(find.byKey(ValueKey(key)));
      expect(rect.bottom, lessThanOrEqualTo(300), reason: key);
      expect(rect.top, greaterThanOrEqualTo(0), reason: key);
    }
    final pin = tester.getRect(find.byType(FlarePinInput));
    final confirm = tester.getRect(
      find.byKey(const ValueKey('flare-payment-confirm')),
    );
    expect(pin.bottom, lessThan(confirm.top));
    expect(pin.top, greaterThanOrEqualTo(0));
  });

  testWidgets('the order number folds into a row and copies when open', (
    tester,
  ) async {
    final copied = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') copied.add(call.arguments);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(host(FlarePaymentConfirmation(order: payOrder())));
    expect(find.byType(ExpansionTile), findsNothing);
    expect(find.text('ord-42'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('flare-payment-order-toggle')));
    await tester.pump();
    expect(find.text('ord-42'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('flare-payment-order-copy')));
    await tester.pump();
    expect(copied, [
      {'text': 'ord-42'},
    ]);
  });

  testWidgets('under a minute left the countdown turns to warning', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(FlarePaymentConfirmation(order: payOrder(inMs: 30000))),
    );
    final countdown = tester.widget<Text>(
      find.byKey(const ValueKey('flare-payment-countdown')),
    );
    expect(countdown.style!.color, FlareColors.light.warningText);
  });

  testWidgets('expired: the amount greys and the key starts again', (
    tester,
  ) async {
    final events = <String>[];
    Widget panel({bool startAgain = true}) => host(
      FlarePaymentConfirmation(
        order: payOrder(inMs: -1),
        onCancel: () => events.add('cancel'),
        onStartAgain: startAgain ? () => events.add('startAgain') : null,
      ),
    );
    await tester.pumpWidget(panel());
    final amount = tester.widget<Text>(
      find.byKey(const ValueKey('flare-payment-amount')),
    );
    expect(amount.style!.color, FlareColors.light.textDisabled);
    expect(amount.style!.fontSize, FlareSizes.componentAmountHeroFontSize);
    await tester.tap(find.text('Start again'));
    expect(events, ['startAgain']);
    await tester.pumpWidget(panel(startAgain: false));
    await tester.tap(find.text('Start again'));
    expect(events, ['startAgain', 'cancel']);
    // No password and no earlier failure on an order that cannot be paid.
    await tester.pumpWidget(
      host(
        FlarePaymentConfirmation(
          order: payOrder(inMs: -1),
          credential: const Text('PIN'),
          error: 'wrong password',
        ),
      ),
    );
    expect(find.text('PIN'), findsNothing);
    expect(find.text('wrong password'), findsNothing);
  });

  testWidgets('the panel reads title, requester, amount, details, countdown, '
      'credential, then the key', (tester) async {
    await tester.pumpWidget(
      host(
        FlarePaymentConfirmation(
          order: payOrder(),
          pluginName: 'Red Packet',
          credential: const Text('PIN'),
        ),
      ),
    );
    double top(Finder f) => tester.getTopLeft(f).dy;
    final order = [
      find.text('Confirm payment'),
      find.text('Requested by “Red Packet”'),
      find.byKey(const ValueKey('flare-payment-amount')),
      find.byKey(const ValueKey('flare-payment-payee')),
      find.byKey(const ValueKey('flare-payment-countdown')),
      find.text('PIN'),
      find.byKey(const ValueKey('flare-payment-confirm')),
    ];
    for (var i = 1; i < order.length; i++) {
      expect(top(order[i]), greaterThan(top(order[i - 1])));
    }
    final title = tester.widget<Text>(find.text('Confirm payment'));
    expect(title.style!.fontSize, FlareSizes.fontSizeXl);
    expect(title.style!.fontWeight, FontWeight.w600);
    expect(title.textAlign, TextAlign.center);
  });

  for (final width in [700.0, 1280.0]) {
    testWidgets('show() is a centred 400-wide dialog $width wide', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => FlarePaymentConfirmation.show<void>(
                  context,
                  builder: (_) => FlarePaymentConfirmation(order: payOrder()),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final modal = find.byType(FlareModal);
      expect(modal, findsOneWidget);
      expect(
        tester.widget<FlareModal>(modal).width,
        FlareSizes.componentPaymentDialogWidth,
      );
      final panel = find.byType(FlarePaymentConfirmation);
      // The dialog's 1px border sits inside its 400.
      expect(tester.getSize(panel).width, closeTo(400, 2));
      expect(tester.getCenter(panel).dx, width / 2);
    });
  }

  testWidgets('a busy panel cannot be closed by back or the scrim', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => FlarePaymentConfirmation.show<void>(
                context,
                builder: (_) =>
                    FlarePaymentConfirmation(order: payOrder(), busy: true),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tapAt(const Offset(8, 8));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(FlarePaymentConfirmation), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(FlarePaymentConfirmation), findsOneWidget);
  });

  testWidgets('the countdown is not a live region; the expiry is', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(FlarePaymentConfirmation(order: payOrder())));
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('flare-payment-countdown')))
          .flagsCollection
          .isLiveRegion,
      isFalse,
    );
    await tester.pumpWidget(
      host(FlarePaymentConfirmation(order: payOrder(inMs: -1))),
    );
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('flare-payment-expired')))
          .flagsCollection
          .isLiveRegion,
      isTrue,
    );
    semantics.dispose();
  });

  testWidgets('document capture frames the side over the host preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        FlareDocumentCapture(
          side: FlareDocumentSide.holding,
          maxBytes: 1000000,
          preview: const ColoredBox(
            key: ValueKey('host-preview'),
            color: Colors.grey,
          ),
          capture: () async => null,
          pickPhoto: () async => null,
          cameraUnavailable: true,
        ),
      ),
    );
    expect(find.byKey(const ValueKey('host-preview')), findsOneWidget);
    final frame = tester.widget<AspectRatio>(
      find.byKey(const ValueKey('flare-doc-frame')),
    );
    expect(frame.aspectRatio, 0.75);
    expect(find.byKey(const ValueKey('flare-doc-shoot')), findsNothing);
    expect(find.byKey(const ValueKey('flare-doc-album')), findsOneWidget);
    // §6.4: camera-off 32 and the line inside the frame.
    final inFrame = find.byKey(const ValueKey('flare-doc-frame'));
    final icon = tester.widget<FlareIcon>(
      find.descendant(of: inFrame, matching: find.byType(FlareIcon)),
    );
    expect((icon.name, icon.size), ('camera-off', FlareSizes.iconSizeXl));
    expect(
      find.descendant(
        of: inFrame,
        matching: find.text(
          flareStringsEnglish.documentCaptureCameraUnavailable,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('document capture: album | shutter | cancel in one row, an '
      'ID-1 frame, the hints; cancel and Esc call onCancel', (tester) async {
    var cancels = 0;
    await tester.pumpWidget(
      host(
        FlareDocumentCapture(
          side: FlareDocumentSide.front,
          maxBytes: 1000000,
          capture: () async => null,
          pickPhoto: () async => null,
          onCancel: () => cancels++,
        ),
      ),
    );
    await tester.pump();
    Offset at(String key) => tester.getCenter(find.byKey(ValueKey(key)));
    final (album, shoot, cancel) = (
      at('flare-doc-album'),
      at('flare-doc-shoot'),
      at('flare-doc-cancel'),
    );
    expect(album.dy, moreOrLessEquals(shoot.dy));
    expect(cancel.dy, moreOrLessEquals(shoot.dy));
    expect(album.dx, lessThan(shoot.dx));
    expect(shoot.dx, lessThan(cancel.dx));
    expect(
      tester.getSize(find.byKey(const ValueKey('flare-doc-shoot'))),
      const Size.square(FlareSizes.componentCaptureShutterSize),
    );
    expect(
      find.bySemanticsLabel(flareStringsEnglish.documentCaptureShoot),
      findsOneWidget,
    );
    // A phone window (800 < breakpoints.md): the album, not a file.
    expect(find.text(flareStringsEnglish.documentCaptureFromAlbum), findsOne);
    final frame = tester.getSize(find.byKey(const ValueKey('flare-doc-frame')));
    expect(
      frame.width / frame.height,
      moreOrLessEquals(FlareSizes.componentDocumentFrameRatio, epsilon: .01),
    );
    expect(frame.width, lessThanOrEqualTo(800 - 2 * FlareSizes.spacing2xl));
    expect(find.text(flareStringsEnglish.documentCaptureHintFront), findsOne);
    expect(find.text(flareStringsEnglish.documentCaptureHintGlare), findsOne);
    await tester.tap(find.byKey(const ValueKey('flare-doc-cancel')));
    expect(cancels, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(cancels, 2);
  });

  testWidgets('document capture: Space shoots, processing spins in the frame, '
      'an error is a danger banner over the viewfinder', (tester) async {
    final pending = Completer<Uint8List?>();
    await tester.pumpWidget(
      host(
        FlareDocumentCapture(
          side: FlareDocumentSide.back,
          maxBytes: 1000000,
          // Not a JPEG input: processing refuses before any decoding.
          accept: const ['application/pdf'],
          capture: () => pending.future,
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    final frame = find.byKey(const ValueKey('flare-doc-frame'));
    expect(
      find.descendant(
        of: frame,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: frame,
        matching: find.text(flareStringsEnglish.documentCaptureProcessing),
      ),
      findsOneWidget,
    );
    pending.complete(Uint8List.fromList([1, 2, 3]));
    await tester.pumpAndSettle();
    final banner = find.byKey(const ValueKey('flare-doc-error'));
    final drawn = tester.widget<FlareStatusBanner>(banner);
    expect(drawn.tone, FlareStatusTone.danger);
    expect(drawn.text, flareStringsEnglish.documentCaptureNotAccepted);
    expect(
      tester.getBottomLeft(banner).dy,
      lessThan(tester.getTopLeft(frame).dy),
    );
    expect(find.byKey(const ValueKey('flare-doc-shoot')), findsOneWidget);
    expect(find.text(flareStringsEnglish.documentCaptureHintBack), findsOne);
  });

  testWidgets('document capture review: retake | use side by side, Enter '
      'uses the photo', (tester) async {
    final photo = Uint8List.fromList(
      img.encodeJpg(img.Image(width: 64, height: 40)),
    );
    final done = <FlareCapturedDocument>[];
    await tester.pumpWidget(
      host(
        FlareDocumentCapture(
          side: FlareDocumentSide.front,
          maxBytes: 1000000,
          pickPhoto: () async => photo,
          onDone: done.add,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('flare-doc-album')));
    final use = find.byKey(const ValueKey('flare-doc-use'));
    // The photo is processed on an isolate: give it real time.
    for (var i = 0; i < 50 && use.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(find.byKey(const ValueKey('flare-doc-review')), findsOneWidget);
    final retake = find.byKey(const ValueKey('flare-doc-retake'));
    final (left, right) = (tester.getCenter(retake), tester.getCenter(use));
    expect(left.dy, moreOrLessEquals(right.dy));
    expect(left.dx, lessThan(right.dx));
    expect(
      tester.getSize(retake).width,
      moreOrLessEquals(tester.getSize(use).width),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(done.single.fileName, 'document-front.jpg');
    expect(find.byKey(const ValueKey('flare-doc-review')), findsNothing);
  });

  testWidgets('document capture in a PC window: a 560 dialog, a 16:10 '
      'picture, choose file', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: FlareStringsScope(
          strings: flareStringsEnglish,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => FlareDocumentCapture.show<void>(
                context,
                side: FlareDocumentSide.front,
                builder: (_) => FlareDocumentCapture(
                  side: FlareDocumentSide.front,
                  maxBytes: 1000000,
                  preview: const SizedBox.expand(key: ValueKey('host-preview')),
                  capture: () async => null,
                  pickPhoto: () async => null,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(FlareDocumentCapture)).width,
      FlareSizes.componentCapturePreviewWidth,
    );
    final picture = tester.getSize(find.byKey(const ValueKey('host-preview')));
    expect(picture.width / picture.height, moreOrLessEquals(16 / 10));
    expect(find.text(flareStringsEnglish.pluginFileChoose), findsOne);
  });

  group('location input', () {
    const place = FlarePluginInput(
      id: 'place',
      kind: FlarePluginInputKind.location,
      label: 'Where',
      required: true,
      precision: FlarePluginLocationPrecision.coarse,
    );
    const fix = FlarePluginLocationValue(
      latitude: 31.23,
      longitude: 121.47,
      accuracyM: 1000,
      precision: FlarePluginLocationPrecision.coarse,
    );

    testWidgets('locates through the host and submits the fix', (tester) async {
      final actions = <FlarePluginLocationAction>[];
      final submitted = <Map<String, Object?>>[];
      Widget form(Map<String, FlarePluginLocationState> states) => host(
        FlarePluginForm(
          inputs: const [place],
          locationStates: states,
          onLocationAction: actions.add,
          onSubmit: submitted.add,
        ),
      );
      await tester.pumpWidget(form(const {}));
      expect(
        find.byKey(const ValueKey('flare-plugin-location-empty')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('flare-plugin-location-locate')),
      );
      expect(actions.single.action, FlarePluginLocationActionKind.locate);
      await tester.pumpWidget(
        form(const {'place': FlarePluginLocationState(value: fix)}),
      );
      expect(find.text('31.23°N, 121.47°E'), findsOneWidget);
      await tester.tap(find.text(flareStringsEnglish.pluginViewSubmit).last);
      await tester.pump();
      expect(submitted.single['place'], fix.toJson());
    });

    test('a fix of another precision is no value', () {
      expect(
        flarePluginDraftValue(
          const FlarePluginInput(
            id: 'place',
            kind: FlarePluginInputKind.location,
            label: 'Where',
            precision: FlarePluginLocationPrecision.fine,
          ),
          {'place': fix.toJson()},
        ),
        isNull,
      );
      expect(flarePluginCheckInput(place, null), FlarePluginFormIssue.required);
    });
  });

  group('protected media', () {
    FlarePluginProtectedMediaBlock block({String? reasonInput}) =>
        FlarePluginBlock.fromJson({
              'kind': 'protected-media',
              'label': 'My documents',
              'items': [
                {
                  'id': 'm1',
                  'label': 'Front',
                  'mediaType': 'image/jpeg',
                  'input': {'applicationId': 'a1'},
                },
              ],
              'action': {'id': 'viewDocument', 'label': 'View document'},
              'inputName': 'materialId',
              'reasonInput': ?reasonInput,
              'urlPath': '/url',
            })
            as FlarePluginProtectedMediaBlock;

    testWidgets('the owner reads with one tap', (tester) async {
      final reads = <FlarePluginProtectedMediaRead>[];
      await tester.pumpWidget(
        host(FlarePluginProtectedMediaView(block: block(), onRead: reads.add)),
      );
      expect(
        find.text(flareStringsEnglish.pluginProtectedMediaOwnNotice),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('flare-protected-media-read-m1')),
      );
      await tester.pump();
      expect(reads.single.formValues, {'materialId': 'm1'});
      expect(reads.single.reason, '');
    });

    testWidgets('a console read asks why first', (tester) async {
      final reads = <FlarePluginProtectedMediaRead>[];
      await tester.pumpWidget(
        host(
          FlarePluginProtectedMediaView(
            block: block(reasonInput: 'reason'),
            onRead: reads.add,
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('flare-protected-media-read-m1')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).last, 'audit 12');
      await tester.tap(find.text('View document').last);
      await tester.pumpAndSettle();
      expect(reads.single.formValues, {
        'materialId': 'm1',
        'reason': 'audit 12',
      });
    });

    testWidgets('only an https grant address or data:image is drawn', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FlarePluginProtectedMediaView(
            block: block(),
            states: const {
              'm1': FlarePluginProtectedMediaState(url: 'http://x/y?grant=1'),
            },
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('flare-protected-media-image-m1')),
        findsNothing,
      );
      expect(
        flarePluginProtectedMediaUrl({'url': 'https://h/p?grant=g'}, '/url'),
        'https://h/p?grant=g',
      );
    });
  });
}
