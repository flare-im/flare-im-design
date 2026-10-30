import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// flareMeMenuSections and flareIconNameOrFallback against
/// spec/me-menu-vectors.json (the Vue, SwiftUI and Compose kits read the same
/// file).
final Map<String, dynamic> _table =
    jsonDecode(File('../../spec/me-menu-vectors.json').readAsStringSync())
        as Map<String, dynamic>;

Map<String, String> _strings(Object? raw) =>
    raw == null ? const {} : (raw as Map).cast<String, String>();

void main() {
  group('flareMeMenuSections', () {
    final cases = (_table['cases'] as List).cast<Map<String, dynamic>>();
    test('reads every case', () => expect(cases, isNotEmpty));
    for (final v in cases) {
      test(v['id'] as String, () {
        final strings = v['locale'] == 'en'
            ? flareStringsEnglish
            : const FlareStrings();
        final sections = flareMeMenuSections(
          FlareMeMenu.fromJson((v['menu'] as Map).cast<String, Object?>()),
          labels: _strings(v['labels']),
          summaries: _strings(v['summaries']),
          strings: strings,
        );
        final expected = (v['expect'] as List).cast<Map<String, dynamic>>();
        expect(sections, hasLength(expected.length), reason: 'sections');
        for (var s = 0; s < expected.length; s += 1) {
          expect(sections[s].title, isNull);
          final items = (expected[s]['items'] as List)
              .cast<Map<String, dynamic>>();
          expect(sections[s].items, hasLength(items.length));
          for (var i = 0; i < items.length; i += 1) {
            final got = sections[s].items[i];
            final want = items[i];
            expect(got.key, want['key']);
            expect(got.label, want['label'], reason: want['key'] as String);
            expect(got.icon, want['icon'], reason: want['key'] as String);
            expect(got.detail, want['detail'], reason: want['key'] as String);
            expect(got.kind, FlareSettingKind.navigation);
          }
        }
      });
    }

    test('the kit copy is the vector copy in both languages', () {
      final copy = _table['copy'] as Map<String, dynamic>;
      for (final (lang, s) in [
        ('zh', const FlareStrings()),
        ('en', flareStringsEnglish),
      ]) {
        final c = (copy[lang] as Map).cast<String, String>();
        expect(s.meMenuMoments, c['moments']);
        expect(s.meMenuReports, c['reports']);
        expect(s.meMenuInvite, c['invite']);
        expect(s.meMenuSettings, c['settings']);
        expect(s.meMenuPluginFallback, c['pluginFallback']);
      }
    });
  });

  group('flareIconNameOrFallback', () {
    final fallback = _table['iconFallback'] as Map<String, dynamic>;
    final cases = (fallback['cases'] as List).cast<Map<String, dynamic>>();
    test('reads every case', () => expect(cases, isNotEmpty));
    for (final v in cases) {
      test('"${v['name']}"', () {
        expect(flareIconNameOrFallback(v['name'] as String), v['expect']);
      });
    }

    testWidgets('FlareIcon draws the plugin glyph for an unknown name, '
        'nothing for an empty one', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(children: [FlareIcon('coins-stack'), FlareIcon('')]),
          ),
        ),
      );
      expect(find.byIcon(flareIconMap['plugin']!), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsNothing);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('a settings row with an unknown icon draws the plugin glyph', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlareSettingsList(
              sections: [
                FlareSettingsSection(
                  items: [
                    FlareSettingsItem(key: 'a', label: '积分', icon: 'coins'),
                    FlareSettingsItem(key: 'b', label: '钱包', icon: 'wallet'),
                    FlareSettingsItem(key: 'c', label: '空', icon: ' '),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byIcon(flareIconMap['plugin']!), findsOneWidget);
      expect(
        find.byIcon(Icons.account_balance_wallet_outlined),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.help_outline), findsNothing);
    });

    testWidgets('the 我 page renders the sections the kit computed', (
      tester,
    ) async {
      final menu = FlareMeMenu.fromJson(
        ((_table['cases'] as List).first as Map)['menu']
            as Map<String, Object?>,
      );
      final picked = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlareSettingsList(
              sections: flareMeMenuSections(
                menu,
                summaries: const {
                  'plugin:flare.redpacket.wallet-entry': '¥12.00',
                },
              ),
              onSelect: (item) => picked.add(item.key),
            ),
          ),
        ),
      );
      expect(find.text('钱包'), findsOneWidget);
      expect(find.text('¥12.00'), findsOneWidget);
      await tester.tap(find.text('设置'));
      expect(picked, ['settings']);
    });
  });
}
