import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

FlarePluginViewModel payment() {
  final raw =
      (jsonDecode(
                File(
                  '../../spec/financial-presentation-vectors.json',
                ).readAsStringSync(),
              )['payment']
              as Map)
          .cast<String, Object?>();
  raw['inputs'] = [
    {
      'id': 'pin',
      'kind': 'password',
      'label': 'Payment PIN',
      'required': true,
      'maxLength': 6,
    },
  ];
  (raw['actions'] as List).first['form'] = ['pin'];
  return FlarePluginViewModel.fromJson(raw);
}

class _Flow {
  final navigator = GlobalKey<NavigatorState>();
  final calls = <FlarePluginActionPayload>[];
  late BuildContext page;
  late StateSetter update;
  String? error;
  int settled = 0;
}

Future<_Flow> open(
  WidgetTester tester, {
  void Function(_Flow)? submitted,
}) async {
  final flow = _Flow(), view = payment();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: flow.navigator,
      home: const Scaffold(body: Text('Owning conversation')),
    ),
  );
  unawaited(
    flow.navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: StatefulBuilder(
            builder: (context, update) {
              flow.page = context;
              flow.update = update;
              return SingleChildScrollView(
                child: FlarePluginView(
                  key: const ValueKey('payment-checkout-kit'),
                  view: view,
                  error: flow.error,
                  settleToken: flow.settled,
                  onAction: (_, payload) {
                    flow.calls.add(payload);
                    submitted?.call(flow);
                  },
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(EditableText), '839271');
  await tester.pump();
  return flow;
}

void main() {
  testWidgets(
    'a synchronous success runs after the real payment overlay exits and returns to chat once',
    (tester) async {
      var overlayGone = false;
      bool? goneWhenDispatched, ownerCurrentWhenDispatched;
      final flow = await open(
        tester,
        submitted: (flow) {
          goneWhenDispatched = overlayGone;
          ownerCurrentWhenDispatched = ModalRoute.of(flow.page)?.isCurrent;
          flow.navigator.currentState!.pop();
        },
      );
      final panel = tester.widget<FlareRedPacketPayConfirm>(
        find.byType(FlareRedPacketPayConfirm),
      );
      final route = ModalRoute.of(
        tester.element(find.byType(FlareRedPacketPayConfirm)),
      )!;
      unawaited(route.completed.then((_) => overlayGone = true));
      panel.onConfirm!();
      panel.onConfirm!();
      expect(
        flow.calls,
        isEmpty,
        reason: 'no dispatch while the overlay is departing',
      );
      await tester.pumpAndSettle();
      expect(goneWhenDispatched, isTrue);
      expect(ownerCurrentWhenDispatched, isTrue);
      expect(flow.calls.single.formValues, {'pin': '839271'});
      expect(find.text('Owning conversation'), findsOneWidget);
      expect(find.byType(FlarePluginView), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a password rejection remains on the payment page with its explicit error',
    (tester) async {
      final flow = await open(
        tester,
        submitted: (flow) => flow.update(() {
          flow.error = 'Payment password incorrect';
          flow.settled++;
        }),
      );
      tester
          .widget<FlareRedPacketPayConfirm>(
            find.byType(FlareRedPacketPayConfirm),
          )
          .onConfirm!();
      await tester.pumpAndSettle();
      expect(flow.calls, hasLength(1));
      expect(
        find.byKey(const ValueKey('payment-checkout-kit')),
        findsOneWidget,
      );
      expect(find.text('Payment password incorrect'), findsOneWidget);
      expect(find.byType(FlareRedPacketPayConfirm), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a newer unrelated route prevents the departing confirmation from dispatching or closing it',
    (tester) async {
      final flow = await open(
        tester,
        submitted: (flow) => flow.navigator.currentState!.pop(),
      );
      tester
          .widget<FlareRedPacketPayConfirm>(
            find.byType(FlareRedPacketPayConfirm),
          )
          .onConfirm!();
      unawaited(
        flow.navigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Unrelated page')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(flow.calls, isEmpty);
      expect(find.text('Unrelated page'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancel dismisses the password overlay without dispatching', (
    tester,
  ) async {
    final flow = await open(tester);
    tester
        .widget<FlareRedPacketPayConfirm>(find.byType(FlareRedPacketPayConfirm))
        .onCancel!();
    await tester.pumpAndSettle();
    expect(flow.calls, isEmpty);
    expect(find.byKey(const ValueKey('payment-checkout-kit')), findsOneWidget);
    expect(find.byType(FlareRedPacketPayConfirm), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
