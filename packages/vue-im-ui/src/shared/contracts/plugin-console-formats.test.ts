import { describe, expect, it } from "vitest";
import {
  flarePluginFormatText,
  flarePluginMoneyText,
  flarePluginProtectedMediaSource,
  flarePluginProtectedMediaUrl,
  flarePluginReferenceParents,
  type FlarePluginFormat,
} from "./plugin-ui";

const context = {
  nowMs: Date.UTC(2026, 0, 1),
  strings: { dateTime: "M/d HH:mm", dateTimeYear: "y/M/d HH:mm" },
  unavailable: "Unavailable",
  utcOffsetMinutes: 0,
};

describe("console value formats", () => {
  it("scales a money value by the scale the host knows for its asset", () => {
    const format: FlarePluginFormat = { kind: "money", minor: "-1205", assetId: "cny" };
    expect(flarePluginFormatText("-1205", format, context)).toBe("-1205");
    expect(flarePluginFormatText("-1205", format, { ...context, assetScale: () => 2 })).toBe("-12.05");
    expect(flarePluginFormatText("12.05", { kind: "money", minor: "1205", scale: 2 }, { ...context, assetScale: () => 5 })).toBe("12.05");
  });

  it("writes small and invalid amounts the way the protocol does", () => {
    expect(flarePluginMoneyText("5", 2)).toBe("0.05");
    expect(flarePluginMoneyText("-5", 2)).toBe("-0.05");
    expect(flarePluginMoneyText("500", 0)).toBe("500");
    expect(flarePluginMoneyText("abc", 2)).toBe("abc");
  });

  it("formats a time and never shows a bare reference id", () => {
    expect(flarePluginFormatText("1767225600000", { kind: "time", atMs: Date.UTC(2026, 0, 1, 8) }, context)).toBe("1/1 08:00");
    expect(flarePluginFormatText("cny", { kind: "reference", id: "cny", labelled: false }, context)).toBe("Unavailable");
    expect(flarePluginFormatText("Yuan", { kind: "reference", id: "cny", labelled: true }, context)).toBe("Yuan");
  });

  it("falls back to the plain text for a format from a newer protocol", () => {
    const newer = { kind: "gauge", level: 3 } as unknown as FlarePluginFormat;
    expect(flarePluginFormatText("plain", newer, context)).toBe("plain");
    expect(flarePluginFormatText("plain", undefined, context)).toBe("plain");
  });
});

describe("references", () => {
  const reference = { operation: "op", valuePath: "/v", labelPath: "/l", parents: { assetId: "asset" } };

  it("waits for every parent", () => {
    expect(flarePluginReferenceParents(reference, () => "")).toBeNull();
    expect(flarePluginReferenceParents(reference, () => undefined)).toBeNull();
    expect(flarePluginReferenceParents(reference, (id) => (id === "asset" ? "cny" : ""))).toEqual({ assetId: "cny" });
    expect(flarePluginReferenceParents({ ...reference, parents: undefined }, () => "")).toEqual({});
  });
});

describe("protected media", () => {
  it("draws only what the host fetched", () => {
    expect(flarePluginProtectedMediaSource("blob:https://console/1")).toBeDefined();
    expect(flarePluginProtectedMediaSource("https://private/1")).toBeDefined();
    expect(flarePluginProtectedMediaSource("data:image/png;base64,AA")).toBeDefined();
    expect(flarePluginProtectedMediaSource("javascript:alert(1)")).toBeUndefined();
    expect(flarePluginProtectedMediaSource("data:text/html,x")).toBeUndefined();
    expect(flarePluginProtectedMediaSource("http://private/1")).toBeUndefined();
  });

  it("reads the address from the action's result", () => {
    expect(flarePluginProtectedMediaUrl({ grant: { readUrl: "https://x" } }, "/grant/readUrl")).toBe("https://x");
    expect(flarePluginProtectedMediaUrl({ grant: 1 }, "/grant/readUrl")).toBeUndefined();
  });
});
