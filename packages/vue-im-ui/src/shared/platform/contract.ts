// Layer 5 — Platform Contract (shared truth: spec/platform-contract.json).
// One capability record, one adapter interface and one error model. The host
// declares what it can do and performs the native work; components read
// capabilities through useFlarePlatform() and never branch on platform identity.

export type FlarePlatformKind = "web" | "tauri" | "ios" | "android" | "flutter";
export type FlareCapabilitySupport = "supported" | "fallback" | "unsupported";
export type FlarePointerKind = "fine" | "coarse" | "mixed" | "unknown";

export interface FlarePlatformCapabilities {
  pointer: FlarePointerKind;
  hover: boolean;
  contextMenu: boolean;
  keyboardShortcut: boolean;
  /** Contextual layers present as bottom sheets (phone form factor). */
  bottomSheet: boolean;
  nativeBack: boolean;
  safeArea: boolean;
  filePicker: FlareCapabilitySupport;
  imagePicker: FlareCapabilitySupport;
  share: FlareCapabilitySupport;
}

export const FLARE_PLATFORM_ERROR_CODES = ["UNSUPPORTED", "CANCELLED", "PERMISSION_DENIED", "TIMEOUT", "FAILED"] as const;
export type FlarePlatformErrorCode = (typeof FLARE_PLATFORM_ERROR_CODES)[number];

export interface FlarePlatformError {
  code: FlarePlatformErrorCode;
  message?: string;
  cause?: unknown;
}

export type FlarePlatformResult<T> =
  | { ok: true; value: T }
  | { ok: false; error: FlarePlatformError };

export interface FlarePickedFile {
  name: string;
  size?: number;
  mimeType?: string;
  /** Native / Tauri filesystem path when the platform exposes one. */
  path?: string;
  /** Android content uri / web object URL when the platform exposes one. */
  uri?: string;
  /** The DOM File on web; hosts upload from it. */
  file?: File;
}

export interface FlarePickFilesOptions {
  multiple?: boolean;
  /** MIME types or extensions, e.g. ["image/*", ".pdf"]. */
  accept?: string[];
}
export interface FlarePickImagesOptions {
  multiple?: boolean;
  /** Also allow videos. */
  video?: boolean;
}
export interface FlareSharePayload {
  title?: string;
  text?: string;
  url?: string;
  files?: FlarePickedFile[];
}
export interface FlareSafeAreaInsets {
  top: number;
  right: number;
  bottom: number;
  left: number;
}

/**
 * Host-implemented native operations. Every method is optional: an absent
 * method is reported as `unsupported` in the capabilities and answers
 * UNSUPPORTED when called through `callPlatform`.
 */
export interface FlarePlatformAdapter {
  pickFiles?(options?: FlarePickFilesOptions): Promise<FlarePlatformResult<FlarePickedFile[]>>;
  pickImages?(options?: FlarePickImagesOptions): Promise<FlarePlatformResult<FlarePickedFile[]>>;
  share?(payload: FlareSharePayload): Promise<FlarePlatformResult<void>>;
  /** Returns the unsubscribe; the handler returns true when it consumed the back action. */
  onNativeBack?(handler: () => boolean): () => void;
  safeAreaInsets?(): FlareSafeAreaInsets;
}

export function platformOk<T>(value: T): FlarePlatformResult<T> {
  return { ok: true, value };
}

export function platformError(code: FlarePlatformErrorCode, message?: string, cause?: unknown): FlarePlatformError {
  return cause === undefined ? { code, message } : { code, message, cause };
}

export function platformErr<T = never>(code: FlarePlatformErrorCode, message?: string, cause?: unknown): FlarePlatformResult<T> {
  return { ok: false, error: platformError(code, message, cause) };
}

export function isPlatformError(value: unknown): value is FlarePlatformError {
  return Boolean(value) && typeof value === "object" &&
    (FLARE_PLATFORM_ERROR_CODES as readonly string[]).includes(String((value as { code?: unknown }).code));
}

/**
 * Map a thrown value to the contract's error model. Web: DOMException names
 * (AbortError → CANCELLED, NotAllowedError / SecurityError → PERMISSION_DENIED,
 * TimeoutError → TIMEOUT, NotSupportedError → UNSUPPORTED); host errors may carry
 * a `code` from the model directly; anything else is FAILED.
 */
