import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vocabulary 2 (new blocks, inputs, formats and the upgrade notice) against
/// the shared spec/plugin-view-vectors.json sections formats2, blocks2,
/// moneyInput and upgradeNotice (the Vue, SwiftUI and Compose kits read the
/// same file), and PLUGIN_UI_VOCABULARY against spec/plugin-ui-vocabulary.json.
final Map<String, dynamic> vectors =
    jsonDecode(
          File(
            '${Directory.current.path}/../../spec/plugin-view-vectors.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;
final Map<String, dynamic> vocabularySource =
    jsonDecode(
          File(
            '${Directory.current.path}/../../spec/plugin-ui-vocabulary.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

const zh = FlareStrings();
const en = flareStringsEnglish;

List<Map<String, dynamic>> list(Object? value) => [
  for (final item in value as List) (item as Map).cast<String, dynamic>(),
];

Widget host(Widget child, {FlareStrings strings = zh}) => MaterialApp(
  home: FlareStringsScope(
    strings: strings,
    child: Scaffold(
      body: SingleChildScrollView(child: Center(child: child)),
    ),
  ),
);

FlarePluginViewModel view(List<Map<String, Object?>> blocks) =>
    FlarePluginViewModel.fromJson({
      'available': true,
      'title': 'Dashboard',
      'blocks': blocks,
    });

void main() {
  group('formats2', () {
    final formats = vectors['formats2'] as Map<String, dynamic>;
    final units = (formats['strings'] as Map).cast<String, dynamic>();
    test('the kit copy is the vectors\' units', () {
      for (final (locale, strings) in [('zh', zh), ('en', en)]) {
        final u = (units[locale] as Map).cast<String, dynamic>();
        expect(strings.pluginFormatCountUnits, u['countUnits'], reason: locale);
        expect(strings.pluginFormatSeconds, u['seconds'], reason: locale);
        expect(strings.myInviteUnitDays, u['days'], reason: locale);
        expect(strings.myInviteUnitHours, u['hours'], reason: locale);
        expect(strings.myInviteUnitMinutes, u['minutes'], reason: locale);
      }
    });
    for (final c in list(formats['cases'])) {
      test('${(c['format'] as Map)['kind']} ${c['text']}', () {
        final format = (c['format'] as Map).cast<String, Object?>();
        expect(flarePluginFormatText(c['text'] as String, format, zh), c['zh']);
        expect(flarePluginFormatText(c['text'] as String, format, en), c['en']);
      });
    }
  });

  group('blocks2', () {
    final blocks = vectors['blocks2'] as Map<String, dynamic>;
    test('steps, trends, tones and aspects', () {
      for (final c in list(blocks['steps'])) {
        expect(flarePluginStepState(c['state']).name, c['expect']);
      }
      for (final c in list(blocks['trend'])) {
        expect(flarePluginTrendDirection(c['direction']).name, c['expect']);
      }
      for (final c in list(blocks['bannerTone'])) {
        expect(flarePluginBannerTone(c['tone']).name, c['expect']);
      }
      for (final c in list(blocks['heroTone'])) {
        expect(flarePluginHeroTone(c['tone']).name, c['expect']);
      }
      for (final c in list(blocks['imageRatio'])) {
        expect(
          flarePluginImageRatio(c['aspect'] as String),
          closeTo((c['expect'] as num).toDouble(), 1e-12),
        );
      }
    });
    test('qr expiry', () {
      for (final c in list(blocks['qr'])) {
        final at = c['expiresAtMs'] as int?;
        final now = c['nowMs'] as int;
        expect(flarePluginQrExpired(at, now), c['expired']);
        expect(flarePluginQrRefreshMs(at, now), c['refreshMs']);
      }
    });
    test('donut slices', () {
      for (final c in list(blocks['donut'])) {
        final slices = flarePluginDonutSlices([
          for (final v in c['values'] as List) (v as num).toDouble(),
        ]);
        final expected = list(c['expect']);
        expect(slices.length, expected.length);
        for (var i = 0; i < slices.length; i += 1) {
          expect(slices[i].index, expected[i]['index']);
          expect(
            slices[i].start,
            closeTo((expected[i]['start'] as num).toDouble(), 1e-12),
          );
          expect(
            slices[i].sweep,
            closeTo((expected[i]['sweep'] as num).toDouble(), 1e-12),
          );
        }
      }
    });
    test('a section\'s children follow its heading', () {
      final flatten = blocks['flatten'] as Map<String, dynamic>;
      final parsed = [
        for (final b in list(flatten['blocks']))
          FlarePluginBlock.fromJson(b.cast<String, Object?>())!,
      ];
      final flat = flarePluginFlatBlocks(parsed);
      final expected = list(flatten['expect']);
      expect(flat.length, expected.length);
      for (var i = 0; i < flat.length; i += 1) {
        expect(flat[i].section, expected[i]['section']);
      }
      expect(flat[2].block, isA<FlarePluginStatsBlock>());
      expect(flat[3].block, isA<FlarePluginChartBlock>());
    });
    test('chart has points', () {
      for (final c in list(blocks['chartHasPoints'])) {
        final block =
            FlarePluginBlock.fromJson({
                  'kind': 'chart',
                  'chartKind': 'bar',
                  'series': c['series'],
                })
                as FlarePluginChartBlock;
        expect(flarePluginChartHasPoints(block.series), c['expect']);
      }
    });
    test('instants outside the Date range are left out', () {
      for (final c in list(blocks['instants'])) {
        final timeline =
            FlarePluginBlock.fromJson({
                  'kind': 'timeline',
                  'items': [
                    {'atMs': c['atMs'], 'title': 'x'},
                  ],
                })
                as FlarePluginTimelineBlock;
        expect(
          timeline.items.length,
          c['kept'] == true ? 1 : 0,
          reason: '${c['atMs']}',
        );
        final time = FlarePluginBlock.fromJson({
          'kind': 'time',
          'atMs': c['atMs'],
        });
        expect(time != null, c['kept'], reason: '${c['atMs']}');
      }
      // A timeline item without an instant is left out, not drawn in 1970.
      final missing =
          FlarePluginBlock.fromJson({
                'kind': 'timeline',
                'items': [
                  {'title': 'x'},
                ],
              })
              as FlarePluginTimelineBlock;
      expect(missing.items, isEmpty);
      // Drawing never throws, whatever the instant.
      expect(
        flarePluginDateTime(flarePluginMaxInstantMs, 0, zh).isNotEmpty,
        isTrue,
      );
    });
    test('chart domain', () {
      for (final c in list(blocks['chartDomain'])) {
        final domain = flarePluginChartDomain([
          for (final v in c['values'] as List) (v as num).toDouble(),
        ]);
        expect(
          [domain.min, domain.max],
          [(c['min'] as num).toDouble(), (c['max'] as num).toDouble()],
          reason: '${c['values']}',
        );
      }
    });
  });

  group('moneyInput', () {
    final money = vectors['moneyInput'] as Map<String, dynamic>;
    final input = FlarePluginInput.fromJson(
      (money['input'] as Map).cast<String, Object?>(),
    )!;
    test('normalize', () {
      for (final c in list(money['normalize'])) {
        expect(flarePluginMoneyAmount(c['typed'] as String), c['expect']);
      }
    });
    test('typed with the locale decimal separator', () {
      for (final c in list(money['typed'])) {
        expect(
          flarePluginMoneyTyped(c['typed'] as String, c['separator'] as String),
          c['expect'],
        );
      }
      expect(flarePluginDecimalSeparator('de', 'DE'), ',');
      expect(flarePluginDecimalSeparator('de', 'CH'), '.');
      expect(flarePluginDecimalSeparator('zh', 'CN'), '.');
      expect(flarePluginDecimalSeparator(null), '.');
    });
    test('check', () {
      for (final c in list(money['check'])) {
        final subject = c['input'] == null
            ? input
            : FlarePluginInput.fromJson(
                (c['input'] as Map).cast<String, Object?>(),
              )!;
        expect(
          flarePluginCheckInput(subject, c['draft'])?.name,
          c['expect'],
          reason: '${c['draft']}',
        );
      }
    });
    test('values', () {
      for (final c in list(money['values'])) {
        final values = flarePluginFormValues([input], {input.id: c['draft']});
        expect(values[input.id], c['expect']);
      }
    });
    test('drafts', () {
      for (final c in list(money['drafts'])) {
        expect(
          flarePluginDraftValue(
            input,
            c['value'] == null ? {} : {input.id: c['value']},
          ),
          c['expect'],
        );
      }
    });
    test('compare', () {
      for (final c in list(money['compare'])) {
        expect(
          flarePluginCompareDecimal(c['a'] as String, c['b'] as String),
          c['expect'],
        );
      }
    });
    test('image and document upload like file', () {
      for (final kind in ['file', 'image', 'document']) {
        final upload = FlarePluginInput.fromJson({
          'id': 'photo',
          'kind': kind,
          'label': 'Photo',
          'required': true,
          if (kind == 'document') 'side': 'front',
        })!;
        expect(flarePluginIsUpload(upload.kind), isTrue);
        expect(
          flarePluginCheckInput(upload, null),
          FlarePluginFormIssue.required,
        );
        expect(flarePluginCheckInput(upload, {'fileId': 'f_1'}), isNull);
        expect(
          flarePluginFormValues(
            [upload],
            {
              'photo': {'fileId': 'f_1'},
            },
          ),
          {
            'photo': {'fileId': 'f_1'},
          },
        );
      }
    });
  });

  group('upgradeNotice', () {
    test('modes', () {
      for (final c in list(vectors['upgradeNotice'])) {
        final status = c['status'] == null
            ? null
            : FlarePluginUpgradeStatus.fromJson(
                (c['status'] as Map).cast<String, Object?>(),
              );
        expect(
          flarePluginUpgradeMode(
            status,
            canUpdate: c['canUpdate'] as bool,
          ).name,
          c['expect'],
        );
      }
    });
    testWidgets('a card offers the update key only with a build', (
      tester,
    ) async {
      var updates = 0;
      final placeholder = FlarePluginViewModel.fromJson({
        'available': false,
        'unavailableReason': 'upgrade_required',
        'minBuild': 41020,
        'title': 'Task board',
      });
      expect(placeholder.minBuild, 41020);
      await tester.pumpWidget(
        host(
          FlarePluginView(
            view: placeholder,
            upgradeStatus: const FlarePluginUpgradeStatus(
              available: true,
              build: 41020,
            ),
            onUpdate: () => updates++,
          ),
        ),
      );
      await tester.tap(find.byKey(FlarePluginUpgradeNotice.actionKey));
      expect(updates, 1);
      expect(find.byKey(FlarePluginView.reasonKey), findsNothing);
      await tester.pumpWidget(
        host(
          FlarePluginView(
            view: placeholder,
            upgradeStatus: const FlarePluginUpgradeStatus(available: false),
            onUpdate: () => updates++,
          ),
        ),
      );
      expect(find.byKey(FlarePluginUpgradeNotice.actionKey), findsNothing);
      expect(find.text(zh.pluginUpgradeNotAvailable), findsOneWidget);
    });
    testWidgets('a page draws the whole notice', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FlarePluginPage(
            page: const FlarePluginPageRef(pluginId: 'p', page: 'board'),
            view: FlarePluginPageViewModel.fromJson({
              'available': false,
              'unavailableReason': 'upgrade_required',
              'title': 'Task board',
            }),
            upgradeStatus: const FlarePluginUpgradeStatus(available: true),
            onUpdate: () {},
          ),
        ),
      );
      expect(find.byKey(FlarePluginUpgradeNotice.actionKey), findsOneWidget);
      expect(find.text(zh.pluginUpgradeDescription), findsOneWidget);
    });
  });

  group('PluginView vocabulary 2 blocks', () {
    testWidgets('draws every new block', (tester) async {
      await tester.pumpWidget(
        host(
          FlarePluginView(
            view: view([
              {
                'kind': 'stats',
                'items': [
                  {
                    'label': 'Members',
                    'value': '12345',
                    'format': {'kind': 'count', 'count': 12345},
                  },
                  {
                    'label': 'Time',
                    'value': '7500000 ms',
                    'format': {'kind': 'duration', 'ms': 7500000},
                    'trend': {'text': '+3', 'direction': 'up'},
                  },
                ],
              },
              {
                'kind': 'chart',
                'chartKind': 'donut',
                'series': [
                  {
                    'points': [
                      {'label': 'A', 'value': 1, 'text': '1'},
                      {'label': 'B', 'value': 3, 'text': '3'},
                    ],
                  },
                ],
              },
              {
                'kind': 'hero',
                'value': '¥128.60',
                'amount': true,
                'tone': 'brand',
              },
              {
                'kind': 'steps',
                'items': [
                  {'label': 'Submit', 'state': 'done'},
                  {'label': 'Review', 'state': 'bogus'},
                ],
              },
              {'kind': 'banner', 'tone': 'warning', 'text': 'Verify first'},
              {
                'kind': 'timeline',
                'items': [
                  {'atMs': 1700000000000, 'title': 'Paid'},
                ],
              },
              {
                'kind': 'image',
                'asset': 'cover.png',
                'aspect': '16:9',
                'alt': 'Cover',
              },
            ]),
          ),
        ),
      );
      expect(find.text('1.2万'), findsOneWidget);
      expect(find.text('2 小时 5 分钟'), findsOneWidget);
      expect(find.text('¥128.60'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('flare-plugin-step-done')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('flare-plugin-step-pending')),
        findsOneWidget,
      );
      expect(find.text('Verify first'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text(zh.pluginViewImageUnavailable), findsOneWidget);
    });

    testWidgets('folds a section and skips unknown kinds inside it', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FlarePluginView(
            view: view([
              {
                'kind': 'section',
                'label': 'Details',
                'collapsed': true,
                'blocks': [
                  {'kind': 'text', 'text': 'Hidden', 'style': 'body'},
                  {'kind': 'sparkline', 'points': []},
                ],
              },
            ]),
          ),
        ),
      );
      expect(find.text('Hidden'), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('flare-plugin-section-toggle')),
      );
      await tester.pump();
      expect(find.text('Hidden'), findsOneWidget);
    });

    testWidgets('runs owned actions and asks for a fresh QR code', (
      tester,
    ) async {
      final actions = <String>[];
      final refreshes = <FlarePluginQrRefresh>[];
      await tester.pumpWidget(
        host(
          FlarePluginView(
            view: view([
              {
                'kind': 'hero',
                'value': '¥1',
                'amount': true,
                'tone': 'neutral',
                'actions': [
                  {'id': 'recharge', 'label': 'Recharge'},
                ],
              },
              {
                'kind': 'qr',
                'value': 'code',
                'valuePath': '/code',
                'refreshOperation': 'code.refresh',
                'expiresAtMs': 1,
              },
            ]),
            onAction: (id, _) => actions.add(id),
            onQrRefresh: refreshes.add,
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('flare-plugin-action-recharge')),
      );
      expect(actions, ['recharge']);
      await tester.tap(find.byKey(const ValueKey('flare-plugin-qr-refresh')));
      expect(refreshes.single.operation, 'code.refresh');
      expect(refreshes.single.valuePath, '/code');
    });
  });

  test(
    'PLUGIN_UI_VOCABULARY is the shared vocabulary less Flutter\'s omissions',
    () {
      final shared = (vocabularySource['vocabulary'] as Map)
          .cast<String, dynamic>();
      final omit =
          (((vocabularySource['kits'] as Map)['flutter'] as Map)['omit'] as Map)
              .cast<String, dynamic>();
      for (final set in [
        'blocks',
        'inputs',
        'formats',
        'actions',
        'native',
        'renderers',
        'kinds',
      ]) {
        final dropped = {...(omit[set] as List? ?? const [])};
        final expected = [
          for (final name in shared[set] as List)
            if (!dropped.contains(name)) name as String,
        ]..sort();
        expect(PLUGIN_UI_VOCABULARY[set], expected, reason: set);
      }
      expect(PLUGIN_UI_VOCABULARY['version'], shared['version']);
      expect(
        PLUGIN_UI_VOCABULARY['blocks'] as List,
        isNot(contains('protected-media')),
      );
    },
  );
}
