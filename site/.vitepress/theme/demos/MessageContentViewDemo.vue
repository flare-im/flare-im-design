<script setup>
// Each message type is its own standalone component (clean props, freely
// composable). MessageContentView just dispatches to the right one by type —
// but you can drop any single one into your own layout.
import FlareTextMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareTextMessage.vue";
import FlareImageMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareImageMessage.vue";
import FlareVideoMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareVideoMessage.vue";
import FlareVoiceMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareVoiceMessage.vue";
import FlareFileMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareFileMessage.vue";
import FlareLocationMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareLocationMessage.vue";
import FlareContactMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareContactMessage.vue";
import FlareLinkCardMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareLinkCardMessage.vue";
import FlareVoteMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareVoteMessage.vue";
import FlareTaskMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareTaskMessage.vue";
import FlareStickerMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareStickerMessage.vue";
import FlareEmojiMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareEmojiMessage.vue";
import FlareSystemMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareSystemMessage.vue";
// The merged-forward body renders its nested messages recursively through the
// same content pipeline, so ContentView drives it directly from a content elem.
import ContentView from "flare-core-vue-im-ui/components/messages/MessagesView/ContentView.vue";
import DemoStage from "./DemoStage.vue";
import { defineComponent, h } from "vue";
import { useFlareNotificationProvider } from "flare-core-vue-im-ui/composables/useNotificationRenderer";

// Notifications are a host extension point: the kit renders a neutral line by
// default, but a product can inject a richer notice (here a call-signal tile)
// and hide variants it surfaces elsewhere (invite/accept live in the call UI).
const CallSignalTile = defineComponent({
  props: { payload: { type: Object, default: () => ({}) } },
  setup(props) {
    return () =>
      h("span", { class: "demo-call-tile" }, [
        h("span", { class: "demo-call-tile__dot" }),
        h("span", props.payload?.body || "通话已结束"),
      ]);
  },
});
useFlareNotificationProvider((payload) => {
  if (payload.notificationType !== "call_signal") return null;
  const variant = payload.data?.variant;
  if (variant === "invite" || variant === "accept") return false; // handled by call UI
  return CallSignalTile;
});

// Wire shape mirrors the SDK: the type payload lives under `data`; the kit
// normalizes it (flattened to root + nested under the type key) before dispatch.
// Each nested item's own `content` is `{ contentType, data }` too, so the drawer
// can render it recursively through the same pipeline.
const forwardContent = {
  contentType: "forward",
  data: {
    mode: 2,
    title: "这是上周设计评审的结论，请查收",
    items: [
      {
        sourceSenderName: "Ivy Chen",
        sourceMessageTimeMs: Date.now() - 3600_000,
        plainText: "气泡圆角统一到 16px，白描边接收气泡定稿。",
        content: { contentType: "text", data: { text: "气泡圆角统一到 16px，白描边接收气泡定稿。" } },
      },
      {
        sourceSenderName: "Leo Wang",
        sourceMessageTimeMs: Date.now() - 3000_000,
        plainText: "[位置] 字节跳动 · 三里屯",
        content: { contentType: "location", data: { title: "字节跳动 · 三里屯", address: "北京市朝阳区工人体育场北路" } },
      },
      {
        sourceSenderName: "Mia Zhao",
        sourceMessageTimeMs: Date.now() - 1800_000,
        plainText: "[文件] 设计规范 v2.pdf",
        content: { contentType: "file", data: { name: "设计规范 v2.pdf", size: 2_517_000, ext: "PDF" } },
      },
    ],
  },
};

// call_signal "ended" → the injected CallSignalTile; a generic notification →
// the default centered line; an "invite" variant → hidden by the resolver.
const callEndedContent = {
  contentType: "notification",
  data: { notificationType: "call_signal", body: "通话已结束 · 时长 03:21", data: { variant: "ended" } },
};
const genericNotificationContent = {
  contentType: "notification",
  data: { title: "系统通知", body: "群管理员已开启全员禁言" },
};
</script>

