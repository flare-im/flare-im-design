/**
 * Same-origin endpoint derivation: one build artifact, any host.
 *
 * When the host app ships without explicit `VITE_FLARE_WS_URL` / `VITE_FLARE_HTTP_URL`,
 * derive them from `window.location` so the bundle is not pinned to a hostname baked in
 * at build time. The paths match the reverse-proxy routes a deployment is expected to
 * expose (`/ws` → access gateway, `/api` → HTTP gateway), which also means the login form
 * needs no hand-typed server address.
 *
 * Explicit configuration always wins: local development points `.env` at 127.0.0.1, and a
 * non-blank value is kept as-is. QUIC is deliberately not derived — UDP cannot be routed by
 * path, so its port is deployment-specific and must stay explicit.
 */
export function withSameOriginEndpoints(
  env: Record<string, string | undefined>,
): Record<string, string | undefined> {
  if (typeof window === "undefined") return env;
  const location = window.location;
  if (!location?.host) return env;

  const secure = location.protocol === "https:";
  const resolved = { ...env };
  fillWhenBlank(resolved, "VITE_FLARE_WS_URL", `${secure ? "wss:" : "ws:"}//${location.host}/ws`);
  fillWhenBlank(resolved, "VITE_FLARE_HTTP_URL", `${location.protocol}//${location.host}/api`);
  return resolved;
}

function fillWhenBlank(env: Record<string, string | undefined>, key: string, value: string): void {
  if (!String(env[key] ?? "").trim()) env[key] = value;
}
