import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// These are real Rust declaration resolutions over explicitly synthetic inputs.
// The UI renders them without querying a database or deriving financial totals.
void main() {
  final vectors =
      jsonDecode(
            File('../../spec/wallet-record-vectors.json').readAsStringSync(),
          )
          as Map;
  final cases = (vectors['cases'] as List).cast<Map>();
  var loadedFonts = false;
  for (final item in cases) {
    for (final width in [320.0, 1440.0]) {
      testWidgets(
        'resolved record ${item['id']}/${item['variant']}/${item['locale']} fits $width',
        (tester) async {
          tester.view.physicalSize = Size(width, 1600);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          if (!loadedFonts) {
            await tester.runAsync(() async {
              for (final (variable, family) in [
                ('FLARE_WALLET_TEST_FONT', 'WalletReview'),
                ('FLARE_WALLET_ICON_FONT', 'MaterialIcons'),
              ]) {
                if (Platform.environment[variable] case final path?) {
                  await (FontLoader(family)..addFont(
                        File(path).readAsBytes().then(ByteData.sublistView),
                      ))
                      .load();
                }
              }
            });
            loadedFonts = true;
          }
          final view = FlarePluginPageViewModel.fromJson(
            (item['view'] as Map).cast<String, Object?>(),
          );
          final filters = (item['filters'] as Map).cast<String, Object?>();
          final strings = item['locale'] == 'en-US'
              ? flareStringsEnglish
              : const FlareStrings();
          final key = GlobalKey();
          final actions = <(String, FlarePluginPageActionPayload)>[];
          await tester.pumpWidget(
            RepaintBoundary(
              key: key,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  brightness: width == 1440
                      ? Brightness.dark
                      : Brightness.light,
                  fontFamily:
                      Platform.environment.containsKey('FLARE_WALLET_TEST_FONT')
                      ? 'WalletReview'
                      : null,
                ),
                home: FlareStringsScope(
                  strings: strings,
                  child: Scaffold(
                    body: FlarePluginPage(
                      page: FlarePluginPageRef(
                        pluginId: 'fixture',
                        page: item['page'] as String? ?? item['id'] as String,
                      ),
                      view: view,
                      filters: filters,
                      onBack: () {},
                      onAction: (id, payload) => actions.add((id, payload)),
                      onFilter: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final bounds = tester.getRect(find.byType(FlareAccountView));
          expect(
            bounds.width,
            lessThanOrEqualTo(FlareSizes.directoryContentMaxWidth),
          );
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(width));
          final props = view.presentation!['props'] as Map;
          final entries = flareAccountEntries(view);
          if (props['layout'] == 'ledger') {
            expect(entries, isNotEmpty);
            for (final entry in entries) {
              final row = find.byKey(ValueKey('account-entry:${entry.id}'));
              expect(entry.title, entry.row.cells[1].text);
              expect(
                find.descendant(
                  of: row,
                  matching: find.text(entry.row.cells[0].text),
                ),
                findsOneWidget,
              );
              expect(
                find.descendant(
                  of: row,
                  matching: find.text(entry.row.cells[1].text),
                ),
                findsOneWidget,
              );
              final badge = find.descendant(
                of: row,
                matching: find.byType(FlareTag),
              );
              expect(
                tester.widget<FlareTag>(badge).label,
                entry.row.badge!.text,
              );
              expect(
                tester.widget<FlareTag>(badge).tone.name,
                entry.row.badge!.tone.name,
              );
            }
            for (final filter in flarePluginPageFilters(
              view,
              filters,
              strings.pluginViewAll,
            )) {
              expect(find.text(filter.input.label), findsOneWidget);
            }
          } else {
            for (final field in view.fields) {
              expect(find.text(field.label), findsWidgets);
              expect(find.text(field.value), findsWidgets);
            }
            for (final block in view.blocks.whereType<FlarePluginRowsBlock>()) {
              for (final row in flarePluginRowsOnce(block.rows)) {
                final caption = find.byKey(
                  ValueKey('flare-plugin-row-caption:${row.key}'),
                );
                expect(
                  tester.widget<Text>(caption).data,
                  block.columns.first.label,
                );
                expect(
                  find.descendant(
                    of: find.byKey(FlarePluginView.rowKey(row.key)),
                    matching: find.text(row.cells.first.text),
                  ),
                  findsOneWidget,
                );
              }
            }
          }
          final screenshot = Platform.environment['FLARE_WALLET_SCREENSHOTS'];
          if (screenshot != null &&
              item['locale'] == 'zh-CN' &&
              (item['variant'] != 'income' &&
                      item['variant'] != 'expense' &&
                      item['variant'] != 'internal' ||
                  item['id'] == 'history_detail')) {
            await tester.runAsync(() async {
              final image =
                  await (key.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                '$screenshot/flutter-record-${item['id']}-${item['variant']}-${width.toInt()}.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          if (props['layout'] == 'ledger') {
            final entry = entries.first;
            final binding = entry.row.actions
                .where((a) => a.id == props['rowEntryAction'])
                .single;
            await tester.ensureVisible(
              find.byKey(ValueKey('account-entry:${entry.id}')),
            );
            await tester.tap(find.byKey(ValueKey('account-entry:${entry.id}')));
            await tester.pumpAndSettle();
            expect(actions.single.$1, binding.id);
            expect(actions.single.$2.row!.key, entry.row.key);
            expect(actions.single.$2.row!.input, binding.input);
            expect(actions.single.$2.data, view.data);
          }
        },
      );
    }
  }
}
