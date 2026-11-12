/// Deterministic camera-independent scan arbitration. Shared vectors: spec/scan-gate-vectors.json.
class FlareScanPoint {
  const FlareScanPoint(this.x, this.y);
  final double x;
  final double y;
}
class FlareScanCode {
  const FlareScanCode(this.raw, {this.corners = const []});
  final String raw;
  final List<FlareScanPoint> corners;
}
class FlareScanHit {
  const FlareScanHit._(this.kind, {this.code, this.ready = false, this.codes = const []});
  static const ignore = FlareScanHit._('ignore');
  factory FlareScanHit.lock(FlareScanCode code, bool ready) => FlareScanHit._('lock', code: code, ready: ready);
  factory FlareScanHit.choose(List<FlareScanCode> codes) => FlareScanHit._('choose', codes: List.unmodifiable(codes));
  final String kind;
  final FlareScanCode? code;
  final bool ready;
  final List<FlareScanCode> codes;
}
class FlareScanHitGate {
  String _phase = 'idle';
  int _startedAt = 0;
  int? _lastAt;
  final Map<String, FlareScanCode> _candidates = {};
  final Map<String, int?> _suppressed = {};
  String? _selected;
  FlareScanHit observe({required List<FlareScanCode> codes, required int tsMs}) {
    if (_lastAt != null && tsMs < _lastAt!) return FlareScanHit.ignore;
    _lastAt = tsMs;
    final visible = {for (final code in codes) if (code.raw.isNotEmpty) code.raw: code};
    for (final raw in _suppressed.keys.toList()) {
      final absentAt = _suppressed[raw];
      if (absentAt != null && tsMs - absentAt >= 1500) { _suppressed.remove(raw); }
      else if (visible.containsKey(raw)) { _suppressed[raw] = null; }
      else if (absentAt == null) { _suppressed[raw] = tsMs; }
      else if (tsMs - absentAt >= 1500) { _suppressed.remove(raw); }
    }
    if (_phase == 'busy' || _phase == 'choosing') return FlareScanHit.ignore;
    final available = visible.values.where((code) => !_suppressed.containsKey(code.raw)).toList();
    if (_phase == 'idle') {
      if (available.isEmpty) return FlareScanHit.ignore;
      _phase = 'collecting'; _startedAt = tsMs; _candidates.clear();
      for (final code in available) { _candidates[code.raw] = code; }
      return FlareScanHit.lock(available.first, false);
    }
    for (final code in available) { _candidates[code.raw] = code; }
    if (tsMs - _startedAt < 150) return FlareScanHit.ignore;
    final found = _candidates.values.toList();
    if (found.length > 1) { _phase = 'choosing'; return FlareScanHit.choose(found); }
    _phase = 'busy'; _selected = found.first.raw;
    return FlareScanHit.lock(found.first, true);
  }
  FlareScanHit select(String raw) {
    final code = _candidates[raw];
    if (_phase != 'choosing' || code == null) return FlareScanHit.ignore;
    _phase = 'busy'; _selected = raw;
    return FlareScanHit.lock(code, true);
  }
  void dismiss() {
    for (final raw in _selected != null ? [_selected!] : _candidates.keys) { _suppressed[raw] = null; }
    _candidates.clear(); _selected = null; _phase = 'idle';
  }
}
