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

const PAIRS: readonly AvatarTint[] = [
  { bg: "#DBEAFE", fg: "#1D4ED8" },
  { bg: "#E9D5FF", fg: "#6D28D9" },
  { bg: "#FBCFE8", fg: "#BE185D" },
  { bg: "#D1FAE5", fg: "#047857" },
  { bg: "#FEF3C7", fg: "#B45309" },
  { bg: "#E5E7EB", fg: "#374151" },
];

export function avatarTint(seed: string | null | undefined): AvatarTint {
  let hash = 0;
  for (const char of seed && seed.trim() ? seed : "user") {
    hash = char.charCodeAt(0) + ((hash << 5) - hash);
  }
  return PAIRS[Math.abs(hash) % PAIRS.length];
}
