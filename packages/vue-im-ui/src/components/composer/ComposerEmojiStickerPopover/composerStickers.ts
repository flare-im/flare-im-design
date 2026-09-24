/**
 * 输入框「贴纸」面板：资源来自 `src/chat/assets/stickers/<package_dir>/*.webp`。
 * - **`classic/`**：示例主贴纸包（如 Giphy 同系列），`packageId = classic`。
 * - **`default/`**：沿用原 `assets/gifs` 语义，**`packageId = gifs`**。
 * - 其他子目录名即 `packageId`（如 `stickers/acme/foo.webp` → `packageId=acme`）。
 */
import classicManifest from "../../../assets/emoji-sticker/stickers/classic/manifest.json";
import { flareAssetUrl } from "../../../shared/assets";
import { reactive } from "vue";

export const CLASSIC_STICKER_PACKAGE_ID = "classic";
export const DEFAULT_STICKER_PACKAGE_ID = "gifs";

type AssetUrlLoader = () => Promise<string>;
const DEFAULT_STICKER_COUNT = 68;

export interface ComposerStickerItem {
  id: string;
  stickerId: string;
  packageId: string;
  loadUrl: AssetUrlLoader;
  loadPreviewUrl: AssetUrlLoader;
  alt: string;
}

export interface ComposerStickerAssetRegistration {
  stickerId: string;
  /** Original source; message hosts may retain it for transport metadata. */
  url: string;
  /** Optional static thumbnail; renderers always freeze frame zero as well. */
  previewUrl?: string;
  alt?: string;
}

export interface ComposerStickerPackRegistration {
  packageId: string;
  title: string;
  stickers: readonly ComposerStickerAssetRegistration[];
  iconUrl?: string;
}

export interface ComposerStickerPack {
  packageId: string;
  title: string;
  items: ComposerStickerItem[];
  loadIconUrl?: AssetUrlLoader;
  runtime?: boolean;
}

const stickerUrlByKey = new Map<string, string>();
const runtimeStickerPacks = new Map<string, ComposerStickerPackRegistration>();

function stickerSubdirForPackageId(packageId: string): string {
  return packageId === DEFAULT_STICKER_PACKAGE_ID ? "default" : packageId;
}

function assetUrl(path: string): string {
  return flareAssetUrl(path);
}

function stickerKey(packageId: string, stickerId: string): string {
  return `${packageId}/${stickerId}`;
}

async function loadStickerUrl(packageId: string, stickerId: string): Promise<string> {
  const runtime = runtimeStickerPacks.get(packageId)?.stickers.find((item) => item.stickerId === stickerId);
  if (runtime) return runtime.url;
  const key = stickerKey(packageId, stickerId);
  const cached = stickerUrlByKey.get(key);
  if (cached) return cached;
  if (!knownStickerKeys.has(key)) return "";
  const url = assetUrl(`stickers/${stickerSubdirForPackageId(packageId)}/${encodeURIComponent(stickerId)}.webp`);
  stickerUrlByKey.set(key, url);
  return url;
}

async function loadStickerPreviewUrl(packageId: string, stickerId: string): Promise<string> {
  const runtime = runtimeStickerPacks.get(packageId)?.stickers.find((item) => item.stickerId === stickerId);
  return runtime?.previewUrl?.trim() || loadStickerUrl(packageId, stickerId);
}

type ClassicStickerManifestEntry = { filename: string };

function fileStem(filename: string): string {
  return filename.replace(/\.webp$/i, "");
}

function indexFileName(index: number): string {
  return `${String(index).padStart(3, "0")}.webp`;
}

function buildStickerItem(packageId: string, filename: string, index: number): ComposerStickerItem {
  const stickerId = fileStem(filename);
  return {
    id: `composer-sticker-${packageId}-${String(index + 1).padStart(3, "0")}`,
    stickerId,
    packageId,
    loadUrl: () => loadStickerUrl(packageId, stickerId),
    loadPreviewUrl: () => loadStickerPreviewUrl(packageId, stickerId),
    alt: `Sticker ${stickerId}`,
  };
}

const classicStickerItems = (classicManifest as ClassicStickerManifestEntry[])
  .map((entry) => entry.filename)
  .sort((a, b) => fileStem(a).localeCompare(fileStem(b), undefined, { numeric: true }))
  .map((filename, i) => buildStickerItem(CLASSIC_STICKER_PACKAGE_ID, filename, i));

const defaultStickerItems = Array.from({ length: DEFAULT_STICKER_COUNT }, (_, i) =>
  buildStickerItem(DEFAULT_STICKER_PACKAGE_ID, indexFileName(i + 1), i),
);

export const COMPOSER_STICKER_ITEMS: ComposerStickerItem[] = [
  ...classicStickerItems,
  ...defaultStickerItems,
];

const knownStickerKeys = new Set(COMPOSER_STICKER_ITEMS.map((item) => stickerKey(item.packageId, item.stickerId)));

/** 主贴纸包（`stickers/classic/`，协议 `packageId=classic`） */
export const COMPOSER_CLASSIC_STICKER_ITEMS: ComposerStickerItem[] = COMPOSER_STICKER_ITEMS.filter(
  (it) => it.packageId === CLASSIC_STICKER_PACKAGE_ID,
);

/** `stickers/default/`，协议 `packageId=gifs` */
export const COMPOSER_DEFAULT_STICKER_ITEMS: ComposerStickerItem[] = COMPOSER_STICKER_ITEMS.filter(
  (it) => it.packageId === DEFAULT_STICKER_PACKAGE_ID,
);

