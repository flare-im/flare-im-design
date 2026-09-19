import 'package:flare_im_ui/src/components/qr/flare_qr_encoder.dart';
import 'package:flutter_test/flutter_test.dart';

import 'qr_oracle_data.dart';

List<String> _rows(QrSymbol symbol) => [
  for (var y = 0; y < symbol.size; y++)
    String.fromCharCodes([
      for (var x = 0; x < symbol.size; x++) symbol.isDark(x, y) ? 0x31 : 0x30,
    ]),
];

/// FNV-1a 32 over the concatenated row strings (same as the oracle dump).
String _fnv1a32(List<String> rows) {
  var hash = 0x811c9dc5;
  for (final row in rows) {
    for (final unit in row.codeUnits) {
      hash = (hash ^ unit) & 0xFFFFFFFF;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

int _darkCount(List<String> rows) =>
    rows.fold(0, (sum, row) => sum + '1'.allMatches(row).length);

void main() {
  group('QrEncoder matches the qrcodegen reference bit for bit', () {
    for (final c in qrOracleCases) {
      test(c.id, () {
        final symbol = QrEncoder.encodeText(
          c.payload,
          mask: c.forcedMask < 0 ? null : c.forcedMask,
        );
        expect(symbol, isNotNull);
        expect(symbol!.version, c.version, reason: 'smallest version');
        expect(symbol.size, 4 * c.version + 17);
        expect(
          symbol.mask,
          c.mask,
          reason: c.forcedMask < 0 ? 'automatic mask choice' : 'forced mask',
        );
        final rows = _rows(symbol);
        for (var y = 0; y < rows.length; y++) {
          expect(rows[y], c.rows[y], reason: 'row $y');
        }
      });
    }

    test('forced cases cover all eight mask patterns', () {
      expect(
        {
          for (final c in qrOracleCases)
            if (c.forcedMask >= 0) c.forcedMask,
        },
        {0, 1, 2, 3, 4, 5, 6, 7},
      );
    });
  });

  group('version sweep at byte capacity (versions 1…40)', () {
    test('covers every version', () {
      expect(
        [for (final s in qrOracleSweep) s.version],
        [for (var v = 1; v <= 40; v++) v],
      );
    });

    for (final s in qrOracleSweep) {
      test('version ${s.version}', () {
        final payload = String.fromCharCodes([
          for (var i = 0; i < s.length; i++) 33 + (i * 7 + s.version * 13) % 94,
        ]);
        final auto = QrEncoder.encodeText(payload)!;
        expect(auto.version, s.version);
        expect(auto.mask, s.autoMask);
        final autoRows = _rows(auto);
        expect(_darkCount(autoRows), s.autoDark);
        expect(_fnv1a32(autoRows), s.autoHash);

        final forced = QrEncoder.encodeText(payload, mask: s.forcedMask)!;
        expect(forced.mask, s.forcedMask);
        final forcedRows = _rows(forced);
        expect(_darkCount(forcedRows), s.forcedDark);
        expect(_fnv1a32(forcedRows), s.forcedHash);
      });
    }
  });

  test('picks the smallest version at every capacity boundary', () {
    for (var version = 1; version < 40; version++) {
      final fits = List.filled(qrOracleCapacity[version], 0x61);
      expect(QrEncoder.encodeBytes(fits)!.version, version);
      expect(QrEncoder.encodeBytes([...fits, 0x61])!.version, version + 1);
    }
  });

  test('rejects payloads longer than version 40 holds', () {
    expect(
      QrEncoder.encodeBytes(List.filled(qrOracleCapacity[40], 0x61)),
      isNotNull,
    );
    expect(
      QrEncoder.encodeBytes(List.filled(qrOracleCapacity[40] + 1, 0x61)),
      isNull,
    );
  });
}
