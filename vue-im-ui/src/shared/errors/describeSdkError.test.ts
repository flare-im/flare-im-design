import { describe, expect, it } from "vitest";
import { describeSdkError } from "./describeSdkError";

/**
 * 用户不该看到原始 JSON，也不该看到裸的 i18n key。
 *
 * 线上实测发一张头像字段填错的名片，弹出来的是：
 *   {"code":"sdk.error","message":"错误 [INVALID_PARAMETER] sdk.message.card.avatar.invalid_url",…}
 * 核心抛的是 i18n key，而 kit 的语言表里没有这一族，查不到就原样返回。
 */
describe("describeSdkError", () => {
  const envelope = (message: string) =>
    new Error(JSON.stringify({ code: "sdk.error", message, operation: "message.send" }));

  it("拆掉 JSON 信封并翻译成人话", () => {
    const out = describeSdkError(envelope("错误 [INVALID_PARAMETER] sdk.message.card.avatar.invalid_url"));
    expect(out).not.toContain("{");
    expect(out).not.toContain("sdk.message");
    expect(out).toContain("名片头像");
  });

  it("按字段分别给出文案", () => {
    const link = describeSdkError(envelope("错误 [INVALID_PARAMETER] sdk.message.link_card.url.invalid_url"));
    const thumb = describeSdkError(envelope("错误 [INVALID_PARAMETER] sdk.message.app_card.thumbnail_url.invalid_url"));
    expect(link).toContain("链接地址");
    expect(thumb).toContain("缩略图");
    expect(link).not.toBe(thumb);
  });

  it("未知字段不把内部路径拼进句子", () => {
    const out = describeSdkError(envelope("错误 [INVALID_PARAMETER] sdk.message.unknown_thing.some_field.invalid_url"));
    expect(out).not.toContain("sdk.message");
    expect(out).not.toContain("unknown_thing");
    expect(out).not.toContain("some_field");
    expect(out).toContain("该字段");
  });

  it("连原因都不认识时，退回兜底文案而不是裸 key", () => {
    const out = describeSdkError(
      envelope("错误 [INVALID_PARAMETER] sdk.message.foo.bar.some_unknown_reason"),
      "发送失败",
    );
    expect(out).toBe("发送失败");
  });

  it("完全无法识别时退回到给定的兜底文案", () => {
    expect(describeSdkError(new Error(""), "发送失败")).toBe("发送失败");
    expect(describeSdkError(null, "发送失败")).toBe("发送失败");
  });

  it("普通错误原样透出，不被吞掉", () => {
    expect(describeSdkError(new Error("网络连接已断开"))).toBe("网络连接已断开");
  });
});
