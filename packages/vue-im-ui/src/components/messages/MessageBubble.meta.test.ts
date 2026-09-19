// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { h } from "vue";
import { afterEach, describe, expect, it } from "vitest";
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

function setup(content: MessageLike["content"], self = true, layoutMode: "pc" | "h5" = "pc", extra: Partial<MessageLike> = {}) {
  const message: MessageLike = {
    serverId: "server-1", clientMsgId: "client-1", senderId: self ? "me" : "ivy",
    senderDisplayName: "Ivy", conversationSeq: 1, createdAt: 1_736_922_600_000,
    clientCreatedAt: 1_736_922_600_000, messageType: 1, content, status: "read",
    isRecalled: false, isRead: true, timelineKey: "message-1", timelineSortTs: 1,
    attributes: {}, ...extra,
  };
  const host = mount(FlareUiProvider, {
    props: { layoutMode, themeMode: "light", locale: "zh-CN" },
    slots: { default: () => h(MessageBubble, { message, self, currentUserId: "me" }) },
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
        expect(meta.props("overlay")).toBe(false);
        expect(meta.props("tone")).toBe("default");
        expect(meta.props("status")).toBe(self ? "read" : undefined);
        expect(bubble.get(".message-bubble-body").element.nextElementSibling).toBe(meta.element);
      });
    }
  }

  it("keeps outgoing text, voice, and quoted media on their bubble palette", () => {
    for (const content of [{ contentType: "text", text: { text: "Hello" } }, { contentType: "voice", voice: { url: "/voice.webm" } }]) {
      expect(setup(content).findComponent(MessageMeta).props("tone")).toBe("onOutgoing");
    }
    const quoted = setup(contents[0], true, "pc", { quotePreview: "A reference" });
    expect(quoted.findComponent(MessageMeta).props("tone")).toBe("onOutgoing");
    expect(quoted.findComponent(MessageMeta).props("overlay")).toBe(false);
  });

  it("preserves edited, ephemeral, and failed-send retry semantics", async () => {
    const bubble = setup(contents[2], true, "h5", {
      status: "failed", isEdited: true, attributes: { ephemeralState: "readOnce" },
    });
    const meta = bubble.findComponent(MessageMeta);
    expect(meta.text()).toContain("已编辑");
    expect(meta.props("ephemeral")).toBe("readOnce");
    const enter = new KeyboardEvent("keydown", { key: "Enter", bubbles: true, cancelable: true });
    meta.get("button.status-failed").element.dispatchEvent(enter);
    expect(enter.defaultPrevented).toBe(false);
    await meta.get("button.status-failed").trigger("click");
    expect(bubble.emitted("resend")).toEqual([["client-1"]]);
  });
});
