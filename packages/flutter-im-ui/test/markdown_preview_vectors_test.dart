import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared markdown table (`spec/markdown-preview-vectors.json`): what a markdown message reads as in a
/// conversation row, a reply strip or a quote. Vue is the reference implementation; this kit answers to the
/// same file.
void main() {
  final table =
      jsonDecode(
            File('../../spec/markdown-preview-vectors.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final cases = (table['cases'] as List).cast<Map<String, dynamic>>();

  const zh = FlareStrings();
  final en = zh.copyWith(
    previewImage: '[Image]',
    previewImageNamed: (label) => '[Image] $label',
  );
  final strings = {'zh-CN': zh, 'en-US': en};

  test('the table still carries its cases', () {
    expect(cases.length, greaterThanOrEqualTo(20));
  });

  for (final vector in cases) {
    final id = vector['id'] as String;
    final expected = (vector['expected'] as Map).cast<String, dynamic>();
    for (final locale in strings.keys) {
      test('$id reads the same in $locale', () {
        expect(
          flareMarkdownToPlainText(
            vector['markdown'] as String,
            strings[locale]!,
          ),
          expected[locale],
          reason: id,
        );
      });
    }
  }
}
