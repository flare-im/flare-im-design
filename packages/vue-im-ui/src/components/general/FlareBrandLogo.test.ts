// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent } from "vue";
import { describe, expect, it } from "vitest";
import FlareBrandLogo from "./FlareBrandLogo.vue";

/**
 * The mark is an image with a name, sized by the host, in two treatments. Two instances on one page
 * must not share a gradient id — a duplicate id makes the second one paint with the first one's
 * fill. Release criterion §1 (component tests).
 */
describe("FlareBrandLogo", () => {
  it("is an image with a name, not a decorative div", () => {
    const wrapper = mount(FlareBrandLogo);
    expect(wrapper.attributes("role")).toBe("img");
    expect(wrapper.attributes("aria-label")).toBe("flare IM");
  });

  it("takes its size from the host, in both axes", () => {
    const wrapper = mount(FlareBrandLogo, { props: { size: 32 } });
    expect(wrapper.attributes("style")).toContain("width: 32px");
    expect(wrapper.attributes("style")).toContain("height: 32px");
  });

  it("swaps fill and ground between the two treatments", () => {
    const gradient = mount(FlareBrandLogo);
    const plate = mount(FlareBrandLogo, { props: { variant: "plate" } });
    const body = (wrapper: ReturnType<typeof mount>) => wrapper.find("path").attributes("fill")!;
    expect(body(gradient)).toMatch(/^url\(#/);
    expect(body(plate)).toBe("#ffffff");
    expect(plate.find("g").attributes("fill")).toMatch(/^url\(#/);
  });

  it("gives every instance on a page its own gradient id", () => {
    // Two marks in one app, which is what a page has: an SVG id is document-global, so a shared one
    // would make the second mark paint with the first one's fill.
    const page = defineComponent({
      components: { FlareBrandLogo },
      template: '<div><FlareBrandLogo /><FlareBrandLogo variant="plate" /></div>',
    });
    const ids = mount(page).findAll("linearGradient").map((node) => node.attributes("id"));
    expect(ids).toHaveLength(2);
    expect(ids[0]).toBeTruthy();
    expect(new Set(ids).size).toBe(2);
  });
});
