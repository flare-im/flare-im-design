import { describe, expect, it } from "vitest";
import { resolveContextualLayerEscape, type FlareContextualLayerEscapeInput } from "./contextual-layer";

/**
 * 裁决表逐行验证。每一行是一个真实的处境,列的顺序就是优先级:前面的事实一旦成立,后面的
 * 都不再看 —— 所以每行只翻一个事实,其余全取「本该退出」的默认值,红了就知道是哪一条在错。
 */
const exits: FlareContextualLayerEscapeInput = { key: "Escape", topmost: true, visible: true };

describe("resolveContextualLayerEscape", () => {
  it("exits on a plain Escape reaching the topmost visible layer", () => {
    expect(resolveContextualLayerEscape(exits)).toBe("exit");
  });

  it.each<[string, Partial<FlareContextualLayerEscapeInput>]>([
    ["any other key", { key: "Enter" }],
    ["an IME composition in progress", { composing: true }],
    ["a layer underneath already used the key", { defaultPrevented: true }],
    ["a modal surface or aria-modal dialog on top", { modalOpen: true }],
    ["focus inside an editable control", { editableTarget: true }],
    ["focus on a page that does not contain this layer", { foreignSurface: true }],
    ["a layer that is not the topmost one", { topmost: false }],
    ["a layer hidden by v-show", { visible: false }],
  ])("ignores %s", (_label, fact) => {
    expect(resolveContextualLayerEscape({ ...exits, ...fact })).toBe("ignore");
  });

  it("swallows the key while busy instead of exiting or passing it on", () => {
    expect(resolveContextualLayerEscape({ ...exits, busy: true })).toBe("swallow");
  });

  it("lets an earlier fact win over busy (a busy layer under a modal is not asked)", () => {
    expect(resolveContextualLayerEscape({ ...exits, busy: true, modalOpen: true })).toBe("ignore");
    expect(resolveContextualLayerEscape({ ...exits, busy: true, editableTarget: true })).toBe("ignore");
  });
});
