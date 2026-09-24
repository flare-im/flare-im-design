const MAX_CACHE_ITEMS = 96;
const MAX_FROZEN_SIDE = 96;
const MAX_SOURCE_SIDE = 4096;
const MAX_ENCODED_BYTES = 8 * 1024 * 1024;
const MAX_ACTIVE_FREEZES = 2;

const cache = new Map<string, string>();
const inflight = new Map<string, Promise<string>>();
const queue: Array<() => void> = [];
let activeFreezes = 0;

function remember(url: string, dataUrl: string): string {
  if (cache.has(url)) cache.delete(url);
  cache.set(url, dataUrl);
  while (cache.size > MAX_CACHE_ITEMS) {
    const oldest = cache.keys().next().value;
    if (!oldest) break;
    cache.delete(oldest);
  }
  return dataUrl;
}

function runLimited<T>(job: () => Promise<T>): Promise<T> {
  return new Promise<T>((resolve, reject) => {
    const run = () => {
      activeFreezes += 1;
      job()
        .then(resolve, reject)
        .finally(() => {
          activeFreezes -= 1;
          const next = queue.shift();
          if (next) next();
        });
    };
    if (activeFreezes < MAX_ACTIVE_FREEZES) run();
    else queue.push(run);
  });
}

export function peekFrozenStickerDataUrl(url: string): string | undefined {
  const hit = cache.get(url);
  if (!hit) return undefined;
  cache.delete(url);
  cache.set(url, hit);
  return hit;
}

export async function freezeStickerToStaticDataUrl(url: string): Promise<string> {
  if (!url) return url;
  const hit = cache.get(url);
  if (hit) return hit;
  const running = inflight.get(url);
  if (running) return running;

  const promise = runLimited(async () => {
    const secondHit = peekFrozenStickerDataUrl(url);
    if (secondHit) return secondHit;

    const res = await fetch(url);
    if (!res.ok) throw new Error(String(res.status));
    const blob = await res.blob();
    if (blob.size === 0 || blob.size > MAX_ENCODED_BYTES) throw new Error("static preview exceeds byte budget");
    const bmp = await createImageBitmap(blob);
    if (bmp.width < 1 || bmp.height < 1 || bmp.width > MAX_SOURCE_SIDE || bmp.height > MAX_SOURCE_SIDE) {
      bmp.close();
      throw new Error("static preview exceeds dimension budget");
    }
    const scale = Math.min(1, MAX_FROZEN_SIDE / Math.max(bmp.width, bmp.height));
    const width = Math.max(1, Math.round(bmp.width * scale));
    const height = Math.max(1, Math.round(bmp.height * scale));
    const canvas = document.createElement("canvas");
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext("2d", { alpha: true });
    if (!ctx) {
      bmp.close();
      return "";
    }
    ctx.drawImage(bmp, 0, 0, width, height);
    bmp.close();
    return remember(url, canvas.toDataURL("image/png"));
  // Never fall back to the animated source in a static surface. A broken
  // thumbnail is safer than silently starting animation inside the composer.
  }).catch(() => "");

  inflight.set(url, promise);
  try {
    return await promise;
  } finally {
    inflight.delete(url);
  }
}
