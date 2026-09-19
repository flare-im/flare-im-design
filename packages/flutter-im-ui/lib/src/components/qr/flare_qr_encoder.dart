import 'dart:convert' show utf8;
import 'dart:typed_data';

/// One encoded QR Code symbol (ISO/IEC 18004): [size] × [size] modules without
/// the quiet zone.
///
/// Internal to the kit: `FlareQRCard` renders it; `flare_im_ui.dart` does not
/// export this file.
final class QrSymbol {
  QrSymbol._(this.version, this.mask, this.size, this._modules);

  /// Symbol version, 1…40.
  final int version;

  /// Data mask pattern reference, 0…7.
  final int mask;

  /// Modules per side: `4 * version + 17`.
  final int size;

  /// Row-major module colors, 1 = dark.
  final Uint8List _modules;

  /// Whether the module in column [x] and row [y] is dark.
  bool isDark(int x, int y) => _modules[y * size + x] == 1;
}

/// Byte-mode QR Code encoder at error correction level M.
///
/// Data encoding, Reed–Solomon error correction with block interleaving,
/// function patterns (finders, separators, timing, alignment, format and
/// version information) and mask selection by the four penalty rules follow
/// ISO/IEC 18004. The kit only needs level M, so the level tables are M only.
abstract final class QrEncoder {
  /// Light modules required around the symbol on every side.
  static const int quietZone = 4;

  /// Encodes [text] as UTF-8 bytes in the smallest version that holds it.
  ///
  /// Returns null when the payload does not fit version 40. [mask] forces a
  /// mask pattern (0…7); by default the lowest-penalty pattern is used.
  static QrSymbol? encodeText(String text, {int? mask}) =>
      encodeBytes(utf8.encode(text), mask: mask);

  /// Encodes raw [bytes]; see [encodeText].
  static QrSymbol? encodeBytes(List<int> bytes, {int? mask}) {
    assert(mask == null || (mask >= 0 && mask <= 7), 'mask must be 0…7');
    var version = 0;
    for (var v = _minVersion; v <= _maxVersion; v++) {
      final needed = 4 + _countBits(v) + bytes.length * 8;
      if (needed <= _dataCodewords(v) * 8) {
        version = v;
        break;
      }
    }
    if (version == 0) return null;
    final codewords = _addErrorCorrection(version, _dataBytes(version, bytes));
    return _Builder(version).build(codewords, mask);
  }

  static const int _minVersion = 1;
  static const int _maxVersion = 40;

  // Level M, indexed by version - 1 (ISO/IEC 18004 Table 9).
  // dart format off
  static const List<int> _eccCodewordsPerBlock = [
    10, 16, 26, 18, 24, 16, 18, 22, 22, 26, 30, 22, 22, 24, 24, 28, 28, 26, 26, 26,
    26, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28,
  ];
  static const List<int> _eccBlockCount = [
    1, 1, 1, 2, 2, 4, 4, 4, 5, 5, 5, 8, 9, 9, 10, 10, 11, 13, 14, 16,
    17, 17, 18, 20, 21, 23, 25, 26, 28, 29, 31, 33, 35, 37, 38, 40, 43, 45, 47, 49,
  ];
  // dart format on

  /// Byte-mode character count indicator width.
  static int _countBits(int version) => version < 10 ? 8 : 16;

  /// Modules left for codewords once every function pattern is placed.
  static int _rawDataModules(int version) {
    final size = 4 * version + 17;
    // Three finders with separators (8 × 8 each), 31 format modules including
    // the dark module, and the two timing lines between the finders.
    var modules = size * size - 3 * 64 - 31 - 2 * (size - 16);
    if (version >= 2) {
      final perAxis = version ~/ 7 + 2;
      // n² - 3 alignment patterns of 25 modules; the ones centred on row or
      // column 6 share five modules with a timing line.
      modules -= 25 * (perAxis * perAxis - 3) - 10 * (perAxis - 2);
    }
    if (version >= 7) modules -= 36;
    return modules;
  }

  static int _totalCodewords(int version) => _rawDataModules(version) ~/ 8;

  static int _dataCodewords(int version) =>
      _totalCodewords(version) -
      _eccCodewordsPerBlock[version - 1] * _eccBlockCount[version - 1];