<template>
  <DemoStage>
  <div class="canvas">
    <div class="item"><span class="tag">&lt;FlareTextMessage&gt;</span>
      <FlareTextMessage text="带链接的文本消息，点 flare.im 查看详情。" />
    </div>
    <div class="item"><span class="tag">&lt;FlareImageMessage&gt;</span>
      <FlareImageMessage />
    </div>
    <div class="item"><span class="tag">&lt;FlareVideoMessage&gt;</span>
      <FlareVideoMessage duration="00:42" />
    </div>
    <div class="item"><span class="tag">&lt;FlareVoiceMessage&gt;</span>
      <FlareVoiceMessage :seconds="7" />
    </div>
    <div class="item"><span class="tag">&lt;FlareFileMessage&gt;</span>
      <FlareFileMessage name="设计规范 v2.pdf" size="2.4 MB" ext="PDF" />
    </div>
    <div class="item"><span class="tag">&lt;FlareLocationMessage&gt;</span>
      <FlareLocationMessage title="字节跳动 · 三里屯" address="北京市朝阳区工人体育场北路" />
    </div>
    <div class="item"><span class="tag">&lt;FlareContactMessage&gt;</span>
      <FlareContactMessage name="Ivy Chen" subtitle="@ivy_chen" />
    </div>
    <div class="item"><span class="tag">&lt;FlareLinkCardMessage&gt;</span>
      <FlareLinkCardMessage title="Flare IM Design — 跨端 IM UI 组件库" domain="flare.im" />
    </div>
    <div class="item"><span class="tag">&lt;FlareVoteMessage&gt;</span>
      <FlareVoteMessage title="周会时间投票" :options="[{ text: '周四 15:00', pct: 62 }, { text: '周五 10:00', pct: 38 }]" />
    </div>
    <div class="item"><span class="tag">&lt;FlareTaskMessage&gt;</span>
      <FlareTaskMessage title="整理评审结论并同步" meta="今天 18:00 截止 · 已完成" done />
    </div>
    <div class="item"><span class="tag">&lt;FlareStickerMessage&gt;</span>
      <FlareStickerMessage emoji="🐱" />
    </div>
    <div class="item"><span class="tag">&lt;FlareEmojiMessage&gt;</span>
      <FlareEmojiMessage emoji="🎉" />
    </div>
    <div class="item"><span class="tag">&lt;FlareSystemMessage&gt;</span>
      <FlareSystemMessage text="Ivy 撤回了一条消息" />
    </div>
    <div class="item"><span class="tag">&lt;ContentView&gt; forward</span>
      <ContentView :content="forwardContent" />
    </div>
    <div class="item"><span class="tag">notification · call (injected)</span>
      <ContentView :content="callEndedContent" />
    </div>
    <div class="item"><span class="tag">notification · default line</span>
      <ContentView :content="genericNotificationContent" />
    </div>
  </div>
  </DemoStage>
</template>

<style scoped>
.canvas { width: 100%; max-width: 520px; display: flex; flex-direction: column; gap: 12px; padding: 16px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.item { display: flex; align-items: center; gap: 12px; min-width: 0; }
.tag { width: 168px; flex: none; font-size: 11px; font-family: var(--vp-font-family-mono, monospace); color: var(--flare-color-text-tertiary); white-space: nowrap; }
.demo-call-tile { display: inline-flex; align-items: center; gap: 8px; padding: 6px 12px; border-radius: 999px; font-size: 12px; color: var(--flare-color-text-secondary); background: var(--flare-color-bg-tertiary, rgba(0,0,0,0.05)); border: 1px solid var(--flare-color-border, rgba(0,0,0,0.08)); }
.demo-call-tile__dot { width: 6px; height: 6px; border-radius: 50%; background: #12b76a; flex: none; }
@media (max-width: 640px) {
  .item { flex-direction: column; align-items: flex-start; gap: 4px; }
  .tag { width: auto; }
}
</style>
