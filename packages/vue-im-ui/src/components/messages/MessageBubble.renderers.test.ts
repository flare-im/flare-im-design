// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick } from "vue";
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
import FlarePluginView from "./FlarePluginView.vue";

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
  it("draws a renderer registered as bare media without the bubble, keeping the row's meta below it", () => {
    const bubble = setup({ "custom:packet": { component: Probe, surface: "bareMedia" } });
    expect(bubble.find(".probe").exists()).toBe(true);
    expect(bubble.attributes("data-surface")).toBe("bareMedia");
    expect(bubble.find(".message-bubble--chromeless-media").exists()).toBe(true);
    expect(bubble.find(".message-bubble--chromeless-card").exists()).toBe(false);
    const meta = bubble.findComponent(MessageMeta);
    expect(meta.props("placement")).toBe("below");
    expect(meta.props("tone")).toBe("default");
  });

  it("draws every custom content as a card by default, as a plain component or an entry", () => {
    for (const registry of [{ "custom:packet": Probe }, { "custom:packet": { component: Probe } }, { "custom:packet": { component: Probe, surface: "card" as const } }]) {
      const bubble = setup(registry);
      expect(bubble.find(".probe").exists()).toBe(true);
      expect(bubble.attributes("data-surface")).toBe("card");
      expect(bubble.find(".message-bubble--chromeless-card").exists()).toBe(true);
      expect(bubble.findComponent(MessageMeta).props("placement")).toBe("below");
    }
  });

  it("keeps a quoted card a card, and puts quoted bare media back in a bubble", () => {
    expect(setup({ "custom:packet": Probe }, { quotePreview: "Earlier" }).attributes("data-surface")).toBe("card");
    const media = setup({ "custom:packet": { component: Probe, surface: "bareMedia" } }, { quotePreview: "Earlier" });
    expect(media.attributes("data-surface")).toBe("bubble");
    expect(media.find(".message-bubble--chromeless-media").exists()).toBe(false);
  });

  it("draws a card's quote inside the plugin card shell, not as a bubble", async () => {
    const Card = defineComponent({
      setup: () => () => h(FlarePluginView, { view: { available: true, title: "周五团建去哪儿？", fields: [], actions: [] } }),
    });
    const bubble = setup({ "custom:packet": Card }, { quotePreview: "Earlier", replyTo: "m-0" });
    await nextTick();
    expect(bubble.attributes("data-surface")).toBe("card");
    const quote = bubble.get("[data-card-quote]");
    expect(quote.text()).toBe("Earlier");
    expect(quote.element.closest(".flare-plugin-view")).not.toBeNull();
    expect(bubble.findAll("[data-card-quote]")).toHaveLength(1);
  });

  it("draws the quote on top of a card that has no quote slot", () => {
    const bubble = setup({ "custom:packet": Probe }, { quotePreview: "Earlier" });
    const quote = bubble.get("[data-card-quote]");
    expect(quote.text()).toBe("Earlier");
    expect(quote.element.tagName).toBe("DIV");
    expect(quote.element.nextElementSibling?.classList.contains("message-content-view") || bubble.find(".probe").exists()).toBe(true);
  });

  it("tells a renderer that its row is selecting", () => {
    const Selecting = defineComponent({
      props: { selectionMode: Boolean },
      setup: (props) => () => h("div", { class: "selecting", "data-selecting": String(props.selectionMode) }),
    });
    const Host = defineComponent({
      setup() {
        provideFlareMessageRenderers({ "custom:packet": Selecting });
        return () => h(MessageBubble, {
          message: {
            serverId: "s", clientMsgId: "c", senderId: "ivy", senderDisplayName: "Ivy", conversationSeq: 1, createdAt: 1, clientCreatedAt: 1,
            messageType: 1, content: { contentType: "custom", type: "packet" }, status: "read", isRecalled: false, isRead: true,
            timelineKey: "c", timelineSortTs: 1, attributes: {},
          } satisfies MessageLike,
          currentUserId: "me",
          multiSelectMode: true,
        });
      },
    });
    const host = mount(FlareUiProvider, { props: { layoutMode: "pc", themeMode: "light", locale: "zh-CN" }, slots: { default: () => h(Host) } });
    hosts.push(host);
    expect(host.get(".selecting").attributes("data-selecting")).toBe("true");
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
      { "custom:lucky": { component: Probe, surface: "bareMedia" }, custom: Other },
      { content: { contentType: "custom", type: "lucky" } },
    );
    expect(bubble.find(".probe").exists()).toBe(true);
    expect(bubble.find(".other").exists()).toBe(false);
    expect(bubble.find(".message-bubble--chromeless-media").exists()).toBe(true);
  });
});
