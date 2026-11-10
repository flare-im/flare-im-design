import { createApp, defineComponent, h } from "vue";
import FlareRedPacketCard from "../../../packages/vue-im-ui/src/components/messages/FlareRedPacketCard.vue";
import FlareCallRecordCard from "../../../packages/vue-im-ui/src/components/call/FlareCallRecordCard.vue";
import FlarePluginView from "../../../packages/vue-im-ui/src/components/messages/FlarePluginView.vue";
import financial from "../../../spec/financial-presentation-vectors.json";
import { useFlareI18nProvider } from "../../../packages/vue-im-ui/src/shared/i18n/useFlareI18n";
import { provideFlareMessageRenderers } from "../../../packages/vue-im-ui/src/shared/message-renderers";
import MessageBubble from "../../../packages/vue-im-ui/src/components/messages/MessageBubble.vue";
import { useViewportProvider } from "../../../packages/vue-im-ui/src/composables/useViewport";

/** Deliberately stretched parents reproduce the constraint that widened Flutter envelopes. */
export function mountCardSizingFixture(width: number) {
  const host = document.createElement("div");
  host.id = "message-card-sizing-fixture";
  host.style.cssText = `width:${width}px;max-width:100%;display:flex;flex-direction:column;gap:24px;padding:0;background:var(--flare-color-bg-secondary)`;
  document.body.replaceChildren(host);
  const row = (name: string, child: ReturnType<typeof h>) => h("section", {
    "data-sizing": name,
    style: "display:flex;flex-direction:column;align-items:stretch;min-width:0;container:flare-timeline / inline-size",
  }, [h("div", {
    class: "message-list",
    style: "display:flex;flex-direction:column;align-items:stretch;width:100%;height:auto;min-height:0;overflow:visible;padding:0",
  }, [child])]);
  createApp({ setup() {
    useFlareI18nProvider("zh-CN");
    useViewportProvider();
    provideFlareMessageRenderers({ "custom:sizing-packet": defineComponent({
      setup: () => () => h(FlarePluginView, { view: financial.card }),
    }) });
    const timelinePacket = (self: boolean, quoted = false) => row(`timeline-${self ? "outgoing" : "incoming"}${quoted ? "-quoted" : ""}`, h(MessageBubble, {
      message: {
        serverId: `packet-${self}`, clientMsgId: `packet-${self}`, senderId: self ? "me" : "ivy",
        senderDisplayName: "Ivy", createdAt: 1_736_922_600_000, clientCreatedAt: 1_736_922_600_000,
        content: { contentType: "custom", type: "sizing-packet" }, status: "sent", isRead: true,
        timelineKey: `packet-${self}`, timelineSortTs: 1, attributes: {},
        ...(quoted ? { quotePreview: "Earlier message with a long summary", replyTo: "earlier" } : {}),
      },
      currentUserId: "me", self, conversationKind: "single", groupPosition: "single",
      rowPresentation: { showAvatar: !self, reserveAvatarSpace: !self, showSenderName: false, avatarPlacement: "leading", tail: true },
      onReply: () => undefined,
    }));
    return () => [
    row("packet", h(FlareRedPacketCard, { blessing: "恭喜发财，大吉大利", kind: "exclusive", recipientName: "A very long recipient name", state: "finished" })),
    row("resolved-packet", h(FlarePluginView, { view: financial.card })),
    row("plugin", h(FlarePluginView, { view: { available: true, title: "A long plugin title that wraps safely", fields: [{ label: "Status", value: "Ready" }], blocks: [], actions: [] } })),
    row("call", h(FlareCallRecordCard, { media: "video", scope: "single", state: "ended", durationSeconds: 30, viewerIsInitiator: true, canJoin: false, canCallBack: true })),
    timelinePacket(false), timelinePacket(true), timelinePacket(false, true), timelinePacket(true, true),
    ];
  } }).mount(host);
}
