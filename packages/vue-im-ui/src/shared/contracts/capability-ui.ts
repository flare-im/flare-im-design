/**
 * Plugin host capability components — pure rules shared by FlareCapabilityConsent, FlareDocumentCapture and
 * FlarePaymentConfirmation (spec/capability-ui-vectors.json; docs/design/plugin-client-hot-delivery.md 7).
 *
 * The kit draws what the engine asks the host (`plugin.capability_request`: consent, captureDocument,
 * confirmPayment). It never runs a request itself: the host listens, shows the component, and answers the engine
 * with what the component hands back. Capabilities are named by what they do; no plugin id appears here.
 */

/** The viewer's answer to a consent prompt. */
export type FlareCapabilityConsentDecision = "once" | "always" | "deny";

/**
 * What the host answers the engine's consent request with (`plugin.capability_complete` result): the decision
 * itself. The engine keeps only "always"; "once" lets this request through and keeps nothing, so the host never
 * revokes anything to emulate it.
 */
export interface FlareCapabilityConsentAnswer {
  decision: FlareCapabilityConsentDecision;
}

export function flareCapabilityConsentAnswer(decision: FlareCapabilityConsentDecision): FlareCapabilityConsentAnswer {
  return { decision: decision === "always" || decision === "once" ? decision : "deny" };
}

/** The copy key (`capability.label.*`) naming what a plugin asks to use; an unknown capability is the generic line. */
export type FlareCapabilityLabelKey =
  | "documentCapture"
  | "paymentConfirmation"
  | "locationCoarse"
  | "locationFine"
  | "camera"
  | "microphone"
  | "rtcSession"
  | "generic";

export function flareCapabilityLabelKey(capability: string, params?: Readonly<Record<string, unknown>> | null): FlareCapabilityLabelKey {
  switch (capability) {
    case "documentCapture":
      return "documentCapture";
    case "paymentConfirmation":
      return "paymentConfirmation";
    case "locationOnce":
      return params?.precision === "fine" ? "locationFine" : "locationCoarse";
    case "camera":
      return "camera";
    case "microphone":
      return "microphone";
    case "rtcSession":
      return "rtcSession";
    default:
      return "generic";
  }
}

/** Whether the consent offers "Always allow": a one-time location is confirmed every time. */
export function flareCapabilityConsentAllowsAlways(capability: string): boolean {
  return capability !== "locationOnce";
}

// ── payment confirmation ───────────────────────────────────────────────────

/** The order the engine hands the host (`confirmPayment.order`, flare-plugin-protocol PaymentConfirmationOrder). */
export interface FlarePaymentOrder {
  orderId: string;
  /** Decimal string, up to 18 fraction digits. */
  amount: string;
  /** ISO 4217 code. */
  currency: string;
  payee: string;
  title: string;
  /** Server clock. */
  expiresAtMs: number;
  /** The plugin's transient operation the engine runs after the viewer confirms; the kit never reads it. */
  operation?: string;
}

const CURRENCY_PREFIX: Readonly<Record<string, string>> = {
  CNY: "¥",
  USD: "$",
  EUR: "€",
  GBP: "£",
  JPY: "JP¥",
  HKD: "HK$",
};
const PLAIN_DECIMAL = /^(\d+)(?:\.(\d{1,18}))?$/;

/**
 * The amount as the confirmation draws it: the currency's symbol (or the code after the number), the integer part
 * grouped by three, the fraction exactly as written. Never a float. null: not a plain non-negative decimal.
 */
export function flarePaymentAmountText(amount: string, currency: string): string | null {
  const match = PLAIN_DECIMAL.exec(amount);
  if (!match) return null;
  const whole = match[1].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  const number = match[2] === undefined ? whole : `${whole}.${match[2]}`;
  const code = currency.trim().toUpperCase();
  const prefix = CURRENCY_PREFIX[code];
  if (prefix) return `${prefix}${number}`;
  return code ? `${number} ${code}` : number;
}

