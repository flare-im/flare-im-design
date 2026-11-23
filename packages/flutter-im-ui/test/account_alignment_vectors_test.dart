import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'wallet_composition_test.dart' as review;

final _vectors =
    jsonDecode(
          File('../../spec/account-layout-vectors.json').readAsStringSync(),
        )
        as Map;

void main() {
  for (final viewport in (_vectors['viewports'] as List).cast<Map>()) {
    for (final vector in (_vectors['cases'] as List).cast<Map>()) {
      testWidgets('${vector['id']} actual geometry at ${viewport['width']}', (
        tester,
      ) async {
        final width = (viewport['width'] as num).toDouble();
        review.surface(tester, width, height: 2000);
        await review.fonts(tester);
        final view = FlarePluginPageViewModel.fromJson({
          ...(vector['view'] as Map).cast<String, Object?>(),
          'data': vector['sourceData'],
        });
        final ref = FlarePluginPageRef(
          pluginId: 'flare.wallet',
          page: vector['page'] as String,
        );
        final calls = <(String, FlarePluginPageActionPayload)>[];
        final capture = GlobalKey();
        await tester.pumpWidget(
          review.host(
            RepaintBoundary(
              key: capture,
              child: FlareStringsScope(
                strings: vector['locale'] == 'en-US'
                    ? flareStringsEnglish
                    : const FlareStrings(),
                child: FlarePluginPage(
                  appearance: FlarePluginPageAppearance.account,
                  page: ref,
                  view: view,
                  onBack: () {},
                  onAction: (id, payload) => calls.add((id, payload)),
                ),
              ),
            ),
            dark: width >= 880,
          ),
        );
        await tester.pumpAndSettle();
        final expected = vector['expected'] as Map;
        final header = find
            .ancestor(of: find.text(view.title), matching: find.byType(Row))
            .first;
        expect(
          tester.getSize(header).width,
          (viewport['outerWidth'] as num) - 24,
        );
        expect(tester.getCenter(header).dx, width / 2);
        expect(calls, isEmpty);
        for (final text in expected['urgentTexts'] as List)
          expect(find.text(text as String), findsOneWidget);
        final layout = vector['layout'];
        if (layout != 'flow') {
          for (final text in expected['informationTexts'] as List)
            expect(find.text(text as String), findsNothing);
        }
        final entries = flareAccountEntries(view);
        expect(entries.map((e) => e.row.key), expected['uniqueRowKeys']);
        final first = find.byKey(ValueKey('account-entry:${entries.first.id}'));
        if (layout == 'wallet') {
          final summary = find.byKey(const ValueKey('flare-account-summary'));
          final props = view.presentation!['props'] as Map;
          final pc = width >= FlareSizes.appShellCompactMinWidth;
          final title = find.descendant(
            of: summary,
            matching: find.text(props['sectionTitle'] as String),
          );
          final controls = find.descendant(
            of: summary,
            matching: find.byType(FlareIconButton),
          );
          final controlsRect = tester.getRect(controls),
              summaryRect = tester.getRect(summary);
          expect(controlsRect.right, closeTo(summaryRect.right, 0.1));
          if (pc) {
            // §12.23: a PC has no title row; the eye ends the quick-key row
            // under the cards.
            expect(title, findsNothing);
            expect(
              controlsRect.top,
              greaterThan(tester.getBottomLeft(first).dy),
            );
          } else {
            // §5.1: a phone's header is the title with the eye at its end.
            final titleRect = tester.getRect(title);
            expect(controlsRect.left, greaterThanOrEqualTo(titleRect.right));
            expect(controlsRect.center.dy, closeTo(titleRect.center.dy, 0.5));
          }
          final second = find.byKey(ValueKey('account-entry:${entries[1].id}'));
          final columns = viewport['walletColumns'] as int;
          // R1: the body gutter is 24 on PC (the 900 breakpoint), 16 on phones.
          final inner = width >= FlareSizes.appShellCompactMinWidth
              ? (viewport['outerWidth'] as num) - 48
              : viewport['innerWidth'] as num;
          expect(
            tester.getSize(first).width,
            closeTo((inner - 12 * (columns - 1)) / columns, 0.1),
          );
          if (columns == 1) {
            expect(
              tester.getTopLeft(second).dy,
              greaterThanOrEqualTo(tester.getBottomLeft(first).dy + 12),
            );
          } else {
            expect(tester.getTopLeft(first).dy, tester.getTopLeft(second).dy);
            expect(
              tester.getTopLeft(second).dx - tester.getTopRight(first).dx,
              closeTo(12, 0.1),
            );
          }
          final amount = find.descendant(
            of: first,
            matching: find.text(entries.first.amount),
          );
          // R10: the wallet card's lead amount is 32/700, tabular.
          expect(
            tester.widget<Text>(amount).style!.fontSize,
            FlareSizes.componentAmountHeroFontSize,
          );
          expect(tester.widget<Text>(amount).maxLines, isNull);
          if (pc) {
            // §12.23: a PC card draws no balance label and no plain details.
            for (final text in [
              entries.first.block.columns.first.label,
              entries.first.block.columns[2].label,
              entries.first.row.cells[2].text,
            ]) {
              expect(
                find.descendant(of: first, matching: find.text(text)),
                findsNothing,
              );
            }
          } else {
            final assetValue = find.descendant(
              of: first,
              matching: find.text(entries.first.row.cells[2].text),
            );
            expect(tester.widget<Text>(assetValue).style!.fontSize, 14);
            expect(
              tester.widget<Text>(assetValue).style!.fontWeight,
              FontWeight.w500,
            );
            final label = find.descendant(
              of: first,
              matching: find.text(entries.first.block.columns[2].label),
            );
            expect(tester.widget<Text>(label).style!.fontSize, 12);
            expect(
              tester.getTopLeft(assetValue).dy - tester.getBottomLeft(label).dy,
              closeTo(4, 0.1),
            );
          }
        } else if (layout == 'flow') {
          expect(
            tester
                .getSize(
                  find.byKey(const ValueKey('flare-plugin-inline-form-region')),
                )
                .width,
            // R2.1: the flow card's hairline border (1 each side) narrows a
            // form the 420 cap does not reach.
            (viewport['formWidth'] as num) <
                    ((_vectors['metrics'] as Map)['formMaxWidth'] as num)
                ? (viewport['formWidth'] as num) - 2
                : viewport['formWidth'],
          );
          expect(
            tester
                .widget<FlarePluginForm>(find.byType(FlarePluginForm))
                .embedded,
            isTrue,
          );
        } else {
          final props = view.presentation!['props'] as Map;
          expect(
            tester
                .getTopLeft(find.byKey(const ValueKey('flare-account-context')))
                .dy,
            lessThan(
              tester.getTopLeft(find.text(props['description'] as String)).dy,
            ),
          );
        }
        // R10: spending reads with a true minus (U+2212).
        for (final amount in (expected['exactAmounts'] as List).toSet())
          expect(
            find.text((amount as String).replaceFirst(RegExp('^-'), '\u2212')),
            findsWidgets,
          );
        if (width == 320 || width == 1360) {
          await review.capture(
            tester,
            capture,
            'alignment-${vector['id']}-${width.toInt()}',
          );
        }
        if (layout != 'flow') {
          final original = entries.first.row.actions.first;
          await tester.ensureVisible(first);
          await tester.tap(first);
          await tester.pumpAndSettle();
          expect(calls.single.$1, original.id);
          expect(calls.single.$2.row!.key, entries.first.row.key);
          expect(calls.single.$2.row!.input, original.input);
          expect(calls.single.$2.page, ref);
          expect(calls.single.$2.data, vector['sourceData']);
          final info = find.byKey(const ValueKey('flare-account-information'));
          await tester.ensureVisible(info);
          await tester.tap(info);
          await tester.pumpAndSettle();
          expect(tester.getSize(info).height, greaterThanOrEqualTo(48));
          for (final text in expected['urgentTexts'] as List)
            expect(find.text(text as String), findsOneWidget);
          for (final text in expected['informationTexts'] as List)
            expect(find.text(text as String), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
