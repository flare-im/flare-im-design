// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import { h, type FunctionalComponent } from "vue";
import FlareIcon from "../components/general/FlareIcon.vue";
import { CheckmarkCircle, SettingsOutline } from "./icon-glyphs";
import { flareIconNames, flareIcons } from "./icons";

// FR-136: a screenshot compared with an anti-aliasing tolerance cannot see one 18 px glyph swapped for another, so the
// drawn SVG says which glyph it is and an application test can record the names on a page beside its screenshot.

const glyphOf = (component: unknown) => (component as FunctionalComponent & { displayName: string }).displayName;

describe("the icon shim names the glyph it draws", () => {
  it("puts the Lucide name on the SVG, filled or not", () => {
    expect(mount(() => h(SettingsOutline)).get("svg").attributes("data-flare-glyph")).toBe("Settings");
    const filled = mount(() => h(CheckmarkCircle)).get("svg");
    expect(filled.attributes("data-flare-glyph")).toBe("CircleCheck");
    expect(filled.attributes("fill")).toBe("currentColor");
  });

  it("every semantic icon, drawn through FlareIcon, names the glyph its registry entry holds", () => {
    for (const name of flareIconNames) {
      const svg = mount(FlareIcon, { props: { name } }).get("svg");
      expect(svg.attributes("data-flare-glyph"), name).toBe(glyphOf(flareIcons[name]));
    }
  });

  it("two semantic names that must look different name different glyphs", () => {
    const drawn = (name: "recall" | "reply") => mount(FlareIcon, { props: { name } }).get("svg").attributes("data-flare-glyph");
    expect(drawn("recall")).not.toBe(drawn("reply"));
  });
});