  /// Mode indicator, count, payload, terminator, bit padding and pad codewords.
  static Uint8List _dataBytes(int version, List<int> bytes) {
    final capacity = _dataCodewords(version);
    final out = Uint8List(capacity);
    var bit = 0;
    void write(int value, int width) {
      for (var i = width - 1; i >= 0; i--) {
        if ((value >> i) & 1 == 1) out[bit >> 3] |= 0x80 >> (bit & 7);
        bit++;
      }
    }

    write(0x4, 4);
    write(bytes.length, _countBits(version));
    for (final byte in bytes) {
      write(byte & 0xFF, 8);
    }
    final free = capacity * 8 - bit;
    bit += free < 4 ? free : 4; // terminator (zero bits)
    var index = (bit + 7) >> 3; // remaining bits of the byte stay zero
    for (var pad = 0xEC; index < capacity; index++, pad ^= 0xEC ^ 0x11) {
      out[index] = pad;
    }
    return out;
  }

  /// Splits [data] into blocks, appends each block's Reed–Solomon codewords
  /// and interleaves the result.
  static Uint8List _addErrorCorrection(int version, Uint8List data) {
    final blocks = _eccBlockCount[version - 1];
    final eccLength = _eccCodewordsPerBlock[version - 1];
    final shortLength = data.length ~/ blocks;
    final shortBlocks = blocks - data.length % blocks;
    final divisor = _Gf256.generator(eccLength);

    final starts = List<int>.filled(blocks, 0);
    final lengths = List<int>.filled(blocks, 0);
    final ecc = <Uint8List>[];
    var offset = 0;
    for (var b = 0; b < blocks; b++) {
      final length = b < shortBlocks ? shortLength : shortLength + 1;
      starts[b] = offset;
      lengths[b] = length;
      ecc.add(_Gf256.remainder(data, offset, length, divisor));
      offset += length;
    }

    final out = Uint8List(_totalCodewords(version));
    var k = 0;
    for (var i = 0; i <= shortLength; i++) {
      for (var b = 0; b < blocks; b++) {
        if (i < lengths[b]) out[k++] = data[starts[b] + i];
      }
    }
    for (var i = 0; i < eccLength; i++) {
      for (var b = 0; b < blocks; b++) {
        out[k++] = ecc[b][i];
      }
    }
    assert(k == out.length);
    return out;
  }
}

/// GF(2⁸) arithmetic over the QR Code field polynomial x⁸ + x⁴ + x³ + x² + 1.
abstract final class _Gf256 {
  /// αⁱ for i in 0…509 (the period is written twice to avoid a modulo).
  static final Uint8List _exp = _powers();

  /// Discrete logarithm base α of every non-zero element.
  static final Uint8List _log = _logarithms(_exp);

  static Uint8List _powers() {
    final exp = Uint8List(510);
    var value = 1;
    for (var power = 0; power < 255; power++) {
      exp[power] = value;
      exp[power + 255] = value;
      value <<= 1;
      if (value & 0x100 != 0) value ^= 0x11D;
    }
    return exp;
  }

  static Uint8List _logarithms(Uint8List exp) {
    final log = Uint8List(256);
    for (var power = 0; power < 255; power++) {
      log[exp[power]] = power;
    }
    return log;
  }

  static int multiply(int a, int b) =>
      a == 0 || b == 0 ? 0 : _exp[_log[a] + _log[b]];

  /// Monic generator polynomial ∏(x − αⁱ), i < [degree], highest power first.
  static Uint8List generator(int degree) {
    var poly = Uint8List(1)..[0] = 1;
    for (var i = 0; i < degree; i++) {
      final next = Uint8List(poly.length + 1);
      for (var j = 0; j < poly.length; j++) {
        next[j] ^= poly[j];
        next[j + 1] ^= multiply(poly[j], _exp[i]);
      }
      poly = next;
    }
    return poly;
  }

  /// Remainder of message(x) · x^degree divided by [divisor].
  static Uint8List remainder(
    Uint8List message,
    int start,
    int length,
    Uint8List divisor,
  ) {
    final degree = divisor.length - 1;
    final register = Uint8List(degree);
    for (var i = start; i < start + length; i++) {
      final factor = message[i] ^ register[0];
      register.setRange(0, degree - 1, register, 1);
      register[degree - 1] = 0;
      if (factor == 0) continue;
      for (var j = 0; j < degree; j++) {
        register[j] ^= multiply(divisor[j + 1], factor);
      }
    }
    return register;
  }
}

/// Places function patterns and codewords for one version, then masks.
class _Builder {
  _Builder(this.version)
    : size = 4 * version + 17,
      modules = Uint8List((4 * version + 17) * (4 * version + 17)),
      function = Uint8List((4 * version + 17) * (4 * version + 17));

