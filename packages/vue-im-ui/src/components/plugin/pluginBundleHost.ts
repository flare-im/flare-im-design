/**
 * The contract of FlarePluginBundleHost (design 8.4 to 8.6): what a host hands the kit to run one plugin web bundle in a
 * sandboxed frame, and the pure rules the component applies. The kit only moves envelopes between the frame and the
 * host's bridge and draws the `ui.*` requests the engine leaves to the host; every bridge check (version, handshake,
 * permission, operation, rate) is the engine's.
 */

/** The frame's sandbox: scripts and forms only. No same-origin (an opaque origin), no popups, no top navigation. */
export const FLARE_PLUGIN_BUNDLE_SANDBOX = "allow-scripts allow-forms";

/** The largest envelope the kit hands on, in UTF-16 code units of its JSON text (the bridge's 64 KiB, with room for escapes). */
export const FLARE_PLUGIN_BUNDLE_MAX_ENVELOPE_CHARS = 64 * 1024;

/** How long a gesture inside the frame (a press or focus moving into it) counts as recent, in ms. */
export const FLARE_PLUGIN_BUNDLE_GESTURE_MS = 5000;

/** How long the kit waits for the bundle's `host.hello` before it shows the load failure, in ms. */
export const FLARE_PLUGIN_BUNDLE_HELLO_TIMEOUT_MS = 15000;

/** One bridge message, camelCase (`flare_plugin_protocol::bridge::BridgeEnvelope`). The kit reads only `id` and `type`. */
export interface FlarePluginBundleEnvelope {
  bridge?: number;
  id?: string;
  type?: "request" | "response" | "event" | string;
  method?: string;
  params?: unknown;
  result?: unknown;
  error?: { code: string; messageKey?: string; pluginCode?: string };
  event?: string;
  payload?: unknown;
}

/** A request the engine leaves to the host (`plugin_bundle_bridge` answering `{host}`): the kit draws it. */
export interface FlarePluginBundleHostRequest {
  id: string;
  method: string;
  params?: Record<string, unknown>;
}

/** What the bridge answers a message: the envelope to post back, a host request to draw, or nothing (drop it). */
export type FlarePluginBundleAnswer =
  | FlarePluginBundleEnvelope
  | { envelope: FlarePluginBundleEnvelope }
  | { host: FlarePluginBundleHostRequest }
  | null
  | undefined;

/** The codes a host may answer a host request with (`plugin_bundle_host_result`). */
export type FlarePluginBundleHostError = "cancelled" | "unavailable" | "gesture_required" | "timeout" | "not_found";

/** Something the bridge sends on its own: an event envelope to post, or the end of the page (`close`). */
export interface FlarePluginBundleBridgeEvent {
  envelope?: FlarePluginBundleEnvelope;
  /** `withdrawn`, `suspended`, `disabled`, `replaced`, `evicted` or `signedOut`: the page closes. */
  close?: string;
}

/**
 * The host's side of one open bundle page. Envelopes travel as objects; a bridge over a string transport
 * (`plugin_bundle_bridge`) parses and serializes them itself.
 */
export interface FlarePluginBundleBridge {
  /** One message the page posted, with the host's own record of a recent gesture (never the page's claim). */
  request(envelope: FlarePluginBundleEnvelope, context: { userGesture: boolean }): Promise<FlarePluginBundleAnswer>;
  /**
   * The kit's answer to a host request (`plugin_bundle_host_result`); resolves with the envelope to post. Without it the
   * kit builds the response envelope itself (a mock bridge).
   */
  hostResult?(id: string, outcome: { result?: Record<string, unknown>; error?: FlarePluginBundleHostError }): Promise<FlarePluginBundleAnswer>;
  /** A host event (`theme.changed`, `locale.changed`, `visibility.changed`) for this page: the envelopes to post, if subscribed. */
  hostEvent?(event: string, payload: Record<string, unknown>): Promise<readonly FlarePluginBundleEnvelope[]>;
  /** What the bridge sends on its own (an event envelope, or close). A bare envelope is taken as `{envelope}`. */
  subscribe?(listener: (event: FlarePluginBundleBridgeEvent | FlarePluginBundleEnvelope) => void): () => void;
  /** The page went away (unmounted, the document unloaded): end the session. Called once. */
  close?(): void;
}

