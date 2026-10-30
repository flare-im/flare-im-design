// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { h } from "vue";
import { afterEach, describe, expect, it, vi } from "vitest";
import FlareUiProvider from "../../design-system/provider/FlareUiProvider.vue";
import type { MessageLike } from "../../shared/contracts/messageRow";
import MessageBubble from "./MessageBubble.vue";
import MessageMeta from "./MessageMeta.vue";

const hosts: ReturnType<typeof mount>[] = [];
const contents: MessageLike["content"][] = [
  { contentType: "image", image: { url: "/photo.webp" } },
  { contentType: "video", video: { url: "/clip.mp4" } },
  { contentType: "sticker", sticker: { url: "/sticker.webp" } },
  { contentType: "emoji", emoji: { key: "grinning_face" } },
  { contentType: "text", text: { text: "[grinning_face]" } },
];

function setup(
  content: MessageLike["content"],
  self = true,
  layoutMode: "pc" | "h5" = "pc",
  extra: Partial<MessageLike> = {},
  listeners: Record<string, unknown> = {},
  bubbleProps: Record<string, unknown> = {},
) {
  const message: MessageLike = {
    serverId: "server-1", clientMsgId: "client-1", senderId: self ? "me" : "ivy",
    senderDisplayName: "Ivy", conversationSeq: 1, createdAt: 1_736_922_600_000,
    clientCreatedAt: 1_736_922_600_000, messageType: 1, content, status: "read",
    isRecalled: false, isRead: true, timelineKey: "message-1", timelineSortTs: 1,
    attributes: {}, ...extra,
  };
  const host = mount(FlareUiProvider, {
    props: { layoutMode, themeMode: "light", locale: "zh-CN" },
    slots: { default: () => h(MessageBubble, { message, self, currentUserId: "me", ...bubbleProps, ...listeners }) },
    global: { stubs: { MessageContentView: { template: '<div class="test-media">Media</div>' } } },
  });
  hosts.push(host);
  return host.findComponent(MessageBubble);
}

afterEach(() => hosts.splice(0).forEach(host => host.unmount()));

