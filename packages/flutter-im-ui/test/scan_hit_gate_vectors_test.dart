import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';
void main() {
  final table = jsonDecode(File('../../spec/scan-gate-vectors.json').readAsStringSync()) as Map<String, dynamic>;
  for (final vector in table['cases'] as List) {
    test(vector['name'] as String, () {
      final gate = FlareScanHitGate();
      for (final step in vector['steps'] as List) {
        if (step['dismiss'] == true) { gate.dismiss(); continue; }
        final result = step['select'] != null ? gate.select(step['select'] as String) : gate.observe(codes: (step['codes'] as List).map((raw) => FlareScanCode(raw as String)).toList(), tsMs: (step['tsMs'] as num).toInt());
        final compact = result.kind == 'lock' ? {'kind': 'lock', 'raw': result.code!.raw, 'ready': result.ready} : result.kind == 'choose' ? {'kind': 'choose', 'raws': result.codes.map((code) => code.raw).toList()} : {'kind': 'ignore'};
        expect(compact, step['expect'], reason: vector['name'] as String);
      }
    });
  }
}