export function normalizePlatformError(value: unknown): FlarePlatformError {
  if (isPlatformError(value)) return value;
  const record = (value && typeof value === "object" ? value : {}) as { name?: unknown; code?: unknown; message?: unknown };
  const name = String(record.name ?? "");
  const code = String(record.code ?? "");
  const message = typeof record.message === "string" ? record.message : value instanceof Error ? value.message : String(value ?? "");
  const text = `${name} ${code} ${message}`;
  if (name === "AbortError" || code === "CANCELLED" || /\bcancel(?:l)?ed\b|\babort/i.test(text)) return platformError("CANCELLED", message, value);
  if (name === "NotAllowedError" || name === "SecurityError" || code === "PERMISSION_DENIED" || /permission|denied|not allowed/i.test(text)) {
    return platformError("PERMISSION_DENIED", message, value);
  }
  if (name === "TimeoutError" || code === "TIMEOUT" || /time(?:d)? ?out/i.test(text)) return platformError("TIMEOUT", message, value);
  if (name === "NotSupportedError" || code === "UNSUPPORTED" || /not supported|unsupported|not implemented/i.test(text)) {
    return platformError("UNSUPPORTED", message, value);
  }
  return platformError("FAILED", message, value);
}

/** Resolve to TIMEOUT when the native surface does not answer within `ms`. */
export function withPlatformTimeout<T>(operation: Promise<FlarePlatformResult<T>>, ms: number): Promise<FlarePlatformResult<T>> {
  return new Promise((resolve) => {
    const timer = setTimeout(() => resolve(platformErr("TIMEOUT", `platform operation exceeded ${ms}ms`)), ms);
    operation.then(
      (result) => { clearTimeout(timer); resolve(result); },
      (error) => { clearTimeout(timer); resolve({ ok: false, error: normalizePlatformError(error) }); },
    );
  });
}

type AdapterOperation = "pickFiles" | "pickImages" | "share";
type OperationResult<K extends AdapterOperation> = K extends "share" ? void : FlarePickedFile[];

/**
 * Call an adapter operation through the contract: an absent method answers
 * UNSUPPORTED, a thrown value is normalized, and an optional timeout applies.
 */
export async function callPlatform<K extends AdapterOperation>(
  adapter: FlarePlatformAdapter | null | undefined,
  operation: K,
  input: K extends "pickFiles" ? FlarePickFilesOptions | undefined : K extends "pickImages" ? FlarePickImagesOptions | undefined : FlareSharePayload,
  timeoutMs?: number,
): Promise<FlarePlatformResult<OperationResult<K>>> {
  const method = adapter?.[operation] as ((arg: unknown) => Promise<FlarePlatformResult<OperationResult<K>>>) | undefined;
  if (typeof method !== "function") return platformErr("UNSUPPORTED", `${operation} is not provided by this host`);
  let pending: Promise<FlarePlatformResult<OperationResult<K>>>;
  try {
    pending = Promise.resolve(method.call(adapter, input));
  } catch (error) {
    return { ok: false, error: normalizePlatformError(error) };
  }
  const guarded = pending.catch((error: unknown) => ({ ok: false as const, error: normalizePlatformError(error) }));
  return timeoutMs && timeoutMs > 0 ? withPlatformTimeout(guarded, timeoutMs) : guarded;
}

/** Support level of the picker / share operations derived from what the adapter implements. */
export function adapterSupport(adapter: FlarePlatformAdapter | null | undefined, operation: AdapterOperation, fallback: FlareCapabilitySupport = "unsupported"): FlareCapabilitySupport {
  return typeof adapter?.[operation] === "function" ? "supported" : fallback;
}

export const FLARE_DEFAULT_PLATFORM_CAPABILITIES: FlarePlatformCapabilities = {
  pointer: "unknown",
  hover: false,
  contextMenu: false,
  keyboardShortcut: false,
  bottomSheet: false,
  nativeBack: false,
  safeArea: false,
  filePicker: "unsupported",
  imagePicker: "unsupported",
  share: "unsupported",
};
