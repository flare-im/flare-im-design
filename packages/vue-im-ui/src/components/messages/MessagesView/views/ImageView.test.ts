// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import FlareUiProvider from "../../../../design-system/provider/FlareUiProvider.vue";
import ImageView from "./ImageView.vue";

let host: ReturnType<typeof mount> | undefined;
afterEach(() => { host?.unmount(); host = undefined; document.body.innerHTML = ""; });

const content = { contentType: "image", image: { source: { url: "https://cdn.example.com/p.png" } } };

function mountImage(props: Record<string, unknown>) {
  host = mount(FlareUiProvider, {
    props: { themeMode: "light", locale: "zh-CN", layoutMode: "pc" },
    slots: { default: () => h(ImageView as Component, { content, isSelf: false, messageId: "m1", ...props }) },
    attachTo: document.body,
  });
  return host;
}

async function openPreview(view: ReturnType<typeof mount>) {
  await flushPromises();
  await view.get(".flare-image-message, .im-image button, .im-image [role='button']").trigger("click");
  await flushPromises();
}

describe("ImageView preview", () => {
  it("offers a download in the preview only when the host offers one", async () => {
    const actions: string[] = [];
    const view = mountImage({ mediaAction: "download", "onMedia-action": (action: string) => actions.push(action) });
    await openPreview(view);
    const download = document.body.querySelector<HTMLButtonElement>('button[aria-label="下载图片"]');
    expect(download).not.toBeNull();
    download!.click();
    expect(actions).toEqual(["download"]);
  });

  it("has no download button without a host download", async () => {
    const view = mountImage({});
    await openPreview(view);
    expect(document.body.querySelector('button[aria-label="下载图片"]')).toBeNull();
  });
});
