import 'dart:convert';
import 'dart:io';
import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flare_im_ui/src/components/flare_resolved_presentation.dart';
import 'package:flutter/material.dart';
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
    'the retired composer renderer draws the plain document (the red packet compose page is plain blocks)',
    (tester) async {
      final raw = fixture('composer');
      raw['blocks'] = [
        {'kind': 'text', 'text': 'Declarative body'},
      ];
      await tester.pumpWidget(
        host(FlarePluginView(view: FlarePluginViewModel.fromJson(raw))),
      );
      expect(find.byType(FlareRedPacketComposer), findsNothing);
      expect(find.text('Declarative body'), findsOneWidget);
    },
  );
  test('page decode retains the presentation just like card decode', () {
    final page = FlarePluginPageViewModel.fromJson(fixture('payment'));
    expect(page.presentation?['renderer'], 'payment.confirm');
  });
  testWidgets(
    'the retired payment renderers draw their document, never a pay sheet',
    (tester) async {
      for (final renderer in ['payment.confirm', 'redPacket.pay']) {
        final raw = fixture('payment');
        (raw['presentation'] as Map)['renderer'] = renderer;
        final view = FlarePluginViewModel.fromJson(raw);
        expect(flareHasResolvedPresentation(view), isFalse);
        await tester.pumpWidget(
          host(FlarePluginView(view: view, onAction: (_, _) {})),
        );
        await tester.pumpAndSettle();
        expect(find.byType(FlarePaymentConfirmation), findsNothing);
        expect(find.text('确认授权'), findsOneWidget);
      }
    },
  );
}