describe("media message metadata", () => {
  for (const layout of ["pc", "h5"] as const) {
    for (const self of [false, true]) {
      it.each(contents)(`keeps $contentType metadata below media in ${layout}, self=${self}`, (content) => {
        const bubble = setup(content, self, layout);
        expect(bubble.find(".message-bubble--chromeless-media").exists()).toBe(true);
        const meta = bubble.findComponent(MessageMeta);
        expect(meta.props("placement")).toBe("below");
        expect(meta.props("tone")).toBe("default");
        expect(meta.props("status")).toBe(self ? "read" : undefined);
        expect(bubble.get(".message-bubble-body").element.nextElementSibling).toBe(meta.element);
      });
    }
  }

  it("keeps outgoing text, voice, and quoted media on their bubble palette", () => {
    const text = setup({ contentType: "text", text: { text: "Hello" } }).findComponent(MessageMeta);
    expect(text.props("tone")).toBe("onOutgoing");
    expect(text.props("placement")).toBe("inline");
    const voice = setup({ contentType: "audio", audio: { url: "/voice.webm" } }).findComponent(MessageMeta);
    expect(voice.props("tone")).toBe("onOutgoing");
    expect(voice.props("placement")).toBe("bubbleFooter");
    const quoted = setup(contents[0], true, "pc", { quotePreview: "A reference" });
    expect(quoted.find(".message-bubble--chromeless-media").exists()).toBe(false);
    expect(quoted.findComponent(MessageMeta).props("tone")).toBe("onOutgoing");
    expect(quoted.findComponent(MessageMeta).props("placement")).toBe("bubbleFooter");
  });

  it("puts a card's time under it, never over it (no overlay pill)", () => {
    for (const content of [
      { contentType: "location", location: { latitude: 1, longitude: 2 } },
      { contentType: "custom", type: "flare.plugin.message.v1", data: {} },
    ]) {
      const bubble = setup(content, true);
      expect(bubble.attributes("data-surface")).toBe("card");
      expect(bubble.find(".message-bubble--chromeless-card").exists()).toBe(true);
      const meta = bubble.findComponent(MessageMeta);
      expect(meta.props("placement")).toBe("below");
      expect(meta.props("tone")).toBe("default");
      expect(meta.classes()).not.toContain("message-meta-row--overlay");
      expect(bubble.get(".message-bubble-body").element.nextElementSibling).toBe(meta.element);
    }
  });

  it("preserves edited, ephemeral, and failed-send retry semantics below media", async () => {
    const onResend = vi.fn();
    const bubble = setup(contents[2], true, "h5", {
      status: "failed", isEdited: true, attributes: { ephemeralState: "readOnce" },
    }, { onResend });
    const meta = bubble.findComponent(MessageMeta);
    expect(meta.text()).toContain("已编辑");
    expect(meta.props("ephemeral")).toBe("readOnce");
    const retry = meta.get("[data-meta-retry]");
    expect(retry.text()).toBe("发送失败，重试");
    expect(meta.find("button.status-failed").exists()).toBe(false);
    await retry.trigger("click");
    expect(onResend).toHaveBeenCalledWith("client-1");
  });

  it("draws the failure surface only for the viewer's own failed bubble", () => {
    const own = setup({ contentType: "text", text: { text: "Hello" } }, true, "pc", { status: "failed" });
    expect(own.find(".message-row--failed .message-bubble-self").exists()).toBe(true);
    const sent = setup({ contentType: "text", text: { text: "Hello" } }, true, "pc", { status: "sent" });
    expect(sent.find(".message-row--failed").exists()).toBe(false);
    // A failed status on someone else's message is not a state the core reports: it keeps the incoming palette.
    const peer = setup({ contentType: "text", text: { text: "Hello" } }, false, "pc", { status: "failed" });
    expect(peer.find(".message-row--failed").exists()).toBe(false);
  });

  it("keeps the failed glyph as the retry key inside a bubble, and inert without a listener", async () => {
    const onResend = vi.fn();
    const framed = setup({ contentType: "text", text: { text: "Hello" } }, true, "pc", { status: "failed" }, { onResend });
    await framed.findComponent(MessageMeta).get("button.status-failed").trigger("click");
    expect(onResend).toHaveBeenCalledWith("client-1");
    const passive = setup(contents[0], true, "pc", { status: "failed" });
    expect(passive.find("[data-meta-retry]").exists()).toBe(false);
    expect(passive.findComponent(MessageMeta).text()).toContain("发送失败");
  });

  it("shows the group read summary in place of the ticks and opens the receipts", async () => {
    const onReadReceiptOpen = vi.fn();
    const summary = { readCount: 2, unreadCount: 3, total: 5 };
    const bubble = setup({ contentType: "text", text: { text: "Hello" } }, true, "pc", { status: "sent", readSummary: summary }, { onReadReceiptOpen }, { conversationKind: "group" });
    const key = bubble.get("button[data-read-summary]");
    expect(key.text()).toBe("3 人未读");
    expect(bubble.findComponent(MessageMeta).find(".status-sent").exists()).toBe(false);
    await key.trigger("click");
    expect(onReadReceiptOpen).toHaveBeenCalledWith("client-1");
    const allRead = setup({ contentType: "text", text: { text: "Hello" } }, true, "pc", { status: "read", readSummary: { readCount: 5, unreadCount: 0, total: 5 } }, {}, { conversationKind: "group" });
    expect(allRead.get("[data-read-summary]").element.tagName).toBe("SPAN");
    expect(allRead.get("[data-read-summary]").text()).toBe("全部已读");
    const single = setup({ contentType: "text", text: { text: "Hello" } }, true, "pc", { status: "sent", readSummary: summary }, { onReadReceiptOpen }, { conversationKind: "single" });
    expect(single.find("[data-read-summary]").exists()).toBe(false);
  });
});

describe("multi-select and the row's reading unit", () => {
  it("makes the content inert and toggles the selection from anywhere on the row", async () => {
    const bubble = setup({ contentType: "text", text: { text: "Hello" } }, false, "pc", {}, {}, { multiSelectMode: true, selected: false });
    const body = bubble.get(".message-bubble-body");
    expect(body.classes()).toContain("message-bubble-body--inert");
    expect(body.attributes("inert")).toBeDefined();
    await bubble.get(".message-bubble").trigger("click");
    expect(bubble.emitted("toggle-select")).toEqual([["client-1"]]);
    await bubble.get(".message-select").trigger("click");
    expect(bubble.emitted("toggle-select")).toHaveLength(2);
  });

  it("names the row by sender, content summary, time and status", () => {
    const bubble = setup({ contentType: "text", data: { text: "好的" } }, true, "pc", { senderDisplayName: "我" });
    const label = bubble.get(".message-bubble").attributes("aria-label") ?? "";
    expect(label.startsWith("我，")).toBe(true);
    expect(label.endsWith("，已读")).toBe(true);
    expect(label.split("，")).toHaveLength(4);
  });
});
