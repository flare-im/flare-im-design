import { mediaProxyFields } from "../shared/config/mediaProxy";

/** Rewrite message/CDN URLs for `<img>` / `<video>` in dev (same-origin storage proxy). */
export function proxiedMediaUrl(url: string | undefined): string {
  if (!url?.trim()) return url ?? "";
  const rewriteConfig = mediaProxyFields();
  try {
    const parsed = new URL(url);
    const target = `${parsed.protocol}//${parsed.host}`;
    const shouldRewrite = rewriteConfig.storageProxyTargets?.some((item) => item.replace(/\/$/, "") === target);
    const prefix = rewriteConfig.storageProxyPrefix;
    if (prefix && shouldRewrite) {
      return `${prefix}${parsed.pathname}${parsed.search}`;
    }
  } catch {
    return url;
  }
  return url;
}
