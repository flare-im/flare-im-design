import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { flareMessages } from "../i18n/messages";
import type { FlareConversationKind } from "./conversation";
import type { MessageStatusState } from "./message-lifecycle";
import {
  flareMessageAccessibilityLabel,
  flareMessageReceiptPresentation,
  type FlareMessageReadSummary,
} from "./message-receipt";

const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/message-receipt-vectors.json"), "utf8")) as {
  statuses: string[];
  cases: Array<{
    id: string;
    conversationKind: FlareConversationKind;
    self: boolean;
    status: MessageStatusState;
    readSummary?: FlareMessageReadSummary;
    expect: { glyph: string | null; summary: null | { count: number | null; zh: string; en: string; allRead: boolean } };
  }>;
  accessibility: Array<{
    id: string; locale: string; sender: string; preview: string; time: string; self: boolean; status: MessageStatusState;
    conversationKind?: FlareConversationKind; readSummary?: FlareMessageReadSummary; expect: string;
  }>;
};
type Tree = { message: Record<string, string> };
const copy = (locale: "zh-CN" | "en-US") => (flareMessages[locale] as unknown as Tree).message;
const fill = (template: string, count: number | null) => template.replace("{count}", String(count ?? ""));

describe("receipt projection vectors (C3)", () => {
  it("has five states and no delivered", () => {
    expect(vectors.statuses).toEqual(["pending", "sending", "sent", "read", "failed"]);
  });
  it.each(vectors.cases)("$id", (c) => {
    const got = flareMessageReceiptPresentation(c);
    expect(got.glyph).toBe(c.expect.glyph);
    if (!c.expect.summary) {
      expect(got.summary).toBeNull();
      return;
    }
    expect(got.summary).toEqual({ allRead: c.expect.summary.allRead, count: c.expect.summary.count });
    for (const [locale, want] of [["zh-CN", c.expect.summary.zh], ["en-US", c.expect.summary.en]] as const) {
      const strings = copy(locale);
      const text = got.summary!.allRead ? strings.readSummaryAllRead : fill(strings.readSummaryUnread, got.summary!.count);
      expect(text).toBe(want);
    }
  });
});

describe("row accessible name vectors", () => {
  it.each(vectors.accessibility)("$id", (c) => {
    const strings = copy(c.locale.startsWith("zh") ? "zh-CN" : "en-US");
    let status = "";
    if (c.self) {
      const receipt = flareMessageReceiptPresentation({ conversationKind: c.conversationKind, self: true, status: c.status, readSummary: c.readSummary });
      status = receipt.summary
        ? (receipt.summary.allRead ? strings.readSummaryAllRead : fill(strings.readSummaryUnread, receipt.summary.count))
        : c.status === "failed" ? strings.sendFailedRetry : strings[c.status];
    }
    expect(flareMessageAccessibilityLabel([c.sender, c.preview, c.time, status], c.locale)).toBe(c.expect);
  });
});
