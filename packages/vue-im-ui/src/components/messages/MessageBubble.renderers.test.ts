// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import FlareUiProvider from "../../design-system/provider/FlareUiProvider.vue";
import type { MessageLike } from "../../shared/contracts/messageRow";
import {
  provideFlareMessageRenderers,
  provideFlareRenderConversation,
  type FlareMessageRendererRegistry,
} from "../../shared/message-renderers";
import MessageBubble from "./MessageBubble.vue";
import MessageMeta from "./MessageMeta.vue";

/** A custom renderer that writes what it was told about its message into the DOM. */
const Probe = defineComponent({
  props: { messageId: String, conversationId: String },
  setup(props) {
    return () => h("div", { class: "probe", "data-message": props.messageId ?? "", "data-conversation": props.conversationId ?? "" }, "card");
  },
});

const hosts: ReturnType<typeof mount>[] = [];
afterEach(() => hosts.splice(0).forEach((host) => host.unmount()));

function setup(
  registry: FlareMessageRendererRegistry,
  extra: Partial<MessageLike> = {},
  listConversation?: string,
) {
  const message: MessageLike = {
    serverId: "server-1", clientMsgId: "client-1", senderId: "ivy", senderDisplayName: "Ivy",
    conversationSeq: 1, createdAt: 1_736_922_600_000, clientCreatedAt: 1_736_922_600_000, messageType: 1,
    content: { contentType: "custom", type: "packet", greeting: "Hi" }, status: "read", isRecalled: false, isRead: true,
    timelineKey: "message-1", timelineSortTs: 1, attributes: {}, ...extra,
  };
  const Host = defineComponent({
    setup() {
      provideFlareMessageRenderers(registry);
      if (listConversation) provideFlareRenderConversation(() => listConversation);
      return () => h(MessageBubble, { message, self: false, currentUserId: "me" });
    },
  });
  const host = mount(FlareUiProvider, {
    props: { layoutMode: "pc", themeMode: "light", locale: "zh-CN" },
    slots: { default: () => h(Host) },
  });
  hosts.push(host);
  return host.findComponent(MessageBubble);
}

describe("custom content renderers", () => {
  it("draws a renderer registered bare without the bubble, keeping the row's meta below it", () => {
    const bubble = setup({ "custom:packet": { component: Probe, bare: true } });
    expect(bubble.find(".probe").exists()).toBe(true);
    expect(bubble.find(".message-bubble--chromeless-media").exists()).toBe(true);
    expect(bubble.find(".message-bubble--chromeless-card").exists()).toBe(false);
    const meta = bubble.findComponent(MessageMeta);
    expect(meta.props("overlay")).toBe(false);
    expect(meta.props("tone")).toBe("default");
  });

  it("keeps the bubble for a renderer registered without bare, as a plain component or an entry", () => {
    for (const registry of [{ "custom:packet": Probe }, { "custom:packet": { component: Probe } }]) {
      const bubble = setup(registry);
      expect(bubble.find(".probe").exists()).toBe(true);
      expect(bubble.find(".message-bubble--chromeless-media").exists()).toBe(false);
      // A custom card keeps the kit's card framing (meta laid over the card) unless it asked to be bare.
      expect(bubble.find(".message-bubble--chromeless-card").exists()).toBe(true);
    }
  });

  it("keeps the bubble around a bare renderer when the message quotes another", () => {
    const bubble = setup({ "custom:packet": { component: Probe, bare: true } }, { quotePreview: "Earlier" });
    expect(bubble.find(".message-bubble--chromeless-media").exists()).toBe(false);
  });

  it("tells the renderer the server id and the row's conversation", () => {
    const probe = setup({ "custom:packet": Probe }, { conversationId: "conv-9" }).get(".probe");
    expect(probe.attributes("data-message")).toBe("server-1");
    expect(probe.attributes("data-conversation")).toBe("conv-9");
  });

  it("falls back to the client id, and to the list's conversation", () => {
    const probe = setup({ "custom:packet": Probe }, { serverId: "" }, "conv-list").get(".probe");
    expect(probe.attributes("data-message")).toBe("client-1");
    expect(probe.attributes("data-conversation")).toBe("conv-list");
  });

  it("resolves the most specific key first, the same way for the view and the bubble", () => {
    const Other = defineComponent({ setup: () => () => h("div", { class: "other" }) });
    const bubble = setup(
      { "custom:lucky": { component: Probe, bare: true }, custom: Other },
      { content: { contentType: "custom", type: "lucky" } },
    );
    expect(bubble.find(".probe").exists()).toBe(true);
    expect(bubble.find(".other").exists()).toBe(false);
    expect(bubble.find(".message-bubble--chromeless-media").exists()).toBe(true);
  });
});
