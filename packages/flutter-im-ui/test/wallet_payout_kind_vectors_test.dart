import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _cases =
    ((jsonDecode(
                  File(
                    '../../spec/wallet-payout-kind-vectors.json',
                  ).readAsStringSync(),
                )
                as Map)['cases']
            as List)
        .cast<Map>();

FlarePluginPageViewModel _view(Map vector) =>
    FlarePluginPageViewModel.fromJson({
      ...(vector['view'] as Map).cast<String, Object?>(),
      'data': vector['sourceData'],
    });

Widget _host(
  FlarePluginPageViewModel view,
  FlarePluginPageActionCallback onAction,
) => MaterialApp(
  home: Scaffold(
    body: FlarePluginPage(
      page: const FlarePluginPageRef(
        pluginId: 'fixture.wallet',
        page: 'fixture.payout-profiles',
      ),
      view: view,
      onAction: onAction,
    ),
  ),
);

void main() {
  for (final vector in _cases) {
    testWidgets(
      '032 payout ${vector['variant']} ${vector['locale']} keeps resolved choices and existing profiles',
      (tester) async {
        final narrow = vector['locale'] == 'zh-CN';
        tester.view.physicalSize = Size(narrow ? 320 : 1440, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final calls = <(String, FlarePluginPageActionPayload)>[];
        final view = _view(vector);
        await tester.pumpWidget(
          _host(view, (id, payload) => calls.add((id, payload))),
        );
        await tester.pumpAndSettle();
        expect(find.text('Example owner'), findsOneWidget);
        expect(calls, isEmpty, reason: 'Mounting a resolved page never writes');
        final existing = view.blocks
            .whereType<FlarePluginRowsBlock>()
            .single
            .rows
            .single;
        expect(existing.key, 'fixture-existing-bank');
        expect(existing.actions.map((a) => a.id), ['default', 'remove']);
        if (vector['variant'] == 'empty') {
          expect(find.byType(FlarePluginForm), findsNothing);
          final warning = view.blocks
              .whereType<FlarePluginStatusBlock>()
              .single;
          expect(find.text(warning.text), findsOneWidget);
          expect(
            find.byKey(const ValueKey('flare-account-result')),
            findsNothing,
          );
        } else {
          final form = tester.widget<FlarePluginForm>(
            find.byType(FlarePluginForm),
          );
          expect(form.embedded, isTrue);
          expect(form.inputs.map((i) => i.id), view.actions.single.form);
          final input = view.inputs.singleWhere((i) => i.id == 'kind');
          final select = tester.widget<FlareRadioGroup>(
            find.byType(FlareRadioGroup),
          );
          expect(input.defaultValue, isNull);
          expect(select.value, isEmpty);
          expect(
            select.options.map((o) => o.value),
            vector['variant'] == 'all4'
                ? ['bankCard', 'alipay', 'wechat', 'address']
                : ['alipay'],
          );
          expect(
            select.options.map((o) => o.label),
            input.choices.map((c) => c.label),
          );
          await tester.ensureVisible(
            find.byKey(const ValueKey('flare-plugin-form-submit')),
          );
          await tester.tap(
            find.byKey(const ValueKey('flare-plugin-form-submit')),
          );
          await tester.pumpAndSettle();
          expect(
            calls,
            isEmpty,
            reason: 'There is no implicit bankCard/default selection',
          );
          select.onSelect!(select.options.first.value);
          for (final id in ['accountName', 'accountNumber', 'bankName']) {
            final label = view.inputs.singleWhere((i) => i.id == id).label;
            final field = find.byWidgetPredicate(
              (widget) => widget is FlareInput && widget.semanticLabel == label,
            );
            await tester.enterText(
              find.descendant(of: field, matching: find.byType(EditableText)),
              'Example $id',
            );
          }
          await tester.ensureVisible(
            find.byKey(const ValueKey('flare-plugin-form-submit')),
          );
          await tester.tap(
            find.byKey(const ValueKey('flare-plugin-form-submit')),
          );
          await tester.pump();
          expect(calls.single.$1, 'save');
          expect(
            calls.single.$2.formValues,
            containsPair('kind', select.options.first.value),
          );
          expect(calls.single.$2.data, vector['sourceData']);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'a changed resolved type set cannot reuse a disabled saved form kind',
    (tester) async {
      final all = _cases.singleWhere(
        (c) => c['variant'] == 'all4' && c['locale'] == 'zh-CN',
      );
      final alipay = _cases.singleWhere(
        (c) => c['variant'] == 'alipay_only' && c['locale'] == 'zh-CN',
      );
      final calls = <FlarePluginPageActionPayload>[];
      await tester.pumpWidget(
        _host(_view(all), (_, payload) => calls.add(payload)),
      );
      await tester.pumpAndSettle();
      tester.widget<FlareRadioGroup>(find.byType(FlareRadioGroup)).onSelect!(
        'bankCard',
      );
      await tester.pump();
      expect(
        tester.widget<FlareRadioGroup>(find.byType(FlareRadioGroup)).value,
        'bankCard',
      );
      await tester.pumpWidget(
        _host(_view(alipay), (_, payload) => calls.add(payload)),
      );
      await tester.pumpAndSettle();
      final select = tester.widget<FlareRadioGroup>(
        find.byType(FlareRadioGroup),
      );
      expect(select.options.map((o) => o.value), ['alipay']);
      expect(select.value, isEmpty);
      expect(
        find.text('Example owner'),
        findsOneWidget,
        reason: 'Closing a type does not hide historical profiles',
      );
      expect(calls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
