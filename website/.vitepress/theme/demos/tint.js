// Pastel identity palette — the soft avatar look from the reference app
// (flare-core-flutter-app · FlareImDesign.avatarPastelForKey). Soft tinted
// background + dark initials reads far more premium than a saturated solid,
// and stays legible in light and dark. Keyed by a stable id so a given person
// always gets the same tint.
export const AVATAR_TINTS = [
  { bg: "#DBEAFE", fg: "#1D4ED8" }, // blue
  { bg: "#E9D5FF", fg: "#6D28D9" }, // purple
  { bg: "#FBCFE8", fg: "#BE185D" }, // pink
  { bg: "#D1FAE5", fg: "#047857" }, // green
  { bg: "#FEF3C7", fg: "#B45309" }, // amber
  { bg: "#E5E7EB", fg: "#374151" }, // slate
];

function hash(key) {
  let h = 0;
  for (const ch of String(key || "user")) h = ch.charCodeAt(0) + ((h << 5) - h);
  return Math.abs(h);
}

/** Stable pastel { bg, fg } for a key. */
export function tint(key) {
  return AVATAR_TINTS[hash(key) % AVATAR_TINTS.length];
}

/** initials from a display name (first char, or first char of two words). */
export function initials(name) {
  const parts = String(name || "").trim().split(/\s+/);
  const s = parts.length > 1 ? parts[0][0] + parts[1][0] : (parts[0] || "?")[0];
  return (s || "?").toUpperCase();
}
