// @vitest-environment happy-dom
import { mount, enableAutoUnmount } from "@vue/test-utils";
import { defineComponent, h, nextTick, type Component } from "vue";
import FlareActionMenu from "../general/FlareActionMenu.vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import { actionMenuEntries, type FlareActionItem } from "../../shared/contracts/action-menu";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { afterEach, describe, expect, it } from "vitest";
import fixture from "../../../../../spec/conversation-state-vectors.json";
import { conversationPreviewKind, conversationTitleEmphasis, conversationUnreadLabel } from "../../shared/contracts/conversation-presentation";
import FlareConversationRow from "./FlareConversationRow.vue";
import FlareConversationList from "./FlareConversationList.vue";

const vectors = fixture.cases;
enableAutoUnmount(afterEach);
function mountKit(component: Component, props: Record<string, unknown>) {
  const host = mount(defineComponent({ setup() {
    useFlareI18nProvider("en-US");
    return () => h(component, props);
  } }), { attachTo: document.body });
  return host.findComponent(component);
}
describe("canonical conversation state combinations", () => {
  for (const vector of vectors) it(vector.id, () => {
    expect(conversationPreviewKind(vector)).toBe(vector.expectedKind);
    expect(conversationUnreadLabel(vector.unreadCount)).toBe(vector.expectedUnread);
    expect(conversationTitleEmphasis(vector)).toBe(vector.expectedEmphasis);
  });
  it("bolds the title only when the row needs attention", () => {
    const quiet = mountKit(FlareConversationRow, { item: { id: "quiet", muted: true, unreadCount: 3 } });
    expect(quiet.get(".im-conv-item").classes()).not.toContain("im-conv-item--strong");
    const mention = mountKit(FlareConversationRow, { item: { id: "mention", muted: true, mentioned: true, unreadCount: 3 } });
    expect(mention.get(".im-conv-item").classes()).toContain("im-conv-item--strong");
    const read = mountKit(FlareConversationRow, { item: { id: "read", mentioned: true } });
    expect(read.get(".im-conv-item").classes()).not.toContain("im-conv-item--strong");
  });
  it("normalizes invalid counts and respects formatted time", () => {
    expect(conversationUnreadLabel(NaN)).toBe("0");
    expect(conversationUnreadLabel(Infinity)).toBe("0");
    const row = mountKit(FlareConversationRow, { item: { id: "one", timestampLabel: "Yesterday", draft: "WIP", muted: true, pinned: true, unreadCount: 1200 } });
    expect(row.get(".im-conv-item__time").text()).toBe("Yesterday");
    expect(row.get(".im-conv-item__unread-pill").text()).toBe("999+");
    expect(row.get(".im-conv-item").attributes("data-preview-kind")).toBe("draft");
    expect(row.findAll(".im-conv-item__tag")).toHaveLength(0);
    expect(row.get("button").attributes("aria-label")).toContain("1200");
  });
  it("provides canonical rows by default in host order", async () => {
    const list = mountKit(FlareConversationList, {
      items: [{ id: "b", pinned: true }, { id: "c", pinned: true }, { id: "a" }],
    });
    const buttons = list.findAll(".im-conv-item__select");
    expect(list.findAll("[data-conversation-id]").map(row => row.attributes("data-conversation-id"))).toEqual(["b", "c", "a"]);
    await buttons[0].trigger("click");
    expect(list.emitted("select")).toEqual([["b"]]);
    (buttons[0].element as HTMLElement).focus();
    await buttons[0].trigger("keydown", { key: "End" });
    expect(document.activeElement).toBe(buttons[2].element);
    await buttons[2].trigger("keydown", { key: "Home" });
    expect(document.activeElement).toBe(buttons[0].element);
    await buttons[0].trigger("keydown", { key: "ArrowDown" });
    expect(document.activeElement).toBe(buttons[1].element);
  });
  it("renders loading and empty through the kit empty state", () => {
    const loading = mountKit(FlareConversationList, { items: [], loading: true });
    expect(loading.find(".flare-empty__spinner").exists()).toBe(true);
    expect(loading.text()).toContain("Loading");
    const empty = mountKit(FlareConversationList, { items: [] });
    expect(empty.find(".flare-empty__spinner").exists()).toBe(false);
    expect(empty.get(".flare-empty__title").text()).toBe("No conversations");
  });
  it("offers a menu only for the actions the host implements", async () => {
    const bare = mountKit(FlareConversationRow, { item: { id: "bare", displayName: "Ivy" } });
    const nativeMenu = new MouseEvent("contextmenu", { bubbles: true, cancelable: true });
    bare.get(".im-conv-item").element.dispatchEvent(nativeMenu);
    await nextTick(); await nextTick();
    expect(nativeMenu.defaultPrevented).toBe(false);
    expect(bare.findComponent(FlareActionMenu).exists()).toBe(false);
    expect(bare.findComponent(FlareBottomSheet).exists()).toBe(false);

    const row = mountKit(FlareConversationRow, {
      item: { id: "ivy", displayName: "Ivy", pinned: true, unreadCount: 0 },
      capabilities: { pin: true, markRead: true, markUnread: true, delete: true },
    });
    await row.get(".im-conv-item").trigger("contextmenu", { clientX: 20, clientY: 30 });
    await nextTick(); await nextTick();
    const menu = row.findComponent(FlareActionMenu);
    expect(menu.exists()).toBe(true);
    const drawn = actionMenuEntries(menu.props("items") as FlareActionItem<unknown>[]).map((entry) => (entry.kind === "item" ? entry.item.id : "|"));
    expect(drawn).toEqual(["unpin", "markUnread", "|", "delete"]);
    menu.vm.$emit("select", "markUnread");
    expect(row.emitted("action")).toEqual([["markUnread", "ivy"]]);
  });
  it("turns a selectable row into a named checkbox without a menu", async () => {
    const row = mountKit(FlareConversationRow, {
      item: { id: "ivy", displayName: "Ivy" },
      capabilities: { pin: true, delete: true },
      selectable: true,
      selected: true,
    });
    const button = row.get(".im-conv-item__select");
    expect(button.attributes("role")).toBe("checkbox");
    expect(button.attributes("aria-checked")).toBe("true");
    expect(button.attributes("aria-label")).toContain("Ivy");
    await button.trigger("click");
    expect(row.emitted("toggleSelect")).toEqual([["ivy"]]);
    expect(row.emitted("select")).toBeUndefined();
    await row.get(".im-conv-item").trigger("contextmenu");
    await nextTick(); await nextTick();
    expect(row.findComponent(FlareActionMenu).exists()).toBe(false);
    const list = mountKit(FlareConversationList, { items: [{ id: "a" }, { id: "b" }], selectable: true, selectedIds: ["b"] });
    expect(list.findAll(".im-conv-item__select").map((node) => node.attributes("aria-checked"))).toEqual(["false", "true"]);
    await list.findAll(".im-conv-item__select")[0].trigger("click");
    expect(list.emitted("toggleSelect")).toEqual([["a"]]);
  });
  it("renders translated failure and typing states", () => {
    const typing = mountKit(FlareConversationRow, { item: { id: "typing", typing: true } });
    expect(typing.text()).toContain("Typing");
    const failed = mountKit(FlareConversationRow, { item: { id: "failed", failed: true } });
    expect(failed.text()).toContain("Send failed");
    expect(typing.text() + failed.text()).not.toContain("conversation.");
  });
});
