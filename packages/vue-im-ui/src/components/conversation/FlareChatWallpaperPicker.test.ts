// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareChatWallpaperPicker from "./FlareChatWallpaperPicker.vue";

const options = [
  { id: "plain", label: "纯色", color: "#f5f6f8" },
  { id: "dusk", label: "暮色", imageUrl: "https://cdn.example/dusk.jpg" },
  { id: "noname" },
];

function render(props: Record<string, unknown>) {
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareChatWallpaperPicker, props);
    },
  }));
}

/**
 * A swatch grid where the chosen one is announced, not only outlined — every swatch is a toggle
 * with `aria-pressed`, and a swatch with no label still has a name. Release criterion §1.
 */
describe("FlareChatWallpaperPicker", () => {
  it("draws one swatch per option", () => {
    expect(render({ options }).findAll(".flare-wallpaper__swatch")).toHaveLength(3);
  });

  it("says which swatch is chosen, for the eye and for a screen reader", () => {
    const wrapper = render({ options, selectedId: "dusk" });
    const swatches = wrapper.findAll(".flare-wallpaper__swatch");
    expect(swatches.map((s) => s.attributes("aria-pressed"))).toEqual(["false", "true", "false"]);
    expect(swatches[1].classes()).toContain("is-selected");
    expect(wrapper.findAll(".flare-wallpaper__check")).toHaveLength(1);
  });

  it("names a swatch by its label, and falls back to its id rather than going unnamed", () => {
    const labels = render({ options }).findAll(".flare-wallpaper__swatch").map((s) => s.attributes("aria-label"));
    expect(labels).toEqual(["纯色", "暮色", "noname"]);
  });

  it("paints a picture swatch with the picture and a colour swatch with the colour", () => {
    const styles = render({ options }).findAll(".flare-wallpaper__swatch").map((s) => s.attributes("style") ?? "");
    expect(styles[0]).toContain("#f5f6f8");
    expect(styles[1]).toContain("dusk.jpg");
  });

  it("reports the id, so the host stores a choice and not a colour", async () => {
    const wrapper = render({ options });
    await wrapper.findAll(".flare-wallpaper__swatch")[1].trigger("click");
    expect(wrapper.findComponent(FlareChatWallpaperPicker).emitted("select")?.[0]).toEqual(["dusk"]);
  });

  it("marks nothing when the host has chosen nothing", () => {
    const wrapper = render({ options });
    expect(wrapper.findAll(".flare-wallpaper__check")).toHaveLength(0);
  });
});
