import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'wallet_composition_test.dart' as review;

Map<String, Object?> cashflowCase(
  String id,
  String variant, {
  String locale = 'zh-CN',
}) =>
    ((jsonDecode(
                  File(
                    '../../spec/wallet-cashflow-vectors.json',
                  ).readAsStringSync(),
                )
                as Map)['cases']
            as List)
        .cast<Map>()
        .singleWhere(
          (item) =>
              item['id'] == id &&
              item['variant'] == variant &&
              item['locale'] == locale,
        )
        .cast<String, Object?>();

FlarePluginPageViewModel resolved(
  Map<String, Object?> vector,
) => FlarePluginPageViewModel.fromJson({
  ...(vector['view'] as Map).cast<String, Object?>(),
  // SDK page hosts carry the original read data alongside the resolved view.
  'data': vector['sourceData'],
});

void main() {
  for (final width in [320.0, 1440.0]) {
    testWidgets(
      'resolved cashflow forms preserve their declared order at $width',
      (tester) async {
        review.surface(tester, width, height: width == 320 ? 1600 : 1100);
        await review.fonts(tester);
        for (final id in ['recharge', 'withdrawal', 'payout_profiles']) {
          final vector = cashflowCase(id, 'available');
          final view = resolved(vector);
          final props = (view.presentation!['props'] as Map);
          final calls = <FlarePluginPageActionPayload>[];
          final captureKey = GlobalKey();
          await tester.pumpWidget(
            review.host(
              RepaintBoundary(
                key: captureKey,
                child: review.page(
                  view,
                  onAction: (_, payload) => calls.add(payload),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final form = tester.widget<FlarePluginForm>(
            find.byType(FlarePluginForm),
          );
          final submit = view.actions.singleWhere(
            (action) => action.form.isNotEmpty,
          );
          expect(form.embedded, isTrue);
          expect(form.inputs.map((input) => input.id), submit.form, reason: id);
          expect(find.text(props['formTitle'] as String), findsOneWidget);
          expect(
            tester
                .getSize(
                  find.byKey(const ValueKey('flare-plugin-inline-form-region')),
                )
                .width,
            lessThanOrEqualTo(FlareSizes.primaryPaneMaxWidth),
          );
          expect(
            find.byKey(const ValueKey('flare-account-result')),
            findsNothing,
          );
          expect(calls, isEmpty, reason: 'Rendering must never submit $id');
          await tester.ensureVisible(
            find.byKey(const ValueKey('flare-plugin-form-submit')),
          );
          expect(tester.takeException(), isNull, reason: id);
          if (id == 'withdrawal') {
            await tester.ensureVisible(find.text(props['formTitle'] as String));
            await review.capture(
              tester,
              captureKey,
              'flutter-wallet-cashflow-withdrawal-${width.toInt()}',
            );
          }
          await tester.pumpWidget(const SizedBox());
        }
      },
    );

    testWidgets(
      'resolved unavailable reasons remain single and actionable at $width',
      (tester) async {
        review.surface(tester, width);
        for (final (id, variant, locale) in [
          ('recharge', 'no_channel', 'en-US'),
          ('withdrawal', 'closed', 'zh-CN'),
          ('payout_profiles', 'closed', 'zh-CN'),
          ('withdrawal_authorization', 'closed_prepared', 'en-US'),
        ]) {
          final view = resolved(cashflowCase(id, variant, locale: locale));
          final reasons = view.blocks.whereType<FlarePluginStatusBlock>().where(
            (block) =>
                block.text.trim().isNotEmpty &&
                (block.tone == FlarePluginTone.warning ||
                    block.tone == FlarePluginTone.danger),
          );
          expect(
            reasons,
            isNotEmpty,
            reason: '$id/$variant must explain unavailability',
          );
          await tester.pumpWidget(
            review.host(
              MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 1200),
                  textScaler: TextScaler.linear(width == 320 ? 1.4 : 1),
                ),
                child: review.page(view, onAction: (_, _) {}),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(FlarePluginForm), findsNothing);
          expect(
            find.byKey(const ValueKey('flare-account-result')),
            findsNothing,
          );
          for (final reason in reasons) {
            expect(find.text(reason.text), findsOneWidget);
            if (width == 320) {
              final text = tester.widget<Text>(find.text(reason.text));
              expect(text.maxLines, isNull);
              expect(text.overflow, isNot(TextOverflow.ellipsis));
            } else {
              expect(
                find.descendant(
                  of: find.byKey(const ValueKey('flare-plugin-status')),
                  matching: find.byType(FlareTag),
                ),
                findsOneWidget,
              );
            }
          }
          expect(
            tester.takeException(),
            isNull,
            reason: '$id/$variant/$locale',
          );
          await tester.pumpWidget(const SizedBox());
        }
      },
    );
  }

  testWidgets(
    'resolved results retain each declared outcome and recovery entry',
    (tester) async {
      review.surface(tester, 320);
      for (final variant in ['pending', 'unknown', 'succeeded', 'failed']) {
        final view = resolved(cashflowCase('cashflow_detail', variant));
        final props = view.presentation!['props'] as Map;
        await tester.pumpWidget(
          review.host(review.page(view, onAction: (_, _) {})),
        );
        await tester.pumpAndSettle();
        final banner = tester.widget<FlareStatusBanner>(
          find.byKey(const ValueKey('flare-account-result')),
        );
        expect(
          banner.text,
          '${props['resultTitle']}\n${props['resultDescription']}',
        );
        expect(banner.tone.name, props['resultTone']);
        expect(find.byType(FlarePluginForm), findsNothing);
        for (final action in view.actions) {
          expect(
            find.byKey(ValueKey('flare-plugin-action-${action.id}')),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull, reason: variant);
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets(
    'resolved recovery does not fabricate success or submit on mount',
    (tester) async {
      final calls = <String>[];
      for (final variant in ['legacy_unknown', 'known_rejection']) {
        final view = resolved(cashflowCase('cashflow_recovery', variant));
        await tester.pumpWidget(
          review.host(review.page(view, onAction: (id, _) => calls.add(id))),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('flare-account-result')),
          findsNothing,
        );
        expect(find.byType(FlarePluginForm), findsNothing);
        for (final action in view.actions) {
          expect(
            find.byKey(ValueKey('flare-plugin-action-${action.id}')),
            findsOneWidget,
          );
        }
        expect(calls, isEmpty);
        expect(tester.takeException(), isNull, reason: variant);
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets(
    'resolved payout save failure preserves entered data and error once',
    (tester) async {
      review.surface(tester, 390);
      final vector = cashflowCase('payout_profiles', 'available');
      final view = resolved(vector);
      final calls = <FlarePluginPageActionPayload>[];
      String? error;
      var settle = 0;
      late StateSetter rebuild;
      await tester.pumpWidget(
        review.host(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return review.page(
                view,
                error: error,
                settle: settle,
                onAction: (_, payload) => calls.add(payload),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final form = tester.widget<FlarePluginForm>(find.byType(FlarePluginForm));
      final values = <String, String>{};
      for (final input in form.inputs) {
        final field = find.descendant(
          of: find.byKey(ValueKey('flare-plugin-input-${input.id}')),
          matching: find.byType(EditableText),
        );
        if (field.evaluate().isNotEmpty) {
          final value = 'synthetic-${input.id}';
          values[input.id] = value;
          await tester.ensureVisible(field);
          await tester.enterText(field, value);
        }
      }
      final submit = find.byKey(const ValueKey('flare-plugin-form-submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      expect(calls, hasLength(1));
      expect(calls.single.data, vector['sourceData']);
      for (final entry in values.entries) {
        expect(calls.single.formValues?[entry.key], entry.value);
      }
      rebuild(() {
        error = '收款资料需要调整';
        settle++;
      });
      await tester.pumpAndSettle();
      expect(find.text('收款资料需要调整'), findsOneWidget);
      expect(
        tester.widget<FlarePluginForm>(find.byType(FlarePluginForm)).busy,
        isFalse,
      );
      for (final entry in values.entries) {
        final field = find.descendant(
          of: find.byKey(ValueKey('flare-plugin-input-${entry.key}')),
          matching: find.byType(EditableText),
        );
        expect(tester.widget<EditableText>(field).controller.text, entry.value);
      }
      expect(tester.takeException(), isNull);
    },
  );
}
