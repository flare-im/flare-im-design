// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import FlareImageGrid from "./FlareImageGrid.vue";

const pics = (n: number) => Array.from({ length: n }, (_, i) => ({ url: `https://cdn.example/${i}.jpg`, alt: `图 ${i}` }));

/**
 * The column count follows the count of pictures the way a chat app lays them out (one big, four as
 * 2×2, otherwise three across), and a grid that is capped says how many more there are rather than
 * dropping them silently. Release criterion §1 (component tests).
 */
describe("FlareImageGrid", () => {
  it("lays one picture out on its own", () => {
    const wrapper = mount(FlareImageGrid, { props: { images: pics(1) } });
    expect(wrapper.attributes("style")).toContain("--cols: 1");
    expect(wrapper.classes()).toContain("is-single");
  });

  it("puts four in a square and five across three", () => {
    expect(mount(FlareImageGrid, { props: { images: pics(4) } }).attributes("style")).toContain("--cols: 2");
    expect(mount(FlareImageGrid, { props: { images: pics(5) } }).attributes("style")).toContain("--cols: 3");
    expect(mount(FlareImageGrid, { props: { images: pics(2) } }).attributes("style")).toContain("--cols: 2");
  });

  it("caps the tiles and says how many are not shown", () => {
    const wrapper = mount(FlareImageGrid, { props: { images: pics(12), max: 9 } });
    expect(wrapper.findAll(".flare-image-grid__cell")).toHaveLength(9);
    expect(wrapper.find(".flare-image-grid__more").text()).toBe("+3");
  });

  it("shows no overflow badge when everything fits", () => {
    const wrapper = mount(FlareImageGrid, { props: { images: pics(3) } });
    expect(wrapper.find(".flare-image-grid__more").exists()).toBe(false);
  });

  it("names every tile for a screen reader, and falls back to the kit's words", () => {
    const wrapper = mount(FlareImageGrid, {
      props: { images: [{ url: "https://cdn.example/a.jpg", alt: "日落" }, { url: "https://cdn.example/b.jpg" }] },
    });
    const labels = wrapper.findAll(".flare-image-grid__cell").map((b) => b.attributes("aria-label"));
    expect(labels[0]).toBe("日落");
    expect(labels[1]).toBeTruthy();
  });

  it("reports which tile was opened, by index into the pictures it was given", async () => {
    const wrapper = mount(FlareImageGrid, { props: { images: pics(6) } });
    await wrapper.findAll(".flare-image-grid__cell")[4].trigger("click");
    expect(wrapper.emitted("open")?.[0]).toEqual([4]);
  });

  it("draws a placeholder rather than a broken image when a url is missing", () => {
    const wrapper = mount(FlareImageGrid, { props: { images: [{ alt: "还没上传" }] } });
    expect(wrapper.find("img").exists()).toBe(false);
    expect(wrapper.find(".flare-image-grid__ph").exists()).toBe(true);
  });
});
