// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { mount } from "@vue/test-utils";
import FlareDangerConfirm from "./FlareDangerConfirm.vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";

// FR-042: the same confirmation, presented the way the platform presents things — a bottom sheet on a
// phone, a centered dialog on a pointer device. Closing it any way is still a cancel, and `busy` holds it.

const wrappers: ReturnType<typeof mount>[] = [];

function setup(props: Record<string, unknown> = {}, bottomSheet = false) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      useFlarePlatformProvider({ capabilities: { bottomSheet } });
      return () => h(FlareDangerConfirm as Component, {
        open: true,
        title: "删除设备",
        description: "该设备将被登出。",
        target: "Ada 的 iPhone",
        ...props,
      });
    },
  }), { attachTo: document.body });
  wrappers.push(host);
  return host;
}

const sheet = () => document.body.querySelector('[data-flare-presentation="sheet"]');
const dialog = () => document.body.querySelector('[data-flare-presentation="dialog"]');

afterEach(() => {
  wrappers.splice(0).forEach((wrapper) => wrapper.unmount());
  document.body.innerHTML = "";
});

describe("FlareDangerConfirm", () => {
  it("is a sheet where the platform puts things at the bottom, and a dialog otherwise", () => {
    setup({}, true);
    expect(sheet()).not.toBeNull();
    expect(dialog()).toBeNull();

    wrappers.splice(0).forEach((wrapper) => wrapper.unmount());
    document.body.innerHTML = "";

    setup({}, false);
    expect(dialog()).not.toBeNull();
    expect(sheet()).toBeNull();
  });

  it("says the same thing either way", () => {
    for (const bottomSheet of [true, false]) {
      setup({ error: "设备已离线。" }, bottomSheet);
      const text = document.body.textContent ?? "";
      for (const words of ["该设备将被登出。", "Ada 的 iPhone", "设备已离线。", "确认", "取消"]) {
        expect(text, `${bottomSheet ? "sheet" : "dialog"}: ${words}`).toContain(words);
      }
      expect(document.body.querySelector('[role="alert"]')?.textContent).toBe("设备已离线。");
      wrappers.splice(0).forEach((wrapper) => wrapper.unmount());
      document.body.innerHTML = "";
    }
  });

  it("reports one cancel when the sheet is closed and never while busy", async () => {
    const host = setup({}, true);
    const confirm = host.findComponent(FlareDangerConfirm);
    const keys = [...document.body.querySelectorAll<HTMLButtonElement>(".flare-danger-confirm__actions button")];
    expect(keys.map((key) => key.getAttribute("aria-label"))).toEqual(["取消", "确认"]);
    keys[0].click();
    keys[1].click();
    await confirm.vm.$nextTick();
    expect(confirm.emitted("cancel")).toHaveLength(1);
    expect(confirm.emitted("confirm")).toHaveLength(1);

    wrappers.splice(0).forEach((wrapper) => wrapper.unmount());
    document.body.innerHTML = "";

    const busyHost = setup({ busy: true }, true);
    const busy = busyHost.findComponent(FlareDangerConfirm);
    const busyKeys = [...document.body.querySelectorAll<HTMLButtonElement>(".flare-danger-confirm__actions button")];
    expect(busyKeys.map((key) => key.disabled)).toEqual([true, true]);
    for (const key of busyKeys) key.click();
    // A batch that is already running cannot be cancelled by the scrim either: the sheet holds.
    busy.findComponent({ name: "FlareBottomSheet" }).vm.$emit("close");
    await busy.vm.$nextTick();
    expect(busy.emitted("cancel")).toBeUndefined();
    expect(busy.emitted("confirm")).toBeUndefined();
  });
});
