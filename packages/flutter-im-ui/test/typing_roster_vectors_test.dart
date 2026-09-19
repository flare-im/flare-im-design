import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared typing table (`spec/typing-vectors.json`), `roster` half: facts about peers in, the people
/// typing out. The Vue, SwiftUI and Compose kits run the same file through the same driver.
void main() {
  final table = jsonDecode(File('../../spec/typing-vectors.json').readAsStringSync()) as Map<String, dynamic>;
  final roster = table['roster'] as Map<String, dynamic>;
  final selfId = roster['selfId'] as String;
  final cases = (roster['cases'] as List).cast<Map<String, dynamic>>();

  test('expires a belief on the table\'s ttl', () {
    expect(flareTypingPeerTtlMs, (table['rules'] as Map<String, dynamic>)['peerTtlMs']);
  });

  for (final vector in cases) {
    final name = vector['name'] as String;
    for (final base in const [0, 1767000000000]) {
      test('$name${base == 0 ? '' : ' (on a real clock)'}', () {
        final state = FlareTypingRoster(selfId);
        final watch = vector['watch'] as String;
        final steps = (vector['steps'] as List).cast<Map<String, dynamic>>();
        final seen = <Map<String, Object>>[];
        var last = '[]';
        final ids = {for (final s in steps) (s['conversationId'] as String? ?? '')};

        void record(int at) {
          final typers = state.typers(watch);
          final key = jsonEncode(typers);
          if (key == last) return;
          last = key;
          seen.add({'at': at - base, 'typers': typers});
        }

        String snapshot() => jsonEncode([for (final id in ids) state.typers(id)]);

        void advance(int to) {
          // Beliefs expire at their own deadline, so the record carries that instant, not the step's. The
          // bound is not decoration: this loop asks the rule when to prune next, so a rule that stops
          // making progress would spin here forever, and a harness that hangs is worse than one that fails.
          for (var guard = 0;; guard += 1) {
            expect(guard, lessThan(steps.length + 64), reason: '$name: prune made no progress');
            final next = state.nextExpiry;
            if (next == null || next > to) break;
            final before = snapshot();
            state.prune(next);
            expect(snapshot(), isNot(before), reason: '$name: prune at $next dropped nothing');
            record(next);
          }
        }

        for (final step in steps) {
          final at = base + (step['at'] as int);
          advance(at);
          switch (step['op'] as String) {
            case 'started':
              state.started(step['conversationId'] as String? ?? '', step['userId'] as String? ?? '', at);
            case 'stopped':
              state.stopped(step['conversationId'] as String? ?? '', step['userId'] as String? ?? '');
            case 'replaced':
              state.replaced(step['conversationId'] as String? ?? '', (step['userIds'] as List).cast<String>(), at);
            case 'sent':
              state.sent(step['conversationId'] as String? ?? '', step['senderId'] as String? ?? '');
          }
          record(at);
        }
        advance(base + (vector['endAt'] as int));

        final expected = (vector['expect'] as List).cast<Map<String, dynamic>>().map((e) => {
              'at': e['at'] as int,
              'typers': (e['typers'] as List).cast<String>(),
            });
        expect(jsonEncode(seen), jsonEncode(expected.toList()), reason: name);
        if (vector.containsKey('nextExpiryAtEnd')) {
          final next = state.nextExpiry;
          expect(next == null ? null : next - base, vector['nextExpiryAtEnd'], reason: '$name next expiry');
        }
      });
    }
  }
}
