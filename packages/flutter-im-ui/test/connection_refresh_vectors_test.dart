import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared reconnect table (`spec/reconnect-refresh-vectors.json`): connection phases in, the work the
/// transition creates out. The Vue, SwiftUI and Compose kits run the same file.
void main() {
  final table = jsonDecode(File('../../spec/reconnect-refresh-vectors.json').readAsStringSync()) as Map<String, dynamic>;
  final cases = (table['cases'] as List).cast<Map<String, dynamic>>();

  FlareConnectionPhase phaseOf(String name) =>
      FlareConnectionPhase.values.firstWhere((p) => p.name == name);

  for (final vector in cases) {
    final name = vector['name'] as String;
    test(name, () {
      final refresh = FlareConnectionRefresh();
      final seen = [
        for (final phase in (vector['phases'] as List).cast<String>()) refresh.observe(phaseOf(phase)),
      ];
      final expected = (vector['expect'] as List).cast<Map<String, dynamic>>().map((e) => FlareReconnectWork(
            dropStaleBeliefs: e['dropStaleBeliefs'] as bool,
            resubscribe: e['resubscribe'] as bool,
            reread: e['reread'] as bool,
          ));
      expect(seen, expected.toList(), reason: name);
    });
  }
}
