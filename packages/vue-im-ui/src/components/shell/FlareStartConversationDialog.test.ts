// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { NModal } from "naive-ui";
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
  it("renders a centered modal where the platform has no bottom sheet", () => {
    const dialog = mountDialog({ open: true, peerUserId: "u2" }, false);
    expect(dialog.findComponent(NModal).exists()).toBe(true);
    expect(document.body.querySelector(".flare-sheet")).toBeNull();
  });

  it("renders the same form as a bottom sheet where the platform says so", async () => {
    const dialog = mountDialog({ open: true, peerUserId: "u2" }, true);
    expect(dialog.findComponent(NModal).exists()).toBe(false);
    const sheet = document.body.querySelector(".flare-sheet");
    expect(sheet).not.toBeNull();
    expect(sheet!.querySelector("[data-flare-sheet='true']")).not.toBeNull();
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
