// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";
import FlareStartConversationDialog from "./FlareStartConversationDialog.vue";

let host: ReturnType<typeof mount> | undefined;
afterEach(() => {
  host?.unmount();
  host = undefined;
});

function mountDialog(props: Record<string, unknown>, bottomSheet?: boolean) {
  host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("en-US");
      if (bottomSheet !== undefined) useFlarePlatformProvider({ capabilities: { bottomSheet } });
      return () => h(FlareStartConversationDialog as Component, props);
    },
  }), { attachTo: document.body });
  return host.findComponent(FlareStartConversationDialog);
}

describe("FlareStartConversationDialog", () => {
  // 一张面两种出场:桌面这边也走组件库自己的弹窗,不再是 naive 的 NModal —— 于是
  // 滚动锁、Escape 的层序、传送目标两边同一套。
  it("renders the kit's centered dialog where the platform has no bottom sheet", () => {
    mountDialog({ open: true, peerUserId: "u2" }, false);
    const surface = document.body.querySelector(".flare-sheet");
    expect(surface).not.toBeNull();
    expect((surface as HTMLElement).dataset.flarePresentation).toBe("dialog");
  });

  it("renders the same form as a bottom sheet where the platform says so", async () => {
    const dialog = mountDialog({ open: true, peerUserId: "u2" }, true);
    const sheet = document.body.querySelector(".flare-sheet");
    expect(sheet).not.toBeNull();
    expect((sheet as HTMLElement).dataset.flarePresentation).toBe("sheet");
    expect(sheet!.querySelector(".start-dialog-form")).not.toBeNull();
    const confirm = [...sheet!.querySelectorAll("button")].at(-1)!;
    confirm.click();
    expect(dialog.emitted("confirm")).toHaveLength(1);
  });

  it("refuses to confirm without a peer and never closes while busy", () => {
    const dialog = mountDialog({ open: true, peerUserId: "   ", busy: true }, true);
    const sheet = document.body.querySelector(".flare-sheet")!;
    [...sheet.querySelectorAll("button")].at(-1)!.click();
    expect(dialog.emitted("confirm")).toBeUndefined();
    (sheet.parentElement as HTMLElement).click();
    expect(dialog.emitted("update:open")).toBeUndefined();
  });
});
