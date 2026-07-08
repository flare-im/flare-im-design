const FORMAT_GIF = 4;
const FORMAT_APNG = 5;

export type ImageSourceLike = {
  animated?: boolean;
  format?: number | string;
  mimeType?: string;
};

export function imageInfoIsMotion(source: ImageSourceLike | null | undefined): boolean {
  if (!source) return false;
  if (source.animated) return true;
  const fmt = typeof source.format === "number" ? source.format : Number(source.format ?? 0);
  if (fmt === FORMAT_GIF || fmt === FORMAT_APNG) return true;
  const mime = String(source.mimeType ?? "").toLowerCase();
  return mime.includes("gif") || mime.includes("apng");
}
