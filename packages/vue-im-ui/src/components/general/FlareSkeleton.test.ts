// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import FlareSkeleton from "./FlareSkeleton.vue";

describe("plugin page skeleton shapes (R8)", () => {
  it("card is one card, list repeats rows, form is four labelled fields", () => {
    const card = mount(FlareSkeleton, { props: { variant: "card" } });
    expect(card.findAll(".sk-card")).toHaveLength(1);
    const list = mount(FlareSkeleton, { props: { variant: "list", rows: 6 } });
    expect(list.findAll(".sk-list-row")).toHaveLength(6);
    const form = mount(FlareSkeleton, { props: { variant: "form", rows: 9 } });
    expect(form.findAll(".sk-field")).toHaveLength(4);
    expect(form.findAll(".sk-input")).toHaveLength(4);
    for (const wrapper of [card, list, form]) {
      expect(wrapper.attributes("aria-hidden")).toBe("true");
      wrapper.unmount();
    }
  });

  it("tile is one composer panel item: an icon square over a short label", () => {
    const tile = mount(FlareSkeleton, { props: { variant: "tile", rows: 5 } });
    expect(tile.findAll(".sk-tile")).toHaveLength(1);
    expect(tile.findAll(".sk-tile-label")).toHaveLength(1);
    expect(tile.attributes("aria-hidden")).toBe("true");
    tile.unmount();
  });
});