/** What is left of an order: whole seconds rounded up, mm:ss under an hour, h:mm:ss from an hour on. */
export function flarePaymentCountdown(remainingMs: number): { text: string; expired: boolean } {
  if (!Number.isFinite(remainingMs) || remainingMs <= 0) return { text: "00:00", expired: true };
  const total = Math.ceil(remainingMs / 1000);
  const hours = Math.floor(total / 3600);
  const minutes = Math.floor((total % 3600) / 60);
  const seconds = total % 60;
  const two = (n: number) => String(n).padStart(2, "0");
  return { text: hours > 0 ? `${hours}:${two(minutes)}:${two(seconds)}` : `${two(minutes)}:${two(seconds)}`, expired: false };
}

// ── document capture ───────────────────────────────────────────────────────

export type FlareDocumentSide = "front" | "back" | "holding";

/** The viewfinder frame's width over height: an ID-1 card for front and back, 3:4 portrait for holding. */
export function flareDocumentFrameAspect(side: FlareDocumentSide): number {
  return side === "holding" ? 0.75 : 1.585;
}

/** The (longest edge, JPEG quality) steps the kit tries until the photo fits; none fits: too large. */
export const FLARE_DOCUMENT_COMPRESSION_PLAN: ReadonlyArray<readonly [number, number]> = [
  [2048, 0.86],
  [2048, 0.72],
  [2048, 0.58],
  [1600, 0.72],
  [1600, 0.58],
  [1280, 0.58],
  [1024, 0.5],
];

export function flareDocumentFileName(side: FlareDocumentSide): string {
  return `document-${side}.jpg`;
}

/** Whether an accept list takes the kit's JPEG (an empty list takes anything). */
export function flareDocumentAcceptsJpeg(accept: ReadonlyArray<string> | null | undefined): boolean {
  if (!accept || accept.length === 0) return true;
  return accept.some((type) => {
    const t = type.trim().toLowerCase();
    return t === "image/jpeg" || t === "image/*" || t === "*/*";
  });
}

/** One JPEG segment before the scan: `[start, end)` of its bytes from its 0xFF, its marker, and whether it may stay. */
interface FlareJpegSegment {
  start: number;
  end: number;
  marker: number;
  allowed: boolean;
}

function startsWithAscii(bytes: Uint8Array, at: number, text: string): boolean {
  if (at + text.length > bytes.length) return false;
  for (let i = 0; i < text.length; i++) if (bytes[at + i] !== text.charCodeAt(i)) return false;
  return true;
}

/** The segments before the scan, with the scan's offset; null when the bytes are not a well-formed JPEG header. */
function flareJpegSegments(bytes: Uint8Array): { segments: FlareJpegSegment[]; scan: number } | null {
  if (bytes.length < 4 || bytes[0] !== 0xff || bytes[1] !== 0xd8) return null;
  const segments: FlareJpegSegment[] = [];
  let at = 2;
  for (;;) {
    if (bytes[at] !== 0xff) return null;
    // 0xFF fill bytes may come before a marker.
    while (bytes[at + 1] === 0xff) at++;
    const marker = bytes[at + 1];
    if (marker === undefined) return null;
    if (marker === 0xda) return { segments, scan: at };
    if (at + 4 > bytes.length) return null;
    const length = (bytes[at + 2] << 8) | bytes[at + 3];
    if (length < 2 || at + 2 + length > bytes.length) return null;
    const body = at + 4;
    let allowed: boolean;
    if (marker === 0xe0) allowed = startsWithAscii(bytes, body, "JFIF\0");
    else if (marker === 0xe2) allowed = startsWithAscii(bytes, body, "ICC_PROFILE\0");
    else if (marker === 0xee) allowed = startsWithAscii(bytes, body, "Adobe");
    else allowed = marker === 0xdb || marker === 0xc4 || marker === 0xcc || marker === 0xdd
      || (marker >= 0xc0 && marker <= 0xcf && marker !== 0xc8);
    segments.push({ start: at, end: at + 2 + length, marker, allowed });
    at += 2 + length;
  }
}

