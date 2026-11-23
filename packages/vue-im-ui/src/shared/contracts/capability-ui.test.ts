import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { flareMessages } from "../i18n/messages";
import {
  flareSpokenAmount,
  FLARE_DOCUMENT_COMPRESSION_PLAN,
  flareCapabilityConsentAllowsAlways,
  flareCapabilityConsentAnswer,
  flareCapabilityLabelKey,
  flareDocumentAcceptsJpeg,
  flareDocumentFileName,
  flareDocumentFrameAspect,
  flareJpegIsStripped,
  flareJpegStrippingMetadata,
  flarePaymentAmountText,
  flarePaymentCountdown,
  type FlareCapabilityConsentDecision,
  type FlareDocumentSide,
} from "./capability-ui";
import { flarePluginLocationText, flarePluginLocationValue, flarePluginProtectedMediaSource, type FlarePluginLocationPrecision } from "./plugin-ui";
import { PLUGIN_UI_VOCABULARY } from "./plugin-ui-vocabulary";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const vectors: any = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/capability-ui-vectors.json"), "utf8"));
const hex = (text: string) => Uint8Array.from((text.match(/../g) ?? []).map((pair) => parseInt(pair, 16)));
const LABEL_KEYS: Record<string, string> = {
  capabilityDocumentCapture: "documentCapture",
  capabilityPaymentConfirmation: "paymentConfirmation",
  capabilityLocationCoarse: "locationCoarse",
  capabilityLocationFine: "locationFine",
  capabilityCamera: "camera",
  capabilityMicrophone: "microphone",
  capabilityRtcSession: "rtcSession",
  capabilityGeneric: "generic",
};

describe("capability components (spec/capability-ui-vectors.json)", () => {
  it("turns the consent decision into the engine's answer", () => {
    for (const c of vectors.consentDecision.cases)
      expect(flareCapabilityConsentAnswer(c.decision as FlareCapabilityConsentDecision)).toEqual(c.answer);
  });
  it("names what the plugin asks for, in both languages", () => {
    for (const c of vectors.capabilityLabel.cases) {
      const key = flareCapabilityLabelKey(c.capability, c.params);
      expect(key).toBe(LABEL_KEYS[c.key]);
      for (const locale of ["zh-CN", "en-US"]) {
        const label = (flareMessages[locale] as never as { capability: { label: Record<string, string> } }).capability.label[key];
        expect(typeof label).toBe("string");
        expect(label).not.toBe(c.capability);
      }
    }
  });
  it("offers always only where it may", () => {
    for (const c of vectors.consentAllowsAlways.cases) expect(flareCapabilityConsentAllowsAlways(c.capability)).toBe(c.always);
  });
  it("draws the order amount exactly", () => {
    for (const c of vectors.paymentAmount.cases) expect(flarePaymentAmountText(c.amount, c.currency)).toBe(c.text);
  });
  it("counts the order down", () => {
    for (const c of vectors.paymentCountdown.cases) expect(flarePaymentCountdown(c.remainingMs)).toEqual({ text: c.text, expired: c.expired });
  });
  it("frames each side", () => {
    for (const c of vectors.documentFrame.cases) expect(flareDocumentFrameAspect(c.side as FlareDocumentSide)).toBeCloseTo(c.aspect, 3);
  });
  it("compresses in the shared order and names the file by side", () => {
    expect(FLARE_DOCUMENT_COMPRESSION_PLAN.map((step) => [...step])).toEqual(vectors.documentCompression.plan);
    for (const c of vectors.documentCompression.fileName) expect(flareDocumentFileName(c.side)).toBe(c.name);
  });
  it("checks the accept list", () => {
    for (const c of vectors.documentAccept.cases) expect(flareDocumentAcceptsJpeg(c.accept)).toBe(c.ok);
  });
  it("takes a JPEG as stripped by the engine's rule", () => {
    for (const c of vectors.jpegStripped.cases) expect(flareJpegIsStripped(hex(c.hex)), c.note).toBe(c.stripped);
  });
  it("strips what an encoder adds and keeps the image data", () => {
    for (const c of vectors.jpegStripped.strip) {
      expect(Array.from(flareJpegStrippingMetadata(hex(c.hex))), c.note).toEqual(Array.from(hex(c.out)));
    }
    // A stripped JPEG stays as it is.
    for (const c of vectors.jpegStripped.cases.filter((c: { hex: string; stripped: boolean }) => c.stripped)) {
      expect(flareJpegIsStripped(flareJpegStrippingMetadata(hex(c.hex)))).toBe(true);
    }
  });
  it("draws only the protected media addresses the web may", () => {
    for (const c of vectors.protectedMediaSource.cases) expect(Boolean(flarePluginProtectedMediaSource(c.url))).toBe(c.web);
  });
  it("takes a location of the input's precision only", () => {
    for (const c of vectors.locationInput.cases) {
      const fix = flarePluginLocationValue(c.value, c.precision as FlarePluginLocationPrecision);
      expect(Boolean(fix)).toBe(c.ok);
      if (fix) expect(flarePluginLocationText(fix)).toBe(c.text);
    }
  });
  it("reports the capabilities the kit now serves", () => {
    for (const name of ["documentCapture", "paymentConfirmation", "locationOnce"]) expect(PLUGIN_UI_VOCABULARY.native).toContain(name);
    expect(PLUGIN_UI_VOCABULARY.renderers).toEqual(expect.arrayContaining(["redPacket.card", "redPacket.compose", "redPacket.detail", "redPacket.review"]));
    expect(PLUGIN_UI_VOCABULARY.inputs).toContain("location");
    expect(PLUGIN_UI_VOCABULARY.blocks).toContain("protected-media");
  });
});

describe("flareSpokenAmount (R11)", () => {
  const name = (locale: string, code: string) => new Intl.DisplayNames([locale], { type: "currency" }).of(code);
  it("reads the currency's platform name after the number, from the symbol, a trailing code or the caller's code", () => {
    expect(flareSpokenAmount("¥1,000.00", "zh-CN")).toBe(`1,000.00 ${name("zh-CN", "CNY")}`);
    expect(flareSpokenAmount("−$5.00", "en-US")).toBe(`−5.00 ${name("en-US", "USD")}`);
    expect(flareSpokenAmount("JP¥300", "en-US")).toBe(`300 ${name("en-US", "JPY")}`);
    expect(flareSpokenAmount("100.00 XYZ", "en-US")).toBe(`100.00 ${name("en-US", "XYZ") ?? "XYZ"}`);
    expect(flareSpokenAmount("26.64", "zh-CN", "cny")).toBe(`26.64 ${name("zh-CN", "CNY")}`);
    expect(name("zh-CN", "CNY")).not.toBe("CNY");
  });
  it("falls back to the code on a bad locale and leaves an amount with no currency as it is", () => {
    expect(flareSpokenAmount("¥8.00", "not a locale!")).toBe("8.00 CNY");
    expect(flareSpokenAmount("1,000.00", "zh-CN")).toBe("1,000.00");
  });
});