/** 其它子目录贴纸（非 classic、非 default） */
export const COMPOSER_OTHER_STICKER_ITEMS: ComposerStickerItem[] = COMPOSER_STICKER_ITEMS.filter(
  (it) => it.packageId !== CLASSIC_STICKER_PACKAGE_ID && it.packageId !== DEFAULT_STICKER_PACKAGE_ID,
);

const bundledStickerPacks: ComposerStickerPack[] = [
  {
    packageId: CLASSIC_STICKER_PACKAGE_ID,
    title: "Classic",
    items: COMPOSER_CLASSIC_STICKER_ITEMS,
    loadIconUrl: COMPOSER_CLASSIC_STICKER_ITEMS[0]?.loadPreviewUrl,
  },
  {
    packageId: DEFAULT_STICKER_PACKAGE_ID,
    title: "Default",
    items: COMPOSER_DEFAULT_STICKER_ITEMS,
    loadIconUrl: COMPOSER_DEFAULT_STICKER_ITEMS[0]?.loadPreviewUrl,
  },
];

/** Reactive merged pack list used by the shared picker. */
export const COMPOSER_STICKER_PACKS = reactive<ComposerStickerPack[]>([...bundledStickerPacks]);

function safeComponent(value: string): boolean {
  return /^[A-Za-z0-9_-]+$/.test(value);
}

function rebuildStickerCatalog(): void {
  const runtimePacks = [...runtimeStickerPacks.values()].map((pack): ComposerStickerPack => {
    const items = pack.stickers
      .filter((asset) => safeComponent(asset.stickerId.trim()) && asset.url.trim())
      .map((asset, index): ComposerStickerItem => {
        const stickerId = asset.stickerId.trim();
        return {
          id: `composer-sticker-runtime-${pack.packageId}-${stickerId}-${index}`,
          stickerId,
          packageId: pack.packageId,
          loadUrl: async () => asset.url.trim(),
          loadPreviewUrl: async () => asset.previewUrl?.trim() || asset.url.trim(),
          alt: asset.alt?.trim() || `Sticker ${stickerId}`,
        };
      });
    return {
      packageId: pack.packageId,
      title: pack.title,
      items,
      runtime: true,
      loadIconUrl: pack.iconUrl?.trim()
        ? async () => pack.iconUrl!.trim()
        : items[0]?.loadPreviewUrl,
    };
  });
  const bundled = bundledStickerPacks.filter((pack) => !runtimeStickerPacks.has(pack.packageId));
  COMPOSER_STICKER_PACKS.splice(0, COMPOSER_STICKER_PACKS.length, ...bundled, ...runtimePacks);
  const all = COMPOSER_STICKER_PACKS.flatMap((pack) => pack.items);
  COMPOSER_STICKER_ITEMS.splice(0, COMPOSER_STICKER_ITEMS.length, ...all);
  knownStickerKeys.clear();
  for (const item of all) knownStickerKeys.add(stickerKey(item.packageId, item.stickerId));
}

/** Adds/replaces user sticker packs. IDs remain the protocol package/sticker IDs. */
export function registerComposerStickerPacks(packs: readonly ComposerStickerPackRegistration[]): void {
  for (const raw of packs) {
    const packageId = raw.packageId.trim();
    if (!safeComponent(packageId) || !raw.title.trim()) continue;
    runtimeStickerPacks.set(packageId, { ...raw, packageId, title: raw.title.trim() });
  }
  rebuildStickerCatalog();
}

export function unregisterComposerStickerPack(packageId: string): void {
  runtimeStickerPacks.delete(packageId.trim());
  rebuildStickerCatalog();
}

export function clearComposerStickerPackRegistrations(): void {
  runtimeStickerPacks.clear();
  rebuildStickerCatalog();
}

/**
 * 底栏「贴纸包」Tab 图标（可选，静态展示、不播放动图）。
 * - 未设置或空字符串：使用该包内第一张贴纸的 URL，由面板用首帧冻结组件显示。
 * - 可设为任意静态资源 URL（如 `import icon from '...png'`），同样走冻结首帧（单帧无影响）。
 *
 * 键与 UI 分包一致：`default` → stickers/default（协议包 id `gifs`），`classic` → stickers/classic。
 */
export const COMPOSER_STICKER_PACK_TAB_ICON_URL: Partial<Record<"default" | "classic", string>> = {
  // 示例：default: new URL("../../../assets/stickers/tab-default.png", import.meta.url).href,
};

/**
 * 根据协议里的 `packageId` + `stickerId` 解析示例应用打包后的贴纸 URL。
 * 用于会话里展示：消息里存的 `url` 可能是开发态路径（如 `/src/assets/...`），在 Vite 产物中无效。
 */
export async function resolveStickerUrlByPackageAndId(
  packageId: string,
  stickerId: string,
): Promise<string | undefined> {
  const pid = packageId.trim();
  const sid = stickerId.trim();
  if (!pid || !sid) return undefined;
  const key = stickerKey(pid, sid);
  if (!knownStickerKeys.has(key)) return undefined;
  return loadStickerUrl(pid, sid);
}

export async function resolveStickerPreviewUrlByPackageAndId(
  packageId: string,
  stickerId: string,
): Promise<string | undefined> {
  const pid = packageId.trim();
  const sid = stickerId.trim();
  if (!pid || !sid || !knownStickerKeys.has(stickerKey(pid, sid))) return undefined;
  return loadStickerPreviewUrl(pid, sid);
}
