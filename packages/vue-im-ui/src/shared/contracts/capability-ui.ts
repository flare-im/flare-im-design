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

/** What the host answers the engine's consent request with, and whether it keeps the grant afterwards. */
export interface FlareCapabilityConsentAnswer {
  /** `{granted}`, the engine's consent result. */
  granted: boolean;
  /**
   * false: the host revokes the grant once the request is done (`revokePluginCapabilityConsent({pluginId,
   * capability})`), so the next use asks again. The engine keeps every grant it is given.
   */
  remember: boolean;
}

export function flareCapabilityConsentAnswer(decision: FlareCapabilityConsentDecision): FlareCapabilityConsentAnswer {
  switch (decision) {
    case "always":
      return { granted: true, remember: true };
    case "once":
      return { granted: true, remember: false };
    default:
      return { granted: false, remember: false };
  }
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

/** Whether bytes are a JPEG with an APP1 Exif segment before the scan (the engine's jpeg_has_exif). */
export function flareJpegHasExif(bytes: Uint8Array): boolean {
  if (bytes.length < 4 || bytes[0] !== 0xff || bytes[1] !== 0xd8) return false;
  let at = 2;
  while (at + 4 <= bytes.length) {
    if (bytes[at] !== 0xff) return false;
    const marker = bytes[at + 1];
    if (marker === 0xda || marker === 0xd9) return false;
    const length = (bytes[at + 2] << 8) | bytes[at + 3];
    if (length < 2) return false;
    if (marker === 0xe1 && at + 10 <= bytes.length) {
      const exif = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00];
      if (exif.every((b, i) => bytes[at + 4 + i] === b)) return true;
    }
    at += 2 + length;
  }
  return false;
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
      const bytes = new Uint8Array(await blob.arrayBuffer());
      // A canvas never writes EXIF; refuse rather than hand on a file the engine would refuse anyway.
      if (flareJpegHasExif(bytes)) throw "failed" satisfies FlareDocumentProcessError;
      return { fileName: flareDocumentFileName(side), contentType: "image/jpeg", bytes };
    }
    throw "tooLarge" satisfies FlareDocumentProcessError;
  } finally {
    bitmap.close();
  }
}
