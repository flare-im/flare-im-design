/**
 * Swipe to reply on a message row (spec/swipe-reply-vectors.json, the same rule as the Flutter, SwiftUI and Compose
 * kits). `dx` / `dy` are the touch's travel from where the finger went down, in CSS pixels; a positive `dx` moves
 * towards the trailing edge of a left-to-right layout. The list draws the row `travel` away from its resting place
 * while the finger is down and raises the reply on release only when `armed`.
 */
export interface FlareSwipeReplyGesture {
  /** How far the row is drawn from its resting place. Never negative: the direction is the layout's leading edge. */
  travel: number;
  /** Whether letting go now replies. The affordance is fully drawn here, so the reader knows before letting go. */
  armed: boolean;
}

/** Gesture geometry in CSS pixels: distances a hand works in, the same three numbers on the four kits. */
export const FLARE_SWIPE_REPLY_ARM_DISTANCE = 56;
export const FLARE_SWIPE_REPLY_MAX_TRAVEL = 72;
const RESISTANCE = 0.35;
const DOMINANCE = 1.25;

export const FLARE_SWIPE_REPLY_NONE: FlareSwipeReplyGesture = Object.freeze({ travel: 0, armed: false });

/**
 * Only the leading direction counts (mirrored under RTL), the list's own vertical scrolling wins any drag whose
 * horizontal travel is under 1.25 times its vertical travel, and the row follows the finger to 56 before it resists
 * at 0.35 and stops at 72.
 */
export function flareSwipeReplyGesture(dx: number, dy: number, options: { rtl?: boolean } = {}): FlareSwipeReplyGesture {
  if (!Number.isFinite(dx) || !Number.isFinite(dy)) return FLARE_SWIPE_REPLY_NONE;
  const leading = options.rtl ? dx < 0 : dx > 0;
  if (!leading) return FLARE_SWIPE_REPLY_NONE;
  const horizontal = Math.abs(dx);
  // A drag that is mostly vertical belongs to the timeline's own scrolling.
  if (horizontal < Math.abs(dy) * DOMINANCE) return FLARE_SWIPE_REPLY_NONE;
  const travel = horizontal <= FLARE_SWIPE_REPLY_ARM_DISTANCE
    ? horizontal
    : Math.min(FLARE_SWIPE_REPLY_MAX_TRAVEL, FLARE_SWIPE_REPLY_ARM_DISTANCE + (horizontal - FLARE_SWIPE_REPLY_ARM_DISTANCE) * RESISTANCE);
  return { travel, armed: travel >= FLARE_SWIPE_REPLY_ARM_DISTANCE };
}
