import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared typing table (`spec/typing-vectors.json`), `signal` half: the composer's edits in, the
/// reports this client owes the conversation out. The Vue, SwiftUI and Compose kits run the same file
/// through the same driver, so a rule that is right here is right there or the difference is a failure.
void main() {
  final table = jsonDecode(File('../../spec/typing-vectors.json').readAsStringSync()) as Map<String, dynamic>;
  final rules = table['rules'] as Map<String, dynamic>;
  final cases = ((table['signal'] as Map<String, dynamic>)['cases'] as List).cast<Map<String, dynamic>>();

  test('uses the table\'s constants, so the four kits cannot drift apart quietly', () {
    expect(flareTypingIdleStopMs, rules['idleStopMs']);
    expect(flareTypingRefreshMs, rules['refreshMs']);
    expect(flareTypingPeerTtlMs, rules['peerTtlMs']);
  });

  test('refreshes before the peer\'s belief expires', () {
    // The invariant the table states. Two apps shipped without it and went silent mid-sentence.
    expect(flareTypingRefreshMs, lessThan(flareTypingPeerTtlMs));
  });

  for (final vector in cases) {
    final name = vector['name'] as String;
    // Once at zero and once where a real clock is. A table whose times start at zero is comfortably inside a
    // 32-bit int; a wall clock is not, and a kit that stored "now" in one would wrap to a negative instant
    // and never stop typing — a defect no zero-based script can see. The Compose kit was written that way
    // first; this is the guard that found it.
    for (final base in const [0, 1767000000000]) {
      test('$name${base == 0 ? '' : ' (on a real clock)'}', () {
        final signal = FlareTypingSignal();
        final reports = <FlareTypingReport>[];
        for (final raw in (vector['steps'] as List).cast<Map<String, dynamic>>()) {
          final at = base + (raw['at'] as int);
          // Time first, then the step: an idle stop that fell due in between must be reported before it.
          reports.addAll(signal.tick(at));
          switch (raw['op'] as String) {
            case 'edit':
              reports.addAll(signal.edit(raw['conversationId'] as String? ?? '', raw['text'] as String? ?? '', at));
            case 'send':
              reports.addAll(signal.send(raw['conversationId'] as String? ?? '', at));
            case 'close':
              reports.addAll(signal.close(at));
          }
        }
        reports.addAll(signal.tick(base + (vector['endAt'] as int)));
        final expected = (vector['expect'] as List)
            .cast<Map<String, dynamic>>()
            .map((e) => FlareTypingReport(e['conversationId'] as String, e['typing'] as bool, base + (e['at'] as int)))
            .toList();
        expect(reports, expected, reason: name);
      });
    }
  }
}
