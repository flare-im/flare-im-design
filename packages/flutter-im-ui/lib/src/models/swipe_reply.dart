import 'dart:math' as math;

/// How far a message row has been dragged sideways, and whether letting go of
/// it now starts a reply.
class FlareSwipeReplyGesture {
  const FlareSwipeReplyGesture({required this.travel, required this.armed});

  /// How far the row is drawn from its resting place, in logical pixels.
  /// Never negative: the direction is the layout's leading edge.
  final double travel;

  /// Whether releasing now replies. The affordance is fully drawn here, so the
  /// reader knows before letting go.
  final bool armed;

  static const FlareSwipeReplyGesture none = FlareSwipeReplyGesture(
    travel: 0,
    armed: false,
  );
}

/// Gesture geometry, in logical pixels. These are distances a hand works in,
/// not visual styling, so they are constants rather than design tokens — and
/// they are the same three numbers in the SwiftUI and Compose kits.
const double flareSwipeReplyArmDistance = 56;
const double flareSwipeReplyMaxTravel = 72;
const double _flareSwipeReplyResistance = 0.35;
const double _flareSwipeReplyDominance = 1.25;

/// The one swipe-to-reply rule, shared with the SwiftUI and Compose kits and
/// tested against `spec/swipe-reply-vectors.json`: only the leading direction
/// counts (mirrored under RTL), the list's own scrolling wins a drag that is
/// not mostly horizontal, and the row follows the finger to
/// [flareSwipeReplyArmDistance] before resisting and stopping at
/// [flareSwipeReplyMaxTravel].
FlareSwipeReplyGesture flareSwipeReplyGesture(
  double dx,
  double dy, {
  required bool rtl,
}) {
  final leading = rtl ? dx < 0 : dx > 0;
  if (!leading) return FlareSwipeReplyGesture.none;
  final horizontal = dx.abs();
  // A drag that is mostly vertical belongs to the timeline's own scrolling.
  if (horizontal < dy.abs() * _flareSwipeReplyDominance) {
    return FlareSwipeReplyGesture.none;
  }
  final travel = horizontal <= flareSwipeReplyArmDistance
      ? horizontal
      : math.min(
          flareSwipeReplyMaxTravel,
          flareSwipeReplyArmDistance +
              (horizontal - flareSwipeReplyArmDistance) *
                  _flareSwipeReplyResistance,
        );
  return FlareSwipeReplyGesture(
    travel: travel,
    armed: travel >= flareSwipeReplyArmDistance,
  );
}
