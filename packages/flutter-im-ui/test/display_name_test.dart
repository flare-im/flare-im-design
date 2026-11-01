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
    expect(_rows('text').length, greaterThanOrEqualTo(30));
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
        final text = row['text'] as Map<String, dynamic>;
        expect(flareDisplayNameText(name, const FlareStrings()), text['zh-CN']);
        expect(flareDisplayNameText(name, flareStringsEnglish), text['en-US']);
        // The wire round-trips.
        expect(FlareDisplayName.fromJson(name.toJson()), name);
      });
    }
  });

  group('quoteSender', () {
    test('the shared table keeps its cases', () {
      expect(_rows('quoteSender').length, greaterThanOrEqualTo(14));
    });
    for (final row in _rows('quoteSender')) {
      test('${row['id']}', () {
        final target = FlareReplyTarget(
          senderName: row['senderName'] as String? ?? '',
          summary: '上一条消息',
          senderId: row['senderId'] as String?,
          sender: row.containsKey('sender')
              ? FlareDisplayName.fromJson(row['sender'])
              : null,
        );
        final text = row['text'] as Map<String, dynamic>;
        expect(flareQuoteSenderText(target, const FlareStrings()), text['zh-CN']);
        expect(flareQuoteSenderText(target, flareStringsEnglish), text['en-US']);
      });
    }
  });

  test('reads what is not a name it knows, never failing', () {
    const unknownUser = FlareUnnamedDisplayName(FlareDisplayNameEntity.person);
    for (final value in [
      {'kind': 'nickname', 'text': 'x'},
      {'kind': 'named'},
      <String, Object?>{},
      'named',
      null,
      [1],
    ]) {
      expect(FlareDisplayName.fromJson(value), unknownUser, reason: '$value');
    }
    expect(
      FlareDisplayName.fromJson({'kind': 'unnamed', 'entity': 'robot', 'idTail': '9876'}),
      const FlareUnnamedDisplayName(FlareDisplayNameEntity.person, idTail: '9876'),
    );
  });

  test("a host's own words win", () {
    final strings = const FlareStrings().copyWith(displayNameUser: (tail) => '访客 $tail');
    expect(
      flareDisplayNameText(const FlareUnnamedDisplayName(FlareDisplayNameEntity.person, idTail: '9876'), strings),
      '访客 9876',
    );
  });
}
