import { describe, expect, it } from "vitest";
import { mergeMessageMenuConfig, unhandledMessageMenuActions } from "./messageMenu";

describe("unhandledMessageMenuActions", () => {
  it("switches off every action whose intent has no listener", () => {
    const masked = unhandledMessageMenuActions({ onReply: () => {}, onDelete: () => {} });
    expect(masked.reply).toBeUndefined();
    expect(masked.delete).toBeUndefined();
    expect(masked).toMatchObject({ react: false, forward: false, pin: false, pinSelf: false, unpin: false, preview: false, downloadMedia: false, resend: false });
  });

  it("keeps copy, which the kit handles itself", () => {
    expect(unhandledMessageMenuActions({}).copy).toBeUndefined();
  });

  it("wins over a host config that turns an unhandled action on", () => {
    const merged = mergeMessageMenuConfig({ actions: { forward: true } }, { actions: unhandledMessageMenuActions({}) });
    expect(merged.actions?.forward).toBe(false);
  });
});
