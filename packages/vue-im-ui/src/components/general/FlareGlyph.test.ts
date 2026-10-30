// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { afterEach, describe, expect, it, vi } from "vitest";
import FlareGlyph from "./FlareGlyph.vue";
import FlareIcon from "./FlareIcon.vue";

afterEach(() => vi.restoreAllMocks());

describe("FlareGlyph", () => {
  it("draws a registry name as its glyph", () => {
    expect(mount(FlareGlyph, { props: { icon: "wallet" } }).findComponent(FlareIcon).props("name")).toBe("wallet");
  });

  it("draws the plugin glyph for a name the registry does not have — never the word, never a blank", () => {
    vi.spyOn(console, "warn").mockImplementation(() => {});
    const glyph = mount(FlareGlyph, { props: { icon: "coins-stack" } });
    expect(glyph.findComponent(FlareIcon).props("name")).toBe("plugin");
    expect(glyph.text()).not.toContain("coins-stack");
  });

  it("still draws an emoji as given, hidden from assistive technology", () => {
    const glyph = mount(FlareGlyph, { props: { icon: "🧧" } });
    expect(glyph.findComponent(FlareIcon).exists()).toBe(false);
    expect(glyph.get("span").attributes("aria-hidden")).toBe("true");
    expect(glyph.text()).toBe("🧧");
  });

  it("draws nothing for no icon", () => {
    expect(mount(FlareGlyph, { props: { icon: "  " } }).html()).not.toContain("<svg");
  });
});
