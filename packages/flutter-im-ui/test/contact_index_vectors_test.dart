import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// FR-044: one index letter per character, on all four kits. Vue and SwiftUI read the
// platform's pinyin collation; Flutter and Compose read the table generated from it.
// A kit that disagrees here has a defect, not a dialect — 曾 was Z here and C
// everywhere else for three rounds because nothing compared them.

void main() {
  final file = File('${Directory.current.path}/../../spec/contact-index-vectors.json');
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final letters = (data['letters'] as Map<String, dynamic>).cast<String, String>();
  final groups = (data['groups'] as Map<String, dynamic>).cast<String, String>();

  String letterOf(String character) =>
      flareContactLetter(FlareContact(id: character, name: character));

  test('reads every character the way the shared table says', () {
    final wrong = <String>[];
    letters.forEach((character, letter) {
      final actual = letterOf(character);
      if (actual != letter) wrong.add('$character: $actual (table says $letter)');
    });
    expect(wrong, isEmpty);
  });

  test('still reads the characters the GB2312 table missed', () {
    for (final character in groups['formerlyMissing']!.split('')) {
      expect(letterOf(character), isNot('#'), reason: character);
    }
  });
}
