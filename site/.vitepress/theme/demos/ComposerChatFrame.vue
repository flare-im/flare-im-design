<script setup>
import FlareIcon from "flare-core-vue-im-ui/components/general/FlareIcon.vue";
import { computed, ref } from "vue";
import FlareChatHeader from "flare-core-vue-im-ui/components/messages/ChatConversationHeader.vue";
import FlareMessageList from "flare-core-vue-im-ui/components/messages/MessageList.vue";
import FlareComposer from "flare-core-vue-im-ui/components/composer/EnhancedComposer.vue";
import EmojiStickerPanel from "flare-core-vue-im-ui/components/composer/ComposerEmojiStickerPanel/index.vue";

// A real, interactive chat surface: kit ChatHeader + MessageList + Composer, all
// wired. Type & send → a real bubble; pick an emoji → inline in the next message;
// pick a sticker → a real sticker bubble; "+" opens the tenant attach menu.
const me = "me";
const base = Date.now() - 240000;
let seq = 0;
function textMsg({ self, name, text, ts, status = 2 }) {
  seq += 1;
  return {
    serverId: String(seq), clientMsgId: String(seq),
    senderId: self ? me : "ivy", senderDisplayName: self ? "" : (name ?? "Ivy Chen"),
    conversationSeq: seq, createdAt: ts ?? Date.now(), clientCreatedAt: ts ?? Date.now(),
    messageType: 1, content: { contentType: "text", text: { text } },
    status, isRecalled: false, isRead: true, timelineKey: String(seq), timelineSortTs: ts ?? Date.now(),
  };
}
function stickerMsg({ packageId, stickerId, url }) {
  seq += 1;
  const ts = Date.now();
  return {
    serverId: String(seq), clientMsgId: String(seq),
    senderId: me, senderDisplayName: "",
    conversationSeq: seq, createdAt: ts, clientCreatedAt: ts,
    messageType: 1, content: { contentType: "sticker", sticker: { packageId, stickerId, url } },
    status: 2, isRecalled: false, isRead: true, timelineKey: String(seq), timelineSortTs: ts,
  };
}

const messages = ref([
  textMsg({ name: "Ivy Chen", text: "新版输入框设计稿上传啦，帮忙看下～", ts: base }),
  textMsg({ self: true, text: "收到，我过一遍就给你反馈 👍", ts: base + 60000, status: 4 }),
  textMsg({ name: "Ivy Chen", text: "重点看下展开和加号菜单那块", ts: base + 120000 }),
]);

const draft = ref("");
const activePanel = ref(null);
const emojiTab = computed(() => (activePanel.value === "sticker" ? "sticker" : "emoji"));

const opLabels = {
  create_file: "文件", create_video: "视频", create_location: "位置", create_card: "名片",
  create_task: "任务", create_schedule: "日程", create_vote: "投票", create_link_card: "链接",
  create_image: "图片", create_mini_program: "小程序", create_thread_reply: "话题",
  create_notification: "通知", create_announcement: "公告",
};

function onSend(text) {
  const body = (text ?? draft.value).trim();
  if (!body) return;
  messages.value.push(textMsg({ self: true, text: body }));
  draft.value = "";
  activePanel.value = null;
}
function onInsertEmoji(key) {
  draft.value += `[${key}]`;
}
function onSendSticker(payload) {
  const pick = payload?.picks?.[0];
  if (pick) messages.value.push(stickerMsg(pick));
  activePanel.value = null;
}
function onBuild(op) {
  messages.value.push(textMsg({ self: true, text: `（发送了${opLabels[op] ?? op}）` }));
  activePanel.value = null;
}
</script>

<template>
  <div class="chat-frame">
    <FlareChatHeader back @back="() => {}">
      <template #identity>
        <div class="idy">
          <span class="idy__avatar" aria-hidden="true">I</span>
          <div class="idy__text">
            <strong>Ivy Chen</strong>
            <span class="sub">在线 · 设计评审组</span>
          </div>
        </div>
      </template>
      <template #actions>
        <span class="act"><FlareIcon name="search" :size="18" /></span>
        <span class="act"><FlareIcon name="phone" :size="18" /></span>
        <span class="act"><FlareIcon name="more" :size="18" /></span>
      </template>
    </FlareChatHeader>

    <div class="chat-frame__body">
      <FlareMessageList :messages="messages" current-user-id="me" conversation-type="single" />
    </div>

    <div v-if="activePanel === 'emoji' || activePanel === 'sticker'" class="chat-frame__panel">
      <EmojiStickerPanel
        :active-tab="emojiTab"
        @update:active-tab="(t) => (activePanel = t)"
        @insert-emoji="onInsertEmoji"
        @send-sticker="onSendSticker"
      />
    </div>

    <div class="chat-frame__composer">
      <FlareComposer
        v-model="draft"
        target-name="Ivy Chen"
        :active-panel="activePanel"
        @toggle-panel="(p) => (activePanel = p)"
        @send="onSend"
        @build="onBuild"
      />
    </div>
  </div>
</template>

<style scoped>
.chat-frame {
  display: flex;
  flex-direction: column;
  /* Fills the iframe viewport it's embedded in. */
  height: 100dvh;
  min-height: 0;
  background: var(--flare-color-bg-primary, #fff);
}
.chat-frame__body {
  flex: 1 1 auto;
  min-height: 0;
  overflow: hidden;
  background: var(--flare-color-bg-secondary, #f5f6f8);
  order: 0;
}
/* Emoji / sticker panel placement follows the platform convention:
   desktop → above the input (a popover-style tray); mobile → below the input
   (the keyboard-area tray). Driven by flex order + the viewport width. */
.chat-frame__panel {
  flex: 0 0 auto;
  border-top: 1px solid var(--flare-color-border-secondary, #e7e9ee);
  background: var(--flare-color-bg-primary, #fff);
  order: 1;
}
.chat-frame__composer {
  flex: 0 0 auto;
  order: 2;
}
@media (max-width: 899px) {
  .chat-frame__panel {
    order: 3;
    border-top: none;
    border-bottom: 1px solid var(--flare-color-border-secondary, #e7e9ee);
  }
}
.idy { display: flex; align-items: center; gap: 10px; }
.idy__avatar { display: grid; place-items: center; width: 40px; height: 40px; border-radius: 50%; background: var(--flare-color-primary, #7c3aed); color: #fff; font-weight: 700; font-size: 15px; }
.idy__text { display: flex; flex-direction: column; min-width: 0; }
.sub { font-size: 12px; color: var(--flare-color-text-tertiary); }
.act { font-size: 16px; opacity: 0.7; cursor: pointer; }
</style>
