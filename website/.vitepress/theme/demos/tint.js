// Identity tint for the home showcase — read from the kit's own palette rather than a copy of it.
//
// This file used to hold six hex pairs "matching" the kit. Copies drift: the pink pair kept the
// 4.4:1 foreground the kit had already moved off, and there was no dark set at all, so the home
// page showed avatars the kit itself never renders. The kit publishes the palette as
// `--flare-component-avatar-tint-{1..6}-{bg,fg}` (component-tokens.css, light and dark); the same
// hash as `shared/avatar-tint.ts` keeps one person on one slot across the docs and the kit.
export const AVATAR_TINTS = [1, 2, 3, 4, 5, 6].map((index) => ({
  bg: `var(--flare-component-avatar-tint-${index}-bg)`,
  fg: `var(--flare-component-avatar-tint-${index}-fg)`,
}));

function hash(key) {
  let h = 0;
  for (const ch of String(key || "user")) h = ch.charCodeAt(0) + ((h << 5) - h);
  return Math.abs(h);
}

/** Stable { bg, fg } for a key, as CSS variable references that follow the active theme. */
export function tint(key) {
  return AVATAR_TINTS[hash(key) % AVATAR_TINTS.length];
}
