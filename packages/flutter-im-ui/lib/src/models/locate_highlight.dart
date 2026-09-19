/// The mark a located row wears while the reader's eye catches up with the jump.
class FlareLocateHighlight {
  const FlareLocateHighlight({
    required this.marked,
    required this.alpha,
    required this.spread,
  });

  /// Whether the row is marked at all. False once the window is over.
  final bool marked;

  /// The ring's opacity.
  final double alpha;

  /// How far the ring reaches beyond the bubble's edge, in logical pixels.
  final double spread;

  static const FlareLocateHighlight none = FlareLocateHighlight(
    marked: false,
    alpha: 0,
    spread: 0,
  );
}

/// How long a located row stays marked. One number: the ring reaches nothing
/// exactly as the window closes.
const int flareLocateHighlightDurationMs = 1600;

const _stops = <({int atMs, double alpha, double spread})>[
  (atMs: 0, alpha: 0.36, spread: 0),
  (atMs: 700, alpha: 0.18, spread: 10),
  (atMs: flareLocateHighlightDurationMs, alpha: 0, spread: 18),
];

/// Held still for a reader who asked for less motion: the middle stop, for the
/// whole window. Less motion is not no answer — the jump still has to say where
/// it landed.
const _reducedMotion = FlareLocateHighlight(marked: true, alpha: 0.18, spread: 10);

/// The one locate-mark rule, shared with the SwiftUI and Compose kits and with
/// Vue's stylesheet, and tested against `spec/locate-highlight-vectors.json`.
/// [elapsedMs] counts from the moment the list started moving towards the row.
FlareLocateHighlight flareLocateHighlight(
  double elapsedMs, {
  required bool reduceMotion,
}) {
  if (elapsedMs >= flareLocateHighlightDurationMs) {
    return FlareLocateHighlight.none;
  }
  if (reduceMotion) return _reducedMotion;
  final elapsed = elapsedMs < 0 ? 0.0 : elapsedMs;
  for (var i = 0; i < _stops.length - 1; i++) {
    final from = _stops[i];
    final to = _stops[i + 1];
    if (elapsed > to.atMs) continue;
    final t = (elapsed - from.atMs) / (to.atMs - from.atMs);
    return FlareLocateHighlight(
      marked: true,
      alpha: from.alpha + (to.alpha - from.alpha) * t,
      spread: from.spread + (to.spread - from.spread) * t,
    );
  }
  return FlareLocateHighlight.none;
}
