import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// The plural rule table against spec/plural-vectors.json (the Vue, SwiftUI
/// and Compose kits read the same file).
final Map<String, dynamic> _table =
    jsonDecode(File('../../spec/plural-vectors.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final cases = (_table['cases'] as List).cast<Map<String, dynamic>>();

  test('every (locale, count) case', () {
    expect(cases, hasLength(greaterThanOrEqualTo(96)));
    for (final v in cases) {
      final locale = v['locale'] as String;
      final count = v['count'] as int;
      expect(
        flarePluralIsOne(count, locale),
        v['one'],
        reason: '$locale $count',
      );
      // Underscore tags (Locale.toString) read the same.
      expect(
        flarePluralIsOne(count, locale.replaceAll('-', '_')),
        v['one'],
        reason: '${locale.replaceAll('-', '_')} $count',
      );
    }
  });

  test('every language of the rule table follows its family', () {
    final rules = _table['rules'] as Map<String, dynamic>;
    final languages = (rules['languages'] as Map).cast<String, List>();
    bool family(String name, int n) => switch (name) {
      'none' => false,
      'is1' => n == 1,
      'is0or1' => n == 0 || n == 1,
      'mod10is1' => n % 10 == 1 && n % 100 != 11,
      _ => throw StateError('unknown family $name'),
    };
    for (final entry in languages.entries) {
      for (final language in entry.value.cast<String>()) {
        for (final n in [0, 1, 2, 5, 11, 21, 101, 111]) {
          expect(
            flarePluralIsOne(n, language),
            family(entry.key, n),
            reason: '$language $n',
          );
        }
      }
    }
    expect(rules['default'], 'is1');
    expect(flarePluralIsOne(1, 'xx'), isTrue);
    expect(flarePluralIsOne(1, null), isTrue);
    expect(flarePluralIsOne(0, 'pt-PT'), isFalse);
    expect(flarePluralIsOne(0, 'pt'), isTrue);
  });

  test('the count copy takes its form', () {
    final forms = (_table['forms'] as List).cast<Map<String, dynamic>>();
    var checked = 0;
    for (final v in forms) {
      final strings = (v['locale'] as String).startsWith('zh')
          ? const FlareStrings()
          : flareStringsEnglish;
      final count = v['count'] as int;
      final locale = v['locale'] as String;
      final text = switch (v['native'] as String) {
        'pluginViewVotes' => strings.pluginViewVotesCount(count, locale),
        'forwardRecordTotal' => strings.forwardRecordTotalCount(count, locale),
        'forwardRecordMore' => strings.forwardRecordMoreCount(count, locale),
        'myInviteCountOnly' => strings.myInviteCountOnlyCount(count, locale),
        // Flutter's storage count is a function of the count, not a pair of
        // template forms.
        'storageUsageFileCount' => null,
        final other => throw StateError('unknown field $other'),
      };
      if (text == null) continue;
      expect(text, v['text'], reason: '${v['native']} $locale $count');
      checked += 1;
    }
    expect(checked, greaterThan(0));
  });

  test('flarePlural fills {count} and {n} in the chosen form', () {
    expect(flarePlural(1, '{count} item', '{count} items', 'en'), '1 item');
    expect(flarePlural(3, '{n} item', '{n} items', 'en'), '3 items');
    expect(flarePlural(1, '{count} 条', '{count} 条', 'zh'), '1 条');
  });
}
