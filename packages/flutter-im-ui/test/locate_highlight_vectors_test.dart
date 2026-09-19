import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/src/models/locate_highlight.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared locate-mark table (`spec/locate-highlight-vectors.json`) is the one rule
/// four kits follow: how long the mark lasts, how it fades, and what a reader who
/// asked for less motion gets instead. Vue's stylesheet holds the same numbers and
/// its own test checks them; the SwiftUI and Compose tests read this same file.
void main() {
  final table =
      jsonDecode(
            File('../../spec/locate-highlight-vectors.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final cases = (table['cases'] as List).cast<Map<String, dynamic>>();

  test('the table is the window this kit was built with', () {
    expect(table['durationMs'], flareLocateHighlightDurationMs);
    expect(cases, isNotEmpty);
  });

  for (final vector in cases) {
    final id = vector['id'] as String;
    final expected = vector['expected'] as Map<String, dynamic>;
    test('locate mark: $id', () {
      final mark = flareLocateHighlight(
        (vector['elapsedMs'] as num).toDouble(),
        reduceMotion: vector['reducedMotion'] as bool,
      );
      expect(mark.marked, expected['marked'], reason: '$id marked');
      expect(
        mark.alpha,
        closeTo((expected['alpha'] as num).toDouble(), 0.001),
        reason: '$id alpha',
      );
      expect(
        mark.spread,
        closeTo((expected['spread'] as num).toDouble(), 0.001),
        reason: '$id spread',
      );
    });
  }
}