/** The theme a host passes: the mode and its token overrides (`BridgeTheme`). */
export interface FlarePluginBundleTheme {
  mode: "light" | "dark";
  tokens?: Record<string, string>;
}

/** Where the page shows: a screen of its own, a card's detail, or a "+" form (`BridgePresentation`). */
export type FlarePluginBundlePresentation = "page" | "detail" | "composerForm";

/** The bridge error codes (`BridgeErrorCode`), each with its kit string `pluginBundle.error.<lowerCamel>`. */
export const FLARE_PLUGIN_BRIDGE_ERROR_CODES = [
  "invalid_envelope", "unsupported_bridge", "not_ready", "method_not_found", "invalid_params", "payload_too_large",
  "permission_denied", "rate_limited", "cancelled", "gesture_required", "quota_exceeded", "not_found", "unavailable",
  "timeout", "operation_failed", "revoked", "internal",
] as const;
export type FlarePluginBridgeErrorCode = (typeof FLARE_PLUGIN_BRIDGE_ERROR_CODES)[number];

/** The kit string key of a bridge error code; unknown codes read as `internal`. */
export function flarePluginBridgeErrorKey(code: string): string {
  const known = (FLARE_PLUGIN_BRIDGE_ERROR_CODES as readonly string[]).includes(code) ? code : "internal";
  return `pluginBundle.error.${known.replace(/_([a-z])/g, (_, letter: string) => letter.toUpperCase())}`;
}

/** An address `ui.openExternal` may open: `https://host…`, no credentials, no spaces or control characters, ≤2048. */
export function flarePluginBundleExternalUrl(value: unknown): string | null {
  if (typeof value !== "string" || value.length > 2048 || /[\s\\\p{Cc}]/u.test(value)) return null;
  let url: URL;
  try { url = new URL(value); } catch { return null; }
  if (url.protocol !== "https:" || !url.hostname || url.username || url.password) return null;
  return url.href;
}

/**
 * The envelope a frame message carries, or null when the kit drops it: a message from anything but the frame's own
 * window (another frame, the host page, an extension), one that is not an object or a JSON object text, or one too
 * large to hand on.
 */
export function flarePluginBundleMessage(event: Pick<MessageEvent, "source" | "data">, frame: Window | null | undefined): FlarePluginBundleEnvelope | null {
  if (!frame || event.source !== frame) return null;
  let value: unknown = event.data;
  if (typeof value === "string") {
    if (value.length > FLARE_PLUGIN_BUNDLE_MAX_ENVELOPE_CHARS) return null;
    try { value = JSON.parse(value); } catch { return null; }
  } else {
    let text: string;
    try { text = JSON.stringify(value); } catch { return null; }
    if (typeof text !== "string" || text.length > FLARE_PLUGIN_BUNDLE_MAX_ENVELOPE_CHARS) return null;
  }
  if (!value || typeof value !== "object" || Array.isArray(value)) return null;
  return value as FlarePluginBundleEnvelope;
}

/** How a bridge answer is read: the envelope to post, the host request to draw, or neither. */
export function flarePluginBundleAnswer(answer: FlarePluginBundleAnswer): { envelope?: FlarePluginBundleEnvelope; host?: FlarePluginBundleHostRequest } {
  if (!answer || typeof answer !== "object") return {};
  const record = answer as Record<string, unknown>;
  const host = record.host as FlarePluginBundleHostRequest | undefined;
  if (host && typeof host === "object" && typeof host.id === "string" && typeof host.method === "string") return { host };
  const wrapped = record.envelope;
  if (wrapped && typeof wrapped === "object" && !Array.isArray(wrapped)) return { envelope: wrapped as FlarePluginBundleEnvelope };
  if (typeof record.type === "string") return { envelope: answer as FlarePluginBundleEnvelope };
  return {};
}

