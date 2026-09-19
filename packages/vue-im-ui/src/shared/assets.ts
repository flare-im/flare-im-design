/**
 * Where the kit's emoji and sticker resources are served. Hosts that deploy under a
 * sub-path (`/app/`) or a CDN set it once through FlareUiProvider `assetBaseUrl`.
 */
const DEFAULT_ASSET_BASE_URL = "/flare-im-ui-assets";

let assetBaseUrl = DEFAULT_ASSET_BASE_URL;

export function setFlareAssetBaseUrl(url: string | undefined): void {
  const value = (url ?? "").trim().replace(/\/+$/, "");
  assetBaseUrl = value || DEFAULT_ASSET_BASE_URL;
}

export function flareAssetBaseUrl(): string {
  return assetBaseUrl;
}

/** URL of a resource path (`emoji/grinning_face.webp`) under the asset base. */
export function flareAssetUrl(path: string): string {
  return `${assetBaseUrl}/${path.replace(/^\/+/, "")}`;
}
