import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/src/models/swipe_reply.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared swipe-to-reply table (`spec/swipe-reply-vectors.json`) is the one
/// rule three kits follow: which direction counts, when the list's own
/// scrolling wins instead, how far the row follows the finger, and where the
/// gesture arms. The same file is read by the SwiftUI and Compose tests, so a
/// number that drifts on one platform fails on that platform alone.
void main() {
  final table =
      jsonDecode(File('../../spec/swipe-reply-vectors.json').readAsStringSync())
          as Map<String, dynamic>;
  final cases = (table['cases'] as List).cast<Map<String, dynamic>>();

  test('the table is the geometry this kit was built with', () {
    expect(table['armDistance'], flareSwipeReplyArmDistance);
    expect(table['maxTravel'], flareSwipeReplyMaxTravel);
    expect(cases, isNotEmpty);
  });

  for (final vector in cases) {
    final id = vector['id'] as String;
    final expected = vector['expected'] as Map<String, dynamic>;
    test('swipe vector: $id', () {
      final gesture = flareSwipeReplyGesture(
        (vector['dx'] as num).toDouble(),
        (vector['dy'] as num).toDouble(),
        rtl: vector['rtl'] as bool,
      );
      expect(
        gesture.travel,
        closeTo((expected['travel'] as num).toDouble(), 0.001),
        reason: '$id travel',
      );
      expect(gesture.armed, expected['armed'], reason: '$id armed');
    });
  }
}
