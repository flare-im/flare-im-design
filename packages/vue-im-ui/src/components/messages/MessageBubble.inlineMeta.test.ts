// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { h } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import FlareUiProvider from "../../design-system/provider/FlareUiProvider.vue";
import type { MessageLike } from "../../shared/contracts/messageRow";
import MessageBubble from "./MessageBubble.vue";

const hosts: ReturnType<typeof mount>[] = [];

function setup(content: MessageLike["content"], self: boolean, layoutMode: "pc" | "h5" = "pc") {
  const message: MessageLike = {
    serverId: "server-1", clientMsgId: "client-1", senderId: self ? "me" : "ivy",
    senderDisplayName: "Ivy", conversationSeq: 1, createdAt: 1_736_922_600_000,
    clientCreatedAt: 1_736_922_600_000, messageType: 1, content, status: "read",
    isRecalled: false, isRead: true, timelineKey: "message-1", timelineSortTs: 1,
    attributes: {},
  };
  const host = mount(FlareUiProvider, {
    props: { layoutMode, themeMode: "light", locale: "zh-CN" },
    slots: { default: () => h(MessageBubble, { message, self, currentUserId: "me" }) },
    global: { stubs: { MessageContentView: { template: '<div class="test-body">Body</div>' } } },
  });
  hosts.push(host);
  return host.findComponent(MessageBubble);
}

afterEach(() => hosts.splice(0).forEach(host => host.unmount()));

/**
 * 时间戳与状态跟在正文右侧，而不是自己另起一行。
 *
 * 气泡里是两个兄弟：`.message-bubble-body` 和 `footer.message-meta-row`。气泡原本是
 * 块级，于是每条消息的时间戳都独占一行 —— 实测一条两行的中文消息 42px 正文 +
 * 16px 时间戳 + 内距 = 79px，约四分之一高度花在只写着「21:15」的一行上；接上以后是 62px。
 *
 * 这套机制 kit 里本来就有（`.bubble-inline-status` 那一族样式），但没有任何组件加过
 * 对应的类 —— 是写完没接上的死样式。这里钉住它确实被加上，而且只加在纯文本上。
 */
describe("文本气泡把时间戳排在正文末行右侧", () => {
  const text: MessageLike["content"] = { contentType: "text", text: { text: "你好" } };

  for (const self of [false, true]) {
    it(`收发两侧都内联，self=${self}`, () => {
      const bubble = setup(text, self);
      expect(bubble.find(".message-bubble--inline-meta").exists()).toBe(true);
    });
  }

  it("媒体不内联：它有自己的排版，把 meta 塞进行尾会挤坏", () => {
    const bubble = setup({ contentType: "image", image: { url: "/photo.webp" } }, true);
    expect(bubble.find(".message-bubble--inline-meta").exists()).toBe(false);
  });

  it("h5 与 pc 同一条规则：这不是某一端的排版特例", () => {
    expect(setup(text, false, "h5").find(".message-bubble--inline-meta").exists()).toBe(true);
  });
});
