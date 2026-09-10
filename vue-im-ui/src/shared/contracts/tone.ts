/**
 * Semantic tone shared by every status-bearing component (StatusBanner, Toast,
 * ConversationDetails, workspace banner, ...). `tone` describes meaning; a
 * component's `variant` (Button, Skeleton) only describes form.
 */
export type FlareTone = "info" | "success" | "warning" | "danger" | "neutral";

export const FLARE_TONES: readonly FlareTone[] = ["info", "success", "warning", "danger", "neutral"];

export function isFlareTone(value: unknown): value is FlareTone {
  return typeof value === "string" && (FLARE_TONES as readonly string[]).includes(value);
}

/**
 * Legacy `connectionTone` values that ConversationDetails used to pass straight
 * to naive-ui. Kept only so the deprecated prop can be mapped onto {@link FlareTone}.
 */
export type FlareLegacyConnectionTone = "success" | "warning" | "default";

/** `default` (naive-ui's unstyled tag) is `neutral` in the shared enum. */
export function toneFromLegacyConnectionTone(tone: FlareLegacyConnectionTone | undefined): FlareTone {
  switch (tone) {
    case "success":
      return "success";
    case "warning":
      return "warning";
    default:
      return "neutral";
  }
}

/** Toast keeps its `variant` (it also carries the loading spinner); this maps it onto a tone. */
export type FlareToastVariant = "info" | "success" | "error" | "warning" | "loading";

export function toneFromToastVariant(variant: FlareToastVariant | undefined): FlareTone {
  switch (variant) {
    case "success":
      return "success";
    case "warning":
      return "warning";
    case "error":
      return "danger";
    case "loading":
      return "neutral";
    default:
      return "info";
  }
}

/** Inverse of {@link toneFromToastVariant}; `neutral` has no spinner so it renders as info. */
export function toastVariantFromTone(tone: FlareTone): Exclude<FlareToastVariant, "loading"> {
  switch (tone) {
    case "success":
      return "success";
    case "warning":
      return "warning";
    case "danger":
      return "error";
    default:
      return "info";
  }
}