  final int version;
  final int size;

  /// 1 = dark.
  final Uint8List modules;

  /// 1 = function module (never masked, never holds data).
  final Uint8List function;

  QrSymbol build(Uint8List codewords, int? forcedMask) {
    _placeFunctionPatterns();
    _placeCodewords(codewords);
    var mask = forcedMask ?? -1;
    if (mask < 0) {
      var lowest = -1;
      for (var candidate = 0; candidate < 8; candidate++) {
        _toggleMask(candidate);
        _placeFormat(candidate);
        final score = _penalty();
        if (lowest < 0 || score < lowest) {
          lowest = score;
          mask = candidate;
        }
        _toggleMask(candidate);
      }
    }
    _toggleMask(mask);
    _placeFormat(mask);
    return QrSymbol._(version, mask, size, modules);
  }

  void _set(int x, int y, bool dark) {
    final index = y * size + x;
    modules[index] = dark ? 1 : 0;
    function[index] = 1;
  }

  void _placeFunctionPatterns() {
    for (var i = 0; i < size; i++) {
      _set(6, i, i.isEven);
      _set(i, 6, i.isEven);
    }
    _finder(3, 3);
    _finder(size - 4, 3);
    _finder(3, size - 4);

    final centres = _alignmentCentres();
    final last = centres.length - 1;
    for (var i = 0; i <= last; i++) {
      for (var j = 0; j <= last; j++) {
        final onFinder =
            (i == 0 && j == 0) ||
            (i == 0 && j == last) ||
            (i == last && j == 0);
        if (!onFinder) _alignment(centres[i], centres[j]);
      }
    }

    _placeFormat(0); // reserves the format areas; rewritten after masking
    if (version >= 7) _placeVersion();
  }

  /// 7 × 7 finder pattern plus its one-module light separator.
  void _finder(int cx, int cy) {
    for (var dy = -4; dy <= 4; dy++) {
      for (var dx = -4; dx <= 4; dx++) {
        final x = cx + dx, y = cy + dy;
        if (x < 0 || y < 0 || x >= size || y >= size) continue;
        final ring = _chebyshev(dx, dy);
        _set(x, y, ring != 2 && ring != 4);
      }
    }
  }

  void _alignment(int cx, int cy) {
    for (var dy = -2; dy <= 2; dy++) {
      for (var dx = -2; dx <= 2; dx++) {
        _set(cx + dx, cy + dy, _chebyshev(dx, dy) != 1);
      }
    }
  }

  static int _chebyshev(int dx, int dy) {
    final ax = dx.abs(), ay = dy.abs();
    return ax > ay ? ax : ay;
  }

  /// Row/column centres of the alignment patterns (ISO/IEC 18004 Annex E):
  /// 6, then evenly spaced back from `size - 7` by an even step.
  List<int> _alignmentCentres() {
    if (version == 1) return const [];
    final count = version ~/ 7 + 2;
    final last = size - 7;
    final step = version == 32
        ? 26
        : ((last - 6) + 2 * (count - 1) - 1) ~/ (2 * (count - 1)) * 2;
    return [6, for (var i = count - 2; i >= 0; i--) last - i * step];
  }

  void _placeFormat(int mask) {
    final bits = _formatBits(mask);
    bool bit(int i) => (bits >> i) & 1 == 1;
    // Copy next to the top-left finder.
    for (var i = 0; i <= 5; i++) {
      _set(8, i, bit(i));
    }
    _set(8, 7, bit(6));
    _set(8, 8, bit(7));
    _set(7, 8, bit(8));
    for (var i = 9; i < 15; i++) {
      _set(14 - i, 8, bit(i));
    }
    // Copy split between the top-right and bottom-left finders.
    for (var i = 0; i < 8; i++) {
      _set(size - 1 - i, 8, bit(i));
    }
    for (var i = 8; i < 15; i++) {
      _set(8, size - 15 + i, bit(i));
    }
    _set(8, size - 8, true); // dark module
  }

  /// Level M (indicator 00) + mask, BCH(15, 5) protected, XOR 101010000010010.
  static int _formatBits(int mask) {
    final data = mask; // (0b00 << 3) | mask
    var value = data << 10;
    for (var i = 14; i >= 10; i--) {
      if ((value >> i) & 1 == 1) value ^= 0x537 << (i - 10);
    }
    return ((data << 10) | value) ^ 0x5412;
  }

