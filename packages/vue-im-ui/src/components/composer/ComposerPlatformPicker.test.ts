// @vitest-environment happy-dom
import { afterEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { mount } from "@vue/test-utils";
import EnhancedComposer from "./EnhancedComposer.vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";
import { platformErr, platformOk, type FlarePlatformAdapter } from "../../shared/platform/contract";

// FR-053: the adapter declared pickers that nothing called, so every app clicked a hidden file input
// of its own. The composer asks the platform now and reports the files through one event.

const wrappers: ReturnType<typeof mount>[] = [];

function setup(adapter: FlarePlatformAdapter) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      useFlarePlatformProvider({ adapter });
      return () => h(EnhancedComposer as Component, {});
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
  it("asks the platform for pictures and reports what came back", async () => {
    const pickImages = vi.fn(async () => platformOk([{ name: "sunset.jpg", file: picture() }]));
    const composer = setup({ pickImages });

    (composer.vm as unknown as { build: (id: string) => void }).build("image");
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(pickImages).toHaveBeenCalledWith({ multiple: true });
    expect(composer.emitted("files-drop")?.[0]?.[0]).toHaveLength(1);
    expect(composer.emitted("build")).toBeUndefined();
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
