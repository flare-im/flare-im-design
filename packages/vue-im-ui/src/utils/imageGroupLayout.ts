/**
 * How an image-group (album) body lays out `count` images: square tiles in `columns` columns, `visible`
 * of them drawn, and the last drawn tile reading `+more` when there are more images than tiles. The rule
 * is shared with the three native kits (`spec/image-group-layout-vectors.json`).
 */
export interface FlareImageGroupLayout {
  columns: number;
  visible: number;
  more: number;
}

/** At most this many tiles are drawn. */
export const FLARE_IMAGE_GROUP_MAX_VISIBLE = 9;

export function flareImageGroupLayout(count: number): FlareImageGroupLayout {
  if (!Number.isFinite(count) || count <= 0) return { columns: 0, visible: 0, more: 0 };
  const whole = Math.floor(count);
  const visible = Math.min(whole, FLARE_IMAGE_GROUP_MAX_VISIBLE);
  return {
    columns: whole === 4 ? 2 : Math.min(whole, 3),
    visible,
    more: whole > FLARE_IMAGE_GROUP_MAX_VISIBLE ? whole - FLARE_IMAGE_GROUP_MAX_VISIBLE + 1 : 0,
  };
}
