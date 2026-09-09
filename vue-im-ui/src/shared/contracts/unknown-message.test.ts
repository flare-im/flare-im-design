import { describe, expect, it } from "vitest";
import { unknownMessagePresentation } from "./unknown-message";

const base = { hint: "当前版本无法显示这条消息", unsupportedText: "不支持的消息类型" };

describe("unknownMessagePresentation", () => {
  it("prefers the sender's fallback summary as the body", () => {
    const p = unknownMessagePresentation({ ...base, summary: "[投票] 周会时间", contentType: "flare.poll.v2" });
    expect(p.body).toBe("[投票] 周会时间");
    expect(p.hasSummary).toBe(true);
  });

  it("falls back to the generic hint when the summary is blank", () => {
    const p = unknownMessagePresentation({ ...base, summary: "   ", contentType: "flare.poll.v2" });
    expect(p.body).toBe("当前版本无法显示这条消息");
    expect(p.hasSummary).toBe(false);
  });

  it("uses the host label as the title when it knows the type", () => {
    expect(unknownMessagePresentation({ ...base, label: "投票" }).title).toBe("投票");
  });

  it("uses the generic unsupported wording when there is no label", () => {
    expect(unknownMessagePresentation({ ...base, label: "  " }).title).toBe("不支持的消息类型");
  });

  it("keeps the raw content type as a diagnostic, never as the body", () => {
    const p = unknownMessagePresentation({ ...base, contentType: "flare.poll.v2" });
    expect(p.diagnostic).toBe("flare.poll.v2");
    expect(p.body).toBe("当前版本无法显示这条消息");
  });

  it("reports no diagnostic when the content type is missing or blank", () => {
    expect(unknownMessagePresentation({ ...base }).diagnostic).toBe("");
    expect(unknownMessagePresentation({ ...base, contentType: "  " }).diagnostic).toBe("");
  });

  it("trims every input so stray whitespace cannot fake a value", () => {
    const p = unknownMessagePresentation({ ...base, label: " 投票 ", summary: " hi ", contentType: " x.y " });
    expect([p.title, p.body, p.diagnostic]).toEqual(["投票", "hi", "x.y"]);
  });
});
