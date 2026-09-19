import { describe, expect, it } from "vitest";
import {
  FLARE_TONES,
  isFlareTone,
  toastVariantFromTone,
  toneFromToastVariant,
} from "./tone";
import { workspaceBannerTone } from "./conversation-workspace";

describe("FlareTone", () => {
  it("is the five-value shared enum", () => {
    expect(FLARE_TONES).toEqual(["info", "success", "warning", "danger", "neutral"]);
    expect(isFlareTone("danger")).toBe(true);
    expect(isFlareTone("error")).toBe(false);
    expect(isFlareTone("default")).toBe(false);
  });

  it("maps Toast variant ↔ tone (error ↔ danger, loading → neutral)", () => {
    expect(toneFromToastVariant("error")).toBe("danger");
    expect(toneFromToastVariant("loading")).toBe("neutral");
    expect(toneFromToastVariant(undefined)).toBe("info");
    expect(toastVariantFromTone("danger")).toBe("error");
    expect(toastVariantFromTone("neutral")).toBe("info");
    for (const tone of FLARE_TONES) expect(isFlareTone(toneFromToastVariant(toastVariantFromTone(tone)))).toBe(true);
  });

  it("keeps the workspace banner inside the shared enum", () => {
    expect(workspaceBannerTone("error")).toBe("danger");
    expect(workspaceBannerTone(undefined)).toBe("info");
    for (const tone of ["info", "warning", "error", "success"] as const) expect(isFlareTone(workspaceBannerTone(tone))).toBe(true);
  });
});
