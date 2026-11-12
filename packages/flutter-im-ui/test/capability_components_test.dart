import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
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
        expect(answer.granted, c['granted']);
        expect(answer.remember, c['remember']);
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
    test('EXIF detection matches the engine', () {
      for (final c in cases('jpegExif')) {
        expect(flareJpegHasExif(hex(c['hex'] as String)), c['exif']);
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
      expect(PLUGIN_UI_VOCABULARY['renderers'], ['redPacket.card']);
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
      expect(flareJpegHasExif(original), isTrue);
      final file = await flareProcessDocumentPhoto(
        original,
        FlareDocumentSide.front,
        maxBytes: 400 * 1024,
        accept: const ['image/jpeg'],
      );
      expect(file.fileName, 'document-front.jpg');
      expect(file.contentType, 'image/jpeg');
      expect(file.bytes.length, lessThanOrEqualTo(400 * 1024));
      expect(flareJpegHasExif(file.bytes), isFalse);
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
