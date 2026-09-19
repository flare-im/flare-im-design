export const EXTRA_GIF_PLAY_ANIMATED = "gif_play_animated" as const;
export const EXTRA_STICKER_PLAY_ANIMATED = "sticker_play_animated" as const;

export function isGifPlayAnimatedFromExtra(extra: Record<string, string> | null | undefined): boolean {
  if (!extra) return false;
  const value = extra[EXTRA_GIF_PLAY_ANIMATED];
  if (value === "0" || value === "false") return false;
  if (value === "1" || value === "true") return true;
  return false;
}

export function isStickerPlayAnimatedFromExtra(extra: Record<string, string> | null | undefined): boolean {
  if (!extra) return true;
  const value = extra[EXTRA_STICKER_PLAY_ANIMATED];
  if (value == null || value === "") return true;
  if (value === "0" || value === "false") return false;
  if (value === "1" || value === "true") return true;
  return true;
}
