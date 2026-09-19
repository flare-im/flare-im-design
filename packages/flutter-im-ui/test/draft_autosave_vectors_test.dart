import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared draft table (`spec/draft-vectors.json`): the composer's edits in, the writes this client
/// owes the core out. The Vue, SwiftUI and Compose kits run the same file through the same driver.
void main() {
  final table = jsonDecode(File('../../spec/draft-vectors.json').readAsStringSync()) as Map<String, dynamic>;
  final cases = (table['cases'] as List).cast<Map<String, dynamic>>();

  test('uses the table\'s delay, so the four kits cannot drift apart quietly', () {
    expect(flareDraftSaveDelayMs, (table['rules'] as Map<String, dynamic>)['saveDelayMs']);
  });

  for (final vector in cases) {
    final name = vector['name'] as String;
    for (final base in const [0, 1767000000000]) {
      test('$name${base == 0 ? '' : ' (on a real clock)'}', () {
        final drafts = FlareDraftAutosave();
        final saves = <FlareDraftSave>[];
        for (final raw in (vector['steps'] as List).cast<Map<String, dynamic>>()) {
          final at = base + (raw['at'] as int);
          saves.addAll(drafts.tick(at));
          final cid = raw['conversationId'] as String? ?? '';
          final text = raw['text'] as String? ?? '';
          switch (raw['op'] as String) {
            case 'seed':
              drafts.seed(cid, text);
            case 'edit':
              saves.addAll(drafts.edit(cid, text, at));
            case 'send':
              saves.addAll(drafts.send(cid, at));
            case 'restore':
              saves.addAll(drafts.restore(cid, text, at));
            case 'leave':
              saves.addAll(drafts.leave(at));
          }
        }
        saves.addAll(drafts.tick(base + (vector['endAt'] as int)));
        final expected = (vector['expect'] as List)
            .cast<Map<String, dynamic>>()
            .map((e) => FlareDraftSave(e['conversationId'] as String, e['text'] as String, base + (e['at'] as int)))
            .toList();
        expect(saves, expected, reason: name);
      });
    }
  }
}
