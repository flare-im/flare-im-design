// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../../shared/i18n/useFlareI18n";
import FlareImageGroupMessage from "./FlareImageGroupMessage.vue";
import ImageGroupView from "../MessagesView/views/ImageGroupView.vue";
import ImagePreviewModal from "../../message-preview/ImagePreviewModal.vue";

const album = (count: number) =>
  Array.from({ length: count }, (_, index) => ({ src: `https://cdn.example/${index}.jpg`, alt: index === 0 ? "封面" : "" }));

describe("image-group body", () => {
  it("lays tiles out by the shared rule and covers the last with the count not drawn", () => {
    const four = mount(FlareImageGroupMessage, { props: { images: album(4) } });
    expect(four.find(".fm-album__grid").attributes("style")).toContain("--fm-album-columns: 2");
    expect(four.findAll(".fm-album__tile")).toHaveLength(4);
    expect(four.find(".fm-album__more").exists()).toBe(false);

    const twelve = mount(FlareImageGroupMessage, { props: { images: album(12) } });
    const tiles = twelve.findAll(".fm-album__tile");
    expect(tiles).toHaveLength(9);
    expect(twelve.find(".fm-album__grid").attributes("style")).toContain("--fm-album-columns: 3");
    expect(tiles[8].find(".fm-album__more").text()).toBe("+4");
    expect(twelve.findAll(".fm-album__more")).toHaveLength(1);
  });

  it("names the album and every tile, and opens the tile's own image", async () => {
    const wrapper = mount(FlareImageGroupMessage, { props: { images: album(12), description: "周末爬山" } });
    expect(wrapper.find(".fm-album").attributes("role")).toBe("group");
    expect(wrapper.find(".fm-album").attributes("aria-label")).toContain("12");
    const buttons = wrapper.findAll("button.fm-album__open");
    expect(buttons[0].attributes("aria-label")).toContain("1");
    expect(buttons[8].attributes("aria-label")).toContain("4");
    await buttons[8].trigger("click");
    expect(wrapper.emitted("open")?.[0]).toEqual([8]);
    expect(wrapper.find(".fm-album__description").text()).toBe("周末爬山");
    expect(wrapper.find("img").attributes("alt")).toBe("封面");
  });

  it("draws nothing for an album without images", () => {
    expect(mount(FlareImageGroupMessage, { props: { images: [] } }).find(".fm-album").exists()).toBe(false);
  });

  it("dispatches a runtime album through the public body and previews the tile that was opened", async () => {
    const content = {
      contentType: "image_group",
      image_group: {
        description: "",
        images: [
          { imageId: "a", url: "https://cdn.example/a.jpg" },
          { imageId: "b", url: "https://cdn.example/b.jpg" },
        ],
      },
    };
    const wrapper = mount(defineComponent({
      setup() {
        useFlareI18nProvider("en-US");
        return () => h(ImageGroupView as Component, { isSelf: false, messageId: "m1", content });
      },
    }));
    const body = wrapper.findComponent(FlareImageGroupMessage);
    expect(body.props("images")).toHaveLength(2);
    // The literal "[Album] N photos" title is gone: the album is named for assistive technology instead.
    expect(wrapper.text()).not.toContain("Album");
    await wrapper.findAll("button.fm-album__open")[1].trigger("click");
    const preview = wrapper.findComponent(ImagePreviewModal);
    expect(preview.props("show")).toBe(true);
    expect(preview.props("imageSrc")).toBe("https://cdn.example/b.jpg");
  });
});
