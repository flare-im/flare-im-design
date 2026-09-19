import { describe, expect, it } from "vitest";
import { flareErrorText } from "./errors";

// FR-067: one answer to "what do I show the person for this caught value", instead of
// `e instanceof Error ? e.message : String(e)` at every catch.

describe("flareErrorText", () => {
  it("reads an Error, a string and a thrown value with a message", () => {
    expect(flareErrorText(new Error("网络连接已断开"))).toBe("网络连接已断开");
    expect(flareErrorText("  发送失败  ")).toBe("发送失败");
    expect(flareErrorText({ message: "会话不存在" })).toBe("会话不存在");
    expect(flareErrorText(new TypeError("bad"))).toBe("bad");
  });

  it("falls back where there is nothing to read, instead of printing the value", () => {
    expect(flareErrorText(undefined, "操作失败，请重试")).toBe("操作失败，请重试");
    expect(flareErrorText(null, "操作失败，请重试")).toBe("操作失败，请重试");
    expect(flareErrorText(new Error("   "), "操作失败，请重试")).toBe("操作失败，请重试");
    expect(flareErrorText({ code: 500 }, "操作失败，请重试")).toBe("操作失败，请重试");
    expect(flareErrorText({}, "操作失败，请重试")).toBe("操作失败，请重试");
  });

  it("keeps a value that does read as something", () => {
    expect(flareErrorText(42)).toBe("42");
    expect(flareErrorText(undefined)).toBe("");
  });
});
