// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, ref, type Component } from "vue";
import { afterEach, describe, expect, it, vi } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareVersionPanel from "./FlareVersionPanel.vue";

let host: ReturnType<typeof mount> | undefined;
afterEach(() => {
  host?.unmount();
  host = undefined;
});

function mountPanel(props: Record<string, unknown>, listeners: Record<string, () => void> = {}, locale: "zh-CN" | "en-US" = "zh-CN") {
  const updateState = ref<string | null>((props.updateState as string | undefined) ?? null);
  host = mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () => h(FlareVersionPanel as Component, { version: "2.3.2", ...props, updateState: updateState.value, ...listeners });
    },
  }), { attachTo: document.body });
  return updateState;
}

const rows = () => host!.findAll(".flare-settings__row");
const action = () => rows().at(-1)!;

describe("FlareVersionPanel", () => {
  it("lists the version, the build, the channel and the update row", () => {
    mountPanel({ build: 20302, channel: "stable" });
    expect(rows().map((row) => row.find(".flare-settings__label").text())).toEqual(["版本", "构建号", "渠道", "检查更新"]);
    expect(rows()[0]!.find(".flare-settings__detail").text()).toBe("2.3.2");
    expect(rows()[1]!.find(".flare-settings__detail").text()).toBe("20302");
    expect(rows()[2]!.find(".flare-settings__detail").text()).toBe("正式版");
  });

  it("writes a channel it has no words for as it arrived, and leaves out what it was not given", () => {
    mountPanel({ channel: "nightly" });
    expect(rows().map((row) => row.find(".flare-settings__label").text())).toEqual(["版本", "渠道", "检查更新"]);
    expect(rows()[1]!.find(".flare-settings__detail").text()).toBe("nightly");
  });

  it("checks from the idle row and disables it while checking", async () => {
    const onCheck = vi.fn();
    const updateState = mountPanel({}, { onCheck });
    await action().trigger("click");
    expect(onCheck).toHaveBeenCalledTimes(1);
    updateState.value = "checking";
    await nextTick();
    expect(action().attributes("disabled")).toBeDefined();
    expect(action().find(".flare-settings__detail").text()).toBe("正在检查…");
    expect(host!.find(".flare-version-panel__spoken").text()).toBe("正在检查…");
  });

  it("offers the update when a version is available, and the restart when it is ready", async () => {
    const onUpdate = vi.fn();
    const updateState = mountPanel({ updateState: "available" }, { onUpdate }, "en-US");
    expect(action().find(".flare-settings__label").text()).toBe("Update now");
    await action().trigger("click");
    expect(onUpdate).toHaveBeenCalledTimes(1);
    updateState.value = "readyToInstall";
    await nextTick();
    expect(action().find(".flare-settings__label").text()).toBe("Restart to finish updating");
    await action().trigger("click");
    expect(onUpdate).toHaveBeenCalledTimes(2);
  });

  it("disables the row while nobody handles what it would do", () => {
    mountPanel({ updateState: "available" }, { onCheck: vi.fn() });
    expect(action().attributes("disabled")).toBeDefined();
  });
});