  void _placeVersion() {
    var value = version << 12;
    for (var i = 17; i >= 12; i--) {
      if ((value >> i) & 1 == 1) value ^= 0x1F25 << (i - 12);
    }
    final bits = (version << 12) | value;
    for (var i = 0; i < 18; i++) {
      final dark = (bits >> i) & 1 == 1;
      final across = size - 11 + i % 3, down = i ~/ 3;
      _set(across, down, dark); // top-right block
      _set(down, across, dark); // bottom-left block
    }
  }

  /// Zig-zag placement in two-module columns from the bottom-right corner,
  /// skipping the vertical timing line. Remainder bits stay light.
  void _placeCodewords(Uint8List codewords) {
    final totalBits = codewords.length * 8;
    var bit = 0;
    var upward = true;
    for (var right = size - 1; right >= 1; right -= 2) {
      if (right == 6) right = 5;
      for (var step = 0; step < size; step++) {
        final y = upward ? size - 1 - step : step;
        for (var x = right; x >= right - 1; x--) {
          final index = y * size + x;
          if (function[index] == 1) continue;
          if (bit < totalBits) {
            modules[index] = (codewords[bit >> 3] >> (7 - (bit & 7))) & 1;
          }
          bit++;
        }
      }
      upward = !upward;
    }
  }

  void _toggleMask(int mask) {
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final index = y * size + x;
        if (function[index] == 0 && _maskHit(mask, x, y)) {
          modules[index] ^= 1;
        }
      }
    }
  }

  /// Mask condition for column [x], row [y].
  static bool _maskHit(int mask, int x, int y) => switch (mask) {
    0 => (x + y) % 2 == 0,
    1 => y % 2 == 0,
    2 => x % 3 == 0,
    3 => (x + y) % 3 == 0,
    4 => (y ~/ 2 + x ~/ 3) % 2 == 0,
    5 => (x * y) % 2 + (x * y) % 3 == 0,
    6 => ((x * y) % 2 + (x * y) % 3) % 2 == 0,
    _ => ((x + y) % 2 + (x * y) % 3) % 2 == 0,
  };

  /// Penalty score of the current symbol, format information included.
  int _penalty() {
    var score = 0;
    final runs = Int32List(size + 2);
    for (var line = 0; line < size; line++) {
      score += _linePenalty(runs, line, horizontal: true);
      score += _linePenalty(runs, line, horizontal: false);
    }
    // N2: every 2 × 2 block of one color.
    for (var y = 0; y < size - 1; y++) {
      for (var x = 0; x < size - 1; x++) {
        final c = modules[y * size + x];
        if (c == modules[y * size + x + 1] &&
            c == modules[(y + 1) * size + x] &&
            c == modules[(y + 1) * size + x + 1]) {
          score += 3;
        }
      }
    }
    // N4: 10 for every full 5 % step the dark share lies beyond 45…55 %.
    var dark = 0;
    for (final m in modules) {
      dark += m;
    }
    final total = size * size;
    final deviation = (dark * 20 - total * 10).abs();
    score += ((deviation + total - 1) ~/ total - 1) * 10;
    return score;
  }

  /// N1 (runs of five or more) and N3 (1:1:3:1:1 finder-like patterns with
  /// four light modules on one side) for one row or column. The quiet zone
  /// counts as light beyond both ends.
  int _linePenalty(Int32List runs, int line, {required bool horizontal}) {
    var score = 0;
    var count = 0; // runs[0] is light, then colors alternate
    var color = 0;
    var length = 0;
    void close() {
      if (length >= 5) score += 3 + (length - 5);
      runs[count++] = length;
    }

    for (var i = 0; i < size; i++) {
      final m = horizontal
          ? modules[line * size + i]
          : modules[i * size + line];
      if (m == color) {
        length++;
      } else {
        close();
        color = m;
        length = 1;
      }
    }
    close();
    if (color == 1) runs[count++] = 0; // trailing light run of zero modules
    runs[0] += size;
    runs[count - 1] += size;

    // Dark runs sit at odd indices; a pattern needs a light run on each side.
    for (var d = 1; d + 5 < count; d += 2) {
      final n = runs[d];
      if (runs[d + 1] != n ||
          runs[d + 2] != 3 * n ||
          runs[d + 3] != n ||
          runs[d + 4] != n) {
        continue;
      }
      final before = runs[d - 1], after = runs[d + 5];
      if (before >= 4 * n && after >= n) score += 40;
      if (after >= 4 * n && before >= n) score += 40;
    }
    return score;
  }
}
