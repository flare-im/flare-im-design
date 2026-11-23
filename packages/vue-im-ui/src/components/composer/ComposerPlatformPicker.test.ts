// @vitest-environment happy-dom
import { afterEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { flushPromises, mount } from "@vue/test-utils";
import EnhancedComposer from "./EnhancedComposer.vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";
import { platformErr, platformOk, type FlarePlatformAdapter } from "../../shared/platform/contract";

// FR-053: the adapter declared pickers that nothing called, so every app clicked a hidden file input
// of its own. The composer asks the platform now and reports the files through one event.

const wrappers: ReturnType<typeof mount>[] = [];

function setup(adapter: FlarePlatformAdapter, props: Record<string, unknown> = {}) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      useFlarePlatformProvider({ adapter });
      return () => h(EnhancedComposer as Component, props);
    },
  }), { attachTo: document.body });
  wrappers.push(host);
  return host.findComponent(EnhancedComposer);
}

const picture = () => new File(["x"], "sunset.jpg", { type: "image/jpeg" });

afterEach(() => {
  wrappers.splice(0).forEach((wrapper) => wrapper.unmount());
  document.body.innerHTML = "";
});

describe("the composer and the platform pickers", () => {
  it("offers the video picker through the attachment menu on desktop", async () => {
    const file = new File(["video"], "clip.mp4", { type: "video/mp4" });
    const pickFiles = vi.fn(async () => platformOk([{ name: file.name, file }]));
    const composer = setup({ pickFiles }, { toolbarPresentation: "expanded", activePanel: "more" });
    expect(composer.find('.composer-toolbar [aria-label="视频"]').exists()).toBe(false);
    await composer.get('[data-action-id="video"]').trigger("click");
    await flushPromises();

    expect(pickFiles).toHaveBeenCalledWith({ accept: ["video/*"] });
    expect(composer.emitted("files-drop")).toEqual([[[file]]]);
    const fileOnly = setup({ pickFiles }, { activePanel: "more", actions: [{ id: "file" }] });
    expect(fileOnly.find('[data-action-id="video"]').exists()).toBe(false);
    const nativeHost = setup({ pickFiles }, {
      toolbarPresentation: "expanded", activePanel: "more", actions: [{ id: "video", intent: "create_video" }],
    });
    await nativeHost.get('[data-action-id="video"]').trigger("click");
    expect(nativeHost.emitted("build")).toEqual([["create_video"]]);
    expect(pickFiles).toHaveBeenCalledTimes(1);
  });

  it("asks the platform for pictures and reports what came back", async () => {
    const pickImages = vi.fn(async () => platformOk([{ name: "sunset.jpg", file: picture() }]));
    const composer = setup({ pickImages });

    (composer.vm as unknown as { build: (id: string) => void }).build("image");
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(pickImages).toHaveBeenCalledWith({ multiple: true });
    expect(composer.emitted("files-drop")?.[0]?.[0]).toHaveLength(1);
    expect(composer.emitted("build")).toBeUndefined();
  });

  it("takes a photo through the platform camera and reports it as a picked picture", async () => {
    const pickImages = vi.fn(async () => platformOk([{ name: "photo.jpg", file: picture() }]));
    const composer = setup({ pickImages });

    (composer.vm as unknown as { build: (id: string) => void }).build("camera");
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(pickImages).toHaveBeenCalledWith({ camera: true });
    expect(composer.emitted("files-drop")?.[0]?.[0]).toHaveLength(1);
    expect(composer.emitted("build")).toBeUndefined();
  });

  it("maps the composer menu's camera item (a host list from the SDK) to the camera", async () => {
    const pickImages = vi.fn(async () => platformOk([{ name: "photo.jpg", file: picture() }]));
    const host = mount(defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        useFlarePlatformProvider({ adapter: { pickImages } });
        return () => h(EnhancedComposer as Component, { actions: [{ id: "camera", kind: "feature" }, { id: "file", kind: "feature" }] });
      },
    }), { attachTo: document.body });
    wrappers.push(host);
    const composer = host.findComponent(EnhancedComposer);
    (composer.vm as unknown as { build: (id: string) => void }).build("camera");
    await new Promise((resolve) => setTimeout(resolve, 0));
    expect(pickImages).toHaveBeenCalledWith({ camera: true });
    expect(composer.emitted("files-drop")).toHaveLength(1);
  });

  it("a host without the picker keeps getting the camera intent", async () => {
    const composer = setup({});
    (composer.vm as unknown as { build: (id: string) => void }).build("camera");
    await new Promise((resolve) => setTimeout(resolve, 0));
    expect(composer.emitted("build")).toEqual([["camera"]]);
  });

  it("a host without the picker keeps getting the intent", async () => {
    const composer = setup({});
    (composer.vm as unknown as { build: (id: string) => void }).build("image");
    await new Promise((resolve) => setTimeout(resolve, 0));
    expect(composer.emitted("build")).toEqual([["image"]]);
    expect(composer.emitted("files-drop")).toBeUndefined();
  });

  it("a cancelled pick is the person saying no: nothing is reported", async () => {
    const pickFiles = vi.fn(async () => platformErr<never>("CANCELLED"));
    const composer = setup({ pickFiles });

    (composer.vm as unknown as { build: (id: string) => void }).build("file");
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(pickFiles).toHaveBeenCalled();
    expect(composer.emitted("files-drop")).toBeUndefined();
    expect(composer.emitted("build")).toBeUndefined();
  });
});
