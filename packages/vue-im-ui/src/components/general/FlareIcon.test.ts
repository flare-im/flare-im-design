// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import FlareIcon from "./FlareIcon.vue";

describe("FlareIcon", () => {
  it("uses the standard toolbar size and hides an already-labelled control's glyph", () => {
    const icon = mount(FlareIcon, { props: { name: "search" } });
    expect(icon.get("i.flare-icon").attributes("aria-hidden")).toBe("true");
    expect(icon.get("i.flare-icon").attributes("style")).toContain("var(--flare-size-icon-size-md)");
    expect(icon.get("svg").attributes("data-flare-glyph")).toBe("Search");
    expect(icon.get("svg").attributes("stroke-width")).toBe("1.75");
  });

  it("supports a compact token size and an explicit accessible name", () => {
    const icon = mount(FlareIcon, { props: { name: "pin", size: "sm", ariaLabel: "Pinned" } });
    expect(icon.get("i.flare-icon").attributes("style")).toContain("var(--flare-size-icon-size-sm)");
    expect(icon.get("i.flare-icon").attributes("aria-label")).toBe("Pinned");
    expect(icon.get("i.flare-icon").attributes("aria-hidden")).toBeUndefined();
  });

  it("keeps explicit media-overlay dimensions available", () => {
    const icon = mount(FlareIcon, { props: { name: "play", size: 40 } });
    expect(icon.get("i.flare-icon").attributes("style")).toContain("40px");
  });
});