/**
 * Whether bytes are a JPEG with nothing but image data before its scan: an APP0 JFIF header, an APP2 ICC profile,
 * the APP14 Adobe segment, tables and the frame header (0xFF fill allowed). Exif or XMP, MPF, IPTC, comments and any
 * other segment, a truncated header or no scan fail. The engine's own rule (jpeg_is_stripped).
 */
export function flareJpegIsStripped(bytes: Uint8Array): boolean {
  const parsed = flareJpegSegments(bytes);
  return parsed !== null && parsed.segments.every((segment) => segment.allowed);
}

/**
 * The JPEG with only the segments {@link flareJpegIsStripped} allows before its scan (and no fill bytes); the scan and
 * what follows stay as they are. Bytes that are not a well-formed JPEG header come back unchanged.
 */
export function flareJpegStrippingMetadata(bytes: Uint8Array): Uint8Array {
  const parsed = flareJpegSegments(bytes);
  if (!parsed) return bytes;
  const kept = parsed.segments.filter((segment) => segment.allowed);
  const size = 2 + kept.reduce((sum, segment) => sum + segment.end - segment.start, 0) + bytes.length - parsed.scan;
  const out = new Uint8Array(size);
  out[0] = 0xff;
  out[1] = 0xd8;
  let at = 2;
  for (const segment of kept) {
    out.set(bytes.subarray(segment.start, segment.end), at);
    at += segment.end - segment.start;
  }
  out.set(bytes.subarray(parsed.scan), at);
  return out;
}

/** The photo the capture hands the host: `captureDocument`'s `{file}` once the host turns bytes into a number list. */
export interface FlareCapturedDocument {
  fileName: string;
  contentType: "image/jpeg";
  bytes: Uint8Array;
}

export type FlareDocumentProcessError = "tooLarge" | "failed" | "notAccepted";

/**
 * Re-encodes a photo to a JPEG that fits `maxBytes`: the orientation is applied to the pixels, then the picture is
 * drawn on a canvas and encoded, so nothing of the original file (EXIF, GPS, maker notes, thumbnails) survives.
 * Browser only (createImageBitmap and a canvas). Rejects with a {@link FlareDocumentProcessError}.
 */
export async function flareProcessDocumentPhoto(
  photo: Blob,
  side: FlareDocumentSide,
  options: { maxBytes: number; accept?: ReadonlyArray<string> },
): Promise<FlareCapturedDocument> {
  if (!flareDocumentAcceptsJpeg(options.accept)) throw "notAccepted" satisfies FlareDocumentProcessError;
  let bitmap: ImageBitmap;
  try {
    bitmap = await createImageBitmap(photo, { imageOrientation: "from-image" });
  } catch {
    throw "failed" satisfies FlareDocumentProcessError;
  }
  try {
    for (const [edge, quality] of FLARE_DOCUMENT_COMPRESSION_PLAN) {
      const scale = Math.min(1, edge / Math.max(bitmap.width, bitmap.height));
      const width = Math.max(1, Math.round(bitmap.width * scale));
      const height = Math.max(1, Math.round(bitmap.height * scale));
      const canvas = document.createElement("canvas");
      canvas.width = width;
      canvas.height = height;
      const context = canvas.getContext("2d");
      if (!context) throw "failed" satisfies FlareDocumentProcessError;
      context.drawImage(bitmap, 0, 0, width, height);
      const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, "image/jpeg", quality));
      if (!blob) throw "failed" satisfies FlareDocumentProcessError;
      if (blob.size > options.maxBytes) continue;
      // A canvas draws only pixels, but a browser's encoder may add segments of its own (Apple's ImageIO writes Exif):
      // keep only image data, and refuse rather than hand on a file the engine would refuse anyway.
      const bytes = flareJpegStrippingMetadata(new Uint8Array(await blob.arrayBuffer()));
      if (!flareJpegIsStripped(bytes)) throw "failed" satisfies FlareDocumentProcessError;
      return { fileName: flareDocumentFileName(side), contentType: "image/jpeg", bytes };
    }
    throw "tooLarge" satisfies FlareDocumentProcessError;
  } finally {
    bitmap.close();
  }
}
