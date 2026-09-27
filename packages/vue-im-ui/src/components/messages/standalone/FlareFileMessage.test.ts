// @vitest-environment happy-dom
//
// 文件卡片右侧的键：没保存时是下载，保存后（openFolder / 刚下完的 downloaded）是文件夹，点了发 reveal；
// 宿主发现文件已不在就把状态放回 idle，键又变回下载。
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import { defineComponent, h, nextTick, ref } from "vue";
import { useFlareI18nProvider } from "../../../shared/i18n/useFlareI18n";
import FlareFileMessage from "./FlareFileMessage.vue";

function mountFile(props: Record<string, unknown>) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareFileMessage, { name: "合同.pdf", size: "8.5 KB", ext: "PDF", onDownload: () => undefined, ...props });
    },
  }));
  return host.findComponent(FlareFileMessage);
}

describe("FlareFileMessage trailing key", () => {
  it("downloads while the file is not saved", async () => {
    const file = mountFile({ state: "idle" });
    const key = file.find("button.dl");
    expect(key.attributes("aria-label")).toBe("下载");
    await key.trigger("click");
    expect(file.emitted("download")).toHaveLength(1);
    expect(file.emitted("reveal")).toBeUndefined();
  });

  it.each(["openFolder", "downloaded"])("shows the saved file in its folder (%s)", async (state) => {
    const file = mountFile({ state });
    const key = file.find("button.dl");
    expect(key.attributes("aria-label")).toBe("在文件夹中显示");
    expect(key.attributes("disabled")).toBeUndefined();
    await key.trigger("click");
    expect(file.emitted("reveal")).toHaveLength(1);
    expect(file.emitted("download")).toBeUndefined();
    // Size and type stay on the card after the save.
    expect(file.find(".sub").text()).toBe("8.5 KB · PDF · 已下载");
  });

  it("is a download again once the host passes idle for a file that is gone", async () => {
    const state = ref<"openFolder" | "idle">("openFolder");
    const host = mount(defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        return () => h(FlareFileMessage, { name: "合同.pdf", state: state.value, onDownload: () => undefined });
      },
    }));
    expect(host.find("button.dl").attributes("aria-label")).toBe("在文件夹中显示");
    state.value = "idle";
    await nextTick();
    expect(host.find("button.dl").attributes("aria-label")).toBe("下载");
  });

  it("cannot be pressed while downloading", async () => {
    const file = mountFile({ state: "downloading" });
    const key = file.find("button.dl");
    expect(key.attributes("disabled")).toBeDefined();
    await key.trigger("click");
    expect(file.emitted("download")).toBeUndefined();
  });
});
