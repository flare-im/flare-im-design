import { sdkMediaProxyFields } from "../shared/config/mediaProxy";

export function safeDownloadFileName(fileName: string): string {
  const trimmed = fileName.trim();
  if (!trimmed) return "download";
  const basename = trimmed
    .replace(/\\/g, "/")
    .split("/")
    .filter(Boolean)
    .pop() ?? "download";
  const safe = basename
    .replace(/[\u0000-\u001f<>:"|?*]+/g, "_")
    .replace(/\s+/g, " ")
    .replace(/^\.+|\.+$/g, "")
    .trim();
  return safe || "download";
}

function storageProxyPrefix(): string {
  return sdkMediaProxyFields().storageProxyPrefix?.trim().replace(/\/$/, "") || "/__flare-storage";
}

function isStorageProxyPath(path: string, prefix: string): boolean {
  return path === prefix || path.startsWith(`${prefix}/`);
}

function isLocalStorageProxyUrl(href: string): boolean {
  const prefix = storageProxyPrefix();
  try {
    const base =
      typeof window !== "undefined" && window.location?.href
        ? window.location.href
        : "http://localhost";
    const path = new URL(href, base).pathname;
    return isStorageProxyPath(path, prefix);
  } catch {
    return isStorageProxyPath(href, prefix);
  }
}

function triggerDownload(href: string, fileName: string): void {
  if (typeof document === "undefined") return;
  const anchor = document.createElement("a");
  anchor.href = href;
  anchor.download = safeDownloadFileName(fileName);
  anchor.rel = "noopener";
  anchor.style.display = "none";
  document.body.appendChild(anchor);
  anchor.click();
  anchor.remove();
}

export async function downloadUrlWithFileName(
  url: string,
  fileName: string,
): Promise<boolean> {
  const href = url.trim();
  if (!href || typeof document === "undefined") return false;
  const safeName = safeDownloadFileName(fileName);

  if (isLocalStorageProxyUrl(href)) {
    triggerDownload(href, safeName);
    return true;
  }

  if (typeof fetch === "function" && typeof URL !== "undefined" && "createObjectURL" in URL) {
    try {
      const response = await fetch(href, { credentials: "include" });
      if (response.ok) {
        const blob = await response.blob();
        const objectUrl = URL.createObjectURL(blob);
        triggerDownload(objectUrl, safeName);
        window.setTimeout(() => URL.revokeObjectURL(objectUrl), 30_000);
        return true;
      }
    } catch {
      // A direct anchor fallback still lets the browser handle non-CORS or native app URLs.
    }
  }

  triggerDownload(href, safeName);
  return false;
}
