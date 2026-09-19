/**
 * Which URLs a chat surface may navigate to.
 *
 * Message content is written by other people. A link in it is a string an
 * attacker chose, so the only safe default is: render it as text unless it is
 * plainly a web address. `javascript:` and `data:` in an `href` execute in the
 * page's origin; `file:` and `blob:` read local state.
 *
 * The kit itself almost never navigates — components report the URL and the host
 * opens it. This is the rule both sides apply, so the kit's two anchors and the
 * host's own open-link handler cannot disagree.
 */

/** The only schemes a message link may carry. */
export const FLARE_SAFE_URL_PROTOCOLS: readonly string[] = ["http:", "https:"];

/**
 * The URL to navigate to, or null when the string is not a safe web address.
 *
 * A scheme-less string is read as https — that is what a user typing
 * `example.com` means — but only when it carries no scheme at all, so
 * `javascript:alert(1)` is never rescued into `https://javascript:alert(1)`.
 */
export function safeExternalUrl(raw: string | null | undefined): string | null {
  if (typeof raw !== "string") return null;
  // Strip only what a URL parser itself ignores — tab, newline, carriage return
  // — so `java\tscript:` normalizes to `javascript:` before the check. Interior
  // spaces must stay: removing them would turn a sentence (`just some text`)
  // into a valid host name.
  const trimmed = raw.trim().replace(/[\t\n\r]/g, "");
  if (!trimmed) return null;
  // A real URL carries no literal space. Refusing one keeps a sentence from
  // being read as an address, and keeps the four platforms identical by rule
  // rather than by whichever parser happens to be stricter: Dart's `Uri` would
  // percent-encode `just some text` into a valid host, JavaScript's `URL` throws.
  if (/\s/.test(trimmed)) return null;
  const candidate = hasScheme(trimmed) ? trimmed : `https://${trimmed}`;
  let parsed: URL;
  try {
    parsed = new URL(candidate);
  } catch {
    return null;
  }
  if (!FLARE_SAFE_URL_PROTOCOLS.includes(parsed.protocol)) return null;
  if (!parsed.hostname) return null;
  return parsed.href;
}

/** Whether the string is a web address this surface may open. */
export function isSafeExternalUrl(raw: string | null | undefined): boolean {
  return safeExternalUrl(raw) !== null;
}

/**
 * `scheme:` at the start, per RFC 3986 — letters, digits, `+`, `-`, `.`.
 *
 * A host and a port look the same to that grammar (`example.com:8443` is a legal
 * scheme followed by nothing), so a colon followed by digits is read as a port.
 * The worst that mis-reading can produce is an https URL to a host with an odd
 * name, which is harmless; reading a real scheme as a host is what must not
 * happen, and that is the direction this errs away from.
 */
function hasScheme(value: string): boolean {
  const match = /^[a-z][a-z0-9+.-]*:/i.exec(value);
  if (!match) return false;
  return !/^\d/.test(value.slice(match[0].length));
}
