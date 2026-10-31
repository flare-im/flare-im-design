import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// spec/display-name-vectors.json, the table the four kits run: the id tail
/// ([flareIdTail], which the plugin view's unresolved user name reads too) and
/// the text of every projected name in Chinese (the defaults) and English
/// ([flareStringsEnglish]).
final Map<String, dynamic> _vectors =
    jsonDecode(File('../../spec/display-name-vectors.json').readAsStringSync())
        as Map<String, dynamic>;

List<Map<String, dynamic>> _rows(String key) =>
    (_vectors[key] as List).cast<Map<String, dynamic>>();

void main() {
  test('the shared table keeps its cases', () {
    expect(_rows('idTail').length, greaterThanOrEqualTo(12));
    expect(_rows('text').length, greaterThanOrEqualTo(24));
  });

  group('idTail', () {
    for (final row in _rows('idTail')) {
      test('${row['id']}', () {
        expect(flareIdTail(row['input'] as String), row['output']);
        expect(flarePluginFallbackName(row['input'] as String), row['output']);
      });
    }
  });

  group('text', () {
    for (final row in _rows('text')) {
      test('${row['id']}', () {
        final name = FlareDisplayName.fromJson(row['name']);
        expect(name, isNotNull);
        final text = row['text'] as Map<String, dynamic>;
        expect(flareDisplayNameText(name!, const FlareStrings()), text['zh-CN']);
        expect(flareDisplayNameText(name, flareStringsEnglish), text['en-US']);
        // The wire round-trips.
        expect(FlareDisplayName.fromJson(name.toJson()), name);
      });
    }
  });

  test('refuses what is not a name', () {
    expect(FlareDisplayName.fromJson({'kind': 'nickname', 'text': 'x'}), isNull);
    expect(FlareDisplayName.fromJson({'kind': 'unnamed', 'entity': 'robot'}), isNull);
    expect(FlareDisplayName.fromJson('named'), isNull);
  });

  test("a host's own words win", () {
    final strings = const FlareStrings().copyWith(displayNameUser: (tail) => '访客 $tail');
    expect(
      flareDisplayNameText(const FlareUnnamedDisplayName(FlareDisplayNameEntity.person, idTail: '9876'), strings),
      '访客 9876',
    );
  });
}
