// @vitest-environment happy-dom
import { flushPromises, mount } from "@vue/test-utils";
import { h } from "vue";
import { afterEach, describe, expect, it, vi } from "vitest";
import FlareUiProvider from "../../design-system/provider/FlareUiProvider.vue";
import type { MessageLike } from "../../shared/contracts/messageRow";
import MessageActionSheet from "./MessageActionSheet.vue";
import MessageMenu from "./MessageMenu.vue";
import FlareActionMenu from "../general/FlareActionMenu.vue";

const message: MessageLike = {
  serverId: "server-1", clientMsgId: "client-1", senderId: "ivy", senderDisplayName: "Ivy",
  conversationSeq: 1, createdAt: 1_736_922_600_000, clientCreatedAt: 1_736_922_600_000, messageType: 1,
  content: { contentType: "text", text: "Ship it" }, status: "read", isRecalled: false, isRead: true,
  timelineKey: "server:server-1", timelineSortTs: 1, attributes: {},
};

function mountMenu(listeners: Record<string, (...args: unknown[]) => void>) {
  const host = mount(FlareUiProvider, {
    props: { themeMode: "light", locale: "en-US", layoutMode: "pc" },
    slots: {
      default: () => h(MessageMenu, {
        message, currentUserId: "me", presentation: "dropdown",
        actions: [{ id: "translate", label: "Translate", icon: "language" }],
        ...listeners,
      }, { default: () => h("div", "bubble") }),
    },
  });
  return host;
}

/** The dropdown mounts on first open. */
async function openDropdown(host: ReturnType<typeof mountMenu>) {
  expect(host.findComponent(FlareActionMenu).exists()).toBe(false);
  (host.findComponent(MessageMenu).vm as unknown as { openMenu(): void }).openMenu();
  await flushPromises();
  return host.findComponent(FlareActionMenu);
}

afterEach(() => vi.unstubAllGlobals());

describe("MessageMenu dropdown", () => {
  it("dispatches the picked built-in and host actions", async () => {
    const calls: unknown[][] = [];
    const host = mountMenu({
      onForward: (...args) => calls.push(["forward", ...args]),
      onAction: (...args) => calls.push(["action", ...args]),
    });
    const dropdown = await openDropdown(host);
    dropdown.vm.$emit("select", "forward");
    dropdown.vm.$emit("select", "action:translate");
    expect(calls).toEqual([["forward", "client-1"], ["action", "translate", "client-1"]]);
    host.unmount();
  });

  it("dispatches picks from the phone action sheet too", async () => {
    const calls: unknown[][] = [];
    const host = mount(FlareUiProvider, {
      props: { themeMode: "light", locale: "en-US", layoutMode: "h5" },
      slots: {
        default: () => h(MessageMenu, {
          message, currentUserId: "me", presentation: "bottomSheet",
          onRecall: (...args: unknown[]) => calls.push(["recall", ...args]),
        }, { default: () => h("div", "bubble") }),
      },
      attachTo: document.body,
    });
    (host.findComponent(MessageMenu).vm as unknown as { openMenu(): void }).openMenu();
    await flushPromises();
    host.findComponent(MessageActionSheet).vm.$emit("action", "recall");
    expect(calls).toEqual([["recall", "client-1"]]);
    host.unmount();
  });

  it("copies the text and reports whether the clipboard took it", async () => {
    const writeText = vi.fn().mockResolvedValueOnce(undefined).mockRejectedValueOnce(new Error("denied"));
    vi.stubGlobal("navigator", { clipboard: { writeText } });
    const copies: unknown[][] = [];
    const host = mountMenu({ onCopy: (...args) => copies.push(args) });
    const dropdown = await openDropdown(host);
    dropdown.vm.$emit("select", "copy");
    await flushPromises();
    dropdown.vm.$emit("select", "copy");
    await flushPromises();
    expect(writeText).toHaveBeenCalledWith("Ship it");
    expect(copies).toEqual([["client-1", true], ["client-1", false]]);
    host.unmount();
  });
});
