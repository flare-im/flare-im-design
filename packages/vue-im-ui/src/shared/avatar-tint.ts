/**
 * Deterministic avatar tint — a soft pastel surface + dark initials, keyed off a
 * stable identity. Shared by every avatar surface (FlareAvatar, message bubbles, …)
 * so the SAME person renders the SAME colour everywhere: conversation list, chat
 * header, and message bubbles.
 *
 * Seed by the display name first: it's the human-visible identity and is consistent
 * across surfaces, whereas the id passed to an avatar varies (peer id vs
 * conversation id vs sender id), which is what made one person show three colours.
 */
export interface AvatarTint {
  bg: string;
  fg: string;
}

// Theme-aware: the values live in component-tokens.css (light and dark).
const PAIRS: readonly AvatarTint[] = [1, 2, 3, 4, 5, 6].map((index) => ({
  bg: `var(--flare-component-avatar-tint-${index}-bg)`,
  fg: `var(--flare-component-avatar-tint-${index}-fg)`,
}));

export function avatarTint(seed: string | null | undefined): AvatarTint {
  let hash = 0;
  for (const char of seed && seed.trim() ? seed : "user") {
    hash = char.charCodeAt(0) + ((hash << 5) - hash);
  }
  return PAIRS[Math.abs(hash) % PAIRS.length];
}
