import { mediaProxyFields } from "../shared/config/mediaProxy";
import { FLARE_SAFE_URL_PROTOCOLS } from "../shared/contracts/url-safety";

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
  return mediaProxyFields().storageProxyPrefix?.trim().replace(/\/$/, "") || "/__flare-storage";
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

/**
 * The URL a download may fetch or hand to an anchor, or null.
 *
 * The URL comes from message content, which other people write. A programmatic click
 * on `<a href="javascript:…" download>` still runs the script in the page's origin —
 * `download` does not apply to that scheme — so a hostile image-group or file URL
 * became one-click stored XSS. Only web addresses (absolute, or relative to the page
 * such as the storage proxy path) and blobs this page created itself are accepted;
 * `javascript:`, `data:`, `vbscript:`, `file:`, `about:` and foreign blobs are refused.
 */
function downloadableHref(raw: string): string | null {
  // Tab / newline / CR are dropped by URL parsers (`java\tscript:`); a literal space
  // never appears in a real URL, so a sentence is not read as a relative path.
  const href = raw.trim().replace(/[\t\n\r]/g, "");
  if (!href || /\s/.test(href)) return null;
  const base = typeof window !== "undefined" && window.location?.href ? window.location.href : "http://localhost/";
  let resolved: URL;
  try {
    resolved = new URL(href, base);
  } catch {
    return null;
  }
  if (FLARE_SAFE_URL_PROTOCOLS.includes(resolved.protocol)) return href;
  if (resolved.protocol === "blob:") {
    try {
      return new URL(resolved.pathname).origin === new URL(base).origin ? href : null;
    } catch {
      return null;
    }
  }
  return null;
}

function triggerDownload(href: string, fileName: string, newTab = false): void {
  if (typeof document === "undefined") return;
  const anchor = document.createElement("a");
  anchor.href = href;
  anchor.download = safeDownloadFileName(fileName);
  anchor.rel = "noopener noreferrer";
  // A cross-origin address ignores `download` and would navigate: give it its own tab so the app stays.
  if (newTab) anchor.target = "_blank";
  anchor.style.display = "none";
  document.body.appendChild(anchor);
  anchor.click();
  anchor.remove();
}

/**
 * Save a file from a safe address. Resolves true when the browser was handed the file: fetched and
 * saved under `fileName`, or (for an address the page cannot fetch, such as a signed URL without
 * CORS) opened in a new tab where the browser saves or shows it. Resolves false when the address is
 * refused (unsafe scheme or foreign blob) and nothing happened.
 */
export async function downloadUrlWithFileName(
  url: string,
  fileName: string,
): Promise<boolean> {
  const href = downloadableHref(url);
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

  triggerDownload(href, safeName, !sameOriginHref(href));
  return true;
}

/** Same-origin addresses (and this page's blobs) honour `download`; others would navigate the page. */
function sameOriginHref(href: string): boolean {
  if (typeof window === "undefined") return false;
  try {
    const base = window.location.href;
    const resolved = new URL(href, base);
    const origin = resolved.protocol === "blob:" ? new URL(resolved.pathname).origin : resolved.origin;
    return origin === new URL(base).origin;
  } catch {
    return false;
  }
}
