import 'dart:convert';
import 'dart:io';
import 'package:flare_im_ui/flare_im_ui.dart';
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
