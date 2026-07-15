<script setup>
// Message actions are platform-split, so the demo shows BOTH:
//  · Desktop — real FlareMessageBubble; hover reveals the [react · reply · more] bar.
//  · Mobile  — the real MessageContextMenuSheet (what a long-press pops up), shown open.
import FlareMessageBubble from "flare-core-vue-im-ui/components/messages/MessageBubble.vue";
import MessageContextMenuSheet from "flare-core-vue-im-ui/components/messages/MessageContextMenuSheet.vue";
import { buildMessageContextSheetModel } from "flare-core-vue-im-ui/utils/buildMessageMenuOptions";
import DemoStage from "./DemoStage.vue";

const me = "me";
const base = Date.now() - 120000;
function msg({ id, self, senderId, name, text, ts, status = 2 }) {
  return {
    serverId: String(id), clientMsgId: String(id),
    senderId: self ? me : senderId, senderDisplayName: name ?? "",
    conversationSeq: id, createdAt: ts, clientCreatedAt: ts, messageType: 1,
    content: { contentType: "text", text: { text } },
    status, isRecalled: false, isRead: true, timelineKey: String(id), timelineSortTs: ts,
  };
}
const thread = [
  { m: msg({ id: 2, senderId: "ivy", name: "Ivy", text: "新版设计稿已经上传啦，帮忙看下～", ts: base }), self: false, gs: true, ge: true },
  { m: msg({ id: 3, self: true, text: "收到，我下午过一遍给你反馈 👍", ts: base + 1000, status: 4 }), self: true, gs: true, ge: true },
];
// A self message → the sheet shows reply/forward/recall + mark/pin/copy/edit/delete.
const sheetMsg = msg({ id: 3, self: true, text: "收到，我下午过一遍给你反馈 👍", ts: base + 1000, status: 4 });
const sheetModel = buildMessageContextSheetModel(sheetMsg, me);
</script>

<template>
  <DemoStage>
    <div class="mas">
      <p class="mas__hint">
        <strong>桌面</strong>：鼠标悬停任意气泡 → 出现 <em>表情反应 · 回复 · 更多</em> 三个快捷键，其余操作点「更多」展开。
        <strong>移动端</strong>：长按气泡 → 底部弹出操作 sheet（右图为展开后的样子）。
      </p>

      <div class="mas__split">
        <div class="mas__col">
          <div class="mas__cap"><span class="mas__dot mas__dot--pc" />桌面 · 悬停三键条</div>
          <div class="mas__canvas">
            <FlareMessageBubble
              v-for="(row, i) in thread"
              :key="i"
              :message="row.m"
              current-user-id="me"
              :self="row.self"
              conversation-type="group"
              :group-start="row.gs"
              :group-end="row.ge"
            />
          </div>
        </div>

        <div class="mas__col">
          <div class="mas__cap"><span class="mas__dot mas__dot--app" />移动端 · 长按 sheet</div>
          <div class="mas__phone">
            <div class="mas__phone-msg">收到，我下午过一遍给你反馈 👍</div>
            <MessageContextMenuSheet :model="sheetModel" />
          </div>
        </div>
      </div>
    </div>
  </DemoStage>
</template>

<style scoped>
.mas { width: 100%; }
.mas__hint {
  margin: 0 0 14px;
  padding: 10px 14px;
  font-size: 13px;
  line-height: 1.7;
  color: var(--flare-color-text-secondary);
  background: var(--flare-color-bg-secondary);
  border-radius: 10px;
}
.mas__hint em { color: var(--flare-color-primary); font-style: normal; font-weight: 600; }
.mas__split {
  display: grid;
  grid-template-columns: 1fr 300px;
  gap: 20px;
  align-items: start;
}
@media (max-width: 720px) {
  .mas__split { grid-template-columns: 1fr; }
}
.mas__cap {
  display: flex;
  align-items: center;
  gap: 7px;
  margin-bottom: 8px;
  font-size: 12px;
  font-weight: 600;
  color: var(--flare-color-text-tertiary);
}
.mas__dot { width: 8px; height: 8px; border-radius: 2px; background: var(--flare-color-primary); opacity: 0.7; }
.mas__dot--app { border-radius: 3px; width: 6px; height: 10px; }
.mas__canvas {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 20px 16px;
  border-radius: 14px;
  background: var(--flare-color-bg-secondary);
}
.mas__phone {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 16px 12px 12px;
  border-radius: 24px;
  background: var(--flare-color-bg-secondary);
  border: 1px solid var(--flare-color-border-primary);
}
.mas__phone-msg {
  align-self: flex-end;
  max-width: 78%;
  padding: 8px 12px;
  border-radius: 14px;
  background: var(--flare-color-primary);
  color: #fff;
  font-size: 14px;
}
</style>
