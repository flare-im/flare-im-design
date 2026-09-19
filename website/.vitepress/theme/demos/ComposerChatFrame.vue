<script setup>
import { FlareIcon } from "@flare-im/vue-ui/components";
import { computed, ref } from "vue";
import { FlareConversationHeader } from "@flare-im/vue-ui/components";
import { FlareMessageList } from "@flare-im/vue-ui/components";
import { FlareComposer } from "@flare-im/vue-ui/components";
import { FlareEmojiStickerPicker as EmojiStickerPanel } from "@flare-im/vue-ui/components";

// A real, interactive chat surface: kit ChatHeader + MessageList + Composer, all
// wired. Type & send → a real bubble; pick an emoji → inline in the next message;
// pick a sticker → a real sticker bubble; "+" opens the tenant attach menu.
const me = "me";
const base = new Date(2025, 0, 15, 14, 26).getTime();
let seq = 0;
function textMsg({ self, name, text, ts, status = "sent" }) {
  seq += 1;
  return {
    serverId: String(seq), clientMsgId: String(seq),
    senderId: self ? me : "ivy", senderDisplayName: self ? "" : (name ?? "Ivy Chen"),
    conversationSeq: seq, createdAt: ts ?? Date.now(), clientCreatedAt: ts ?? Date.now(),
    messageType: 1, content: { contentType: "text", text: { text } },
    status, isRecalled: false, isRead: true, timelineKey: String(seq), timelineSortTs: ts ?? Date.now(),
    attributes: {},
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
    status: "sent", isRecalled: false, isRead: true, timelineKey: String(seq), timelineSortTs: ts,
    attributes: {},
  };
}

const messages = ref([
  textMsg({ name: "Ivy Chen", text: "新版输入框设计稿上传啦，帮忙看下～", ts: base }),
  textMsg({ name: "Ivy Chen", text: "另外配色也换成新的品牌紫了", ts: base + 20000 }),
  textMsg({ self: true, text: "收到，我过一遍就给你反馈 👍", ts: base + 60000, status: "read" }),
  textMsg({ name: "Ivy Chen", text: "重点看下展开和加号菜单那块", ts: base + 120000 }),
]);

const draft = ref("");
const richMode = ref(false);
const composerRef = ref(null);
const fileInput = ref(null);
const mode = ref("normal");
const showSearch = ref(false);
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
  composerRef.value?.insertAtCursor(`[${key}]`);
}
function onSendSticker(payload) {
  const pick = payload?.picks?.[0];
  if (pick) messages.value.push(stickerMsg(pick));
  activePanel.value = null;
}
function onSendVoice() {
  messages.value.push(textMsg({ self: true, text: "（发送了语音）" }));
  activePanel.value = null;
}
function onBuild(op) {
  if (op === "create_image") { fileInput.value?.click(); return; }
  messages.value.push(textMsg({ self: true, text: `（发送了${opLabels[op] ?? op}）` }));
  activePanel.value = null;
}
</script>

<template>
  <div class="chat-frame">
    <FlareConversationHeader :identity="{ id: 'ivy', title: 'Ivy Chen', subtitle: '在线 · 设计评审组', kind: 'direct', presence: 'online' }" show-back @back="() => {}">
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
    </FlareConversationHeader>

    <div class="chat-frame__controls">
      <label>输入状态 <select v-model="mode"><option value="normal">正常</option><option value="offline">离线</option><option value="muted">禁言</option></select></label>
      <label><input v-model="showSearch" type="checkbox" />更多搜索 / 关闭</label>
      <span>本地组件演示</span>
    </div>
    <div class="chat-frame__body">
      <FlareMessageList :has-older="false" :messages="messages" current-user-id="me" conversation-kind="single" />
    </div>

    <div class="chat-frame__composer">
      <FlareComposer
        ref="composerRef"
        toolbar-presentation="expanded"
        @send-voice="onSendVoice"
        :rich-mode="richMode"
        :read-only="mode === 'muted'"
        :send-blocked="mode === 'offline'"
        :status-hint="mode === 'muted' ? '你已被禁言，草稿已保留' : mode === 'offline' ? '连接已断开，暂不可发送' : ''"
        :more-search-visible="showSearch"
        :more-close-visible="showSearch"
        :mention-candidates="[{ userId: 'ivy', label: 'Ivy Chen' }, { userId: 'lin', label: '林小满' }]"
        @toggle-rich-mode="richMode = $event"
        v-model="draft"
        target-name="Ivy Chen"
        :active-panel="activePanel"
        @toggle-panel="(p) => (activePanel = p)"
        @send="onSend"
        @build="onBuild"
      >
        <template #media-panel>
          <EmojiStickerPanel :active-tab="emojiTab" :show-send-button="false" :disabled="mode !== 'normal'"
            @update:active-tab="activePanel = $event" @insert-emoji="onInsertEmoji" @send-sticker="onSendSticker" />
        </template>
      </FlareComposer>
      <input ref="fileInput" type="file" accept="image/*" multiple hidden />
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
.chat-frame__composer { flex: 0 0 auto; }
.chat-frame__controls { display: flex; flex-wrap: wrap; gap: 12px; padding: 8px 12px; font-size: 12px; color: var(--flare-color-text-secondary); }
.idy { display: flex; align-items: center; gap: 10px; }
.idy__avatar { display: grid; place-items: center; width: 40px; height: 40px; border-radius: 50%; background: var(--flare-color-primary, #7c3aed); color: #fff; font-weight: 700; font-size: 15px; }
.idy__text { display: flex; flex-direction: column; min-width: 0; }
.sub { font-size: 12px; color: var(--flare-color-text-tertiary); }
.act { font-size: 16px; opacity: 0.7; cursor: pointer; }
</style>