/** A bridge event as `{envelope?, close?}`: a bare envelope (a mock bridge's) is wrapped. */
export function flarePluginBundleEvent(event: FlarePluginBundleBridgeEvent | FlarePluginBundleEnvelope | null | undefined): FlarePluginBundleBridgeEvent {
  if (!event || typeof event !== "object") return {};
  const record = event as Record<string, unknown>;
  if (typeof record.type === "string") return { envelope: event as FlarePluginBundleEnvelope };
  const close = typeof record.close === "string" && record.close ? record.close : undefined;
  const envelope = record.envelope && typeof record.envelope === "object" ? record.envelope as FlarePluginBundleEnvelope : undefined;
  return { ...(envelope ? { envelope } : {}), ...(close ? { close } : {}) };
}

/** The response envelope for a host request, built by the kit when the bridge has no `hostResult`. */
export function flarePluginBundleHostResponse(request: FlarePluginBundleHostRequest, outcome: { result?: Record<string, unknown>; error?: FlarePluginBundleHostError }, bridge = 1): FlarePluginBundleEnvelope {
  return outcome.error
    ? { bridge, id: request.id, type: "response", error: { code: outcome.error, messageKey: flarePluginBridgeErrorKey(outcome.error).replace(/^pluginBundle\.error\./, "plugin.bridge.") } }
    : { bridge, id: request.id, type: "response", result: outcome.result ?? {} };
}

/** A toast kind of `ui.toast`, as the kit toast's variant. */
export function flarePluginBundleToastVariant(kind: unknown): "info" | "success" | "error" {
  return kind === "success" || kind === "error" ? kind : "info";
}

/** The text a host request may show: a string of at most `max` characters, trimmed; empty otherwise. */
export function flarePluginBundleText(value: unknown, max = 512): string {
  return typeof value === "string" ? value.trim().slice(0, max) : "";
}

/**
 * The host's own record of recent gestures inside the frame: focus moving into the frame (a click or tab into it), or
 * user activation (which a press inside the frame passes to its ancestors) while the host document saw no press of its
 * own. A press in the host document (the tap that opened the page, a host button) is never the page's gesture, and
 * nothing from before the frame (re)loaded counts. The page itself cannot set any of these.
 */
export function createFlarePluginBundleGesture(target: Window & typeof globalThis = window, now: () => number = () => Date.now()) {
  let inside = -Infinity;
  let hostPress = -Infinity;
  const press = () => { hostPress = now(); };
  const onBlur = () => {
    // Focus left the host window for the frame: a click or tab into it.
    if (target.document.activeElement?.tagName === "IFRAME") inside = now();
  };
  target.addEventListener("pointerdown", press, true);
  target.addEventListener("keydown", press, true);
  target.addEventListener("blur", onBlur);
  return {
    recent(): boolean {
      const at = now();
      if (at - inside <= FLARE_PLUGIN_BUNDLE_GESTURE_MS) return true;
      const activation = (target.navigator as Navigator & { userActivation?: { isActive?: boolean } }).userActivation;
      // An activation the host's own press caused is not the page's.
      return activation?.isActive === true && at - hostPress > FLARE_PLUGIN_BUNDLE_GESTURE_MS;
    },
    /** A gesture inside the frame the host learned of another way. */
    mark(): void { inside = now(); },
    /** The frame (re)loaded: nothing from before counts, the activation of the press that opened it included. */
    reset(): void { inside = -Infinity; hostPress = now(); },
    dispose(): void {
      target.removeEventListener("pointerdown", press, true);
      target.removeEventListener("keydown", press, true);
      target.removeEventListener("blur", onBlur);
    },
  };
}
