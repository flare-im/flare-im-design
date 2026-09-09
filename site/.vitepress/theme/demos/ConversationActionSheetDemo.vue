<script setup>
import { computed, ref } from "vue";
import FlareConversationActionSheet from "@flare-im/vue-ui/components/conversation/FlareConversationActionSheet.vue";
import FlareBottomSheet from "@flare-im/vue-ui/components/general/FlareBottomSheet.vue";
import DemoStage from "./DemoStage.vue";

const conversation = ref({ id: "conv-1", title: "设计评审 · 移动端周会", pinned: false, muted: false, unreadCount: 3, archived: false });
const caps = ref({ pin: true, mute: true, markRead: true, archive: true, hide: true, delete: true });
const busy = ref(false);
const sheetOpen = ref(false);
const last = ref("尚未操作");
const capKeys = ["pin", "mute", "markRead", "archive", "hide", "delete"];

function apply({ id, action }) {
  last.value = `action：${id}/${action}`;
  busy.value = true;
  // Host applies the command; the snapshot flips only after the SDK confirms.
  setTimeout(() => {
    const c = conversation.value;
    if (action === "pin" || action === "unpin") c.pinned = action === "pin";
    if (action === "mute" || action === "unmute") c.muted = action === "mute";
    if (action === "markRead") c.unreadCount = 0;
    if (action === "archive" || action === "unarchive") c.archived = action === "archive";
    busy.value = false;
    sheetOpen.value = false;
  }, 600);
}
function reset() {
  conversation.value = { id: "conv-1", title: "设计评审 · 移动端周会", pinned: false, muted: false, unreadCount: 3, archived: false };
  caps.value = { pin: true, mute: true, markRead: true, archive: true, hide: true, delete: true };
  busy.value = false;
  last.value = "尚未操作";
}
const stateSummary = computed(() => {
  const c = conversation.value;
  return [c.pinned ? "已置顶" : "未置顶", c.muted ? "免打扰" : "通知开", `未读 ${c.unreadCount}`, c.archived ? "已归档" : "未归档"].join(" · ");
});
</script>

<template>
  <DemoStage>
    <div class="cas-demo">
      <div class="cas-demo__split">
        <div class="cas-demo__col">
          <div class="cas-demo__cap">桌面 · 右键 / 更多 popover 内容</div>
          <div class="cas-demo__popover">
            <FlareConversationActionSheet
              :conversation="conversation"
              :capabilities="caps"
              :busy="busy"
              @action="apply"
              @close="last = 'close'"
            />
          </div>
        </div>
        <div class="cas-demo__col">
          <div class="cas-demo__cap">移动端 · 长按 → FlareBottomSheet</div>
          <button type="button" class="cas-demo__row" @click="sheetOpen = true">
            <span class="cas-demo__row-title">{{ conversation.title }}</span>
            <span class="cas-demo__row-sub">{{ stateSummary }}</span>
          </button>
          <FlareBottomSheet :open="sheetOpen" @close="sheetOpen = false">
            <FlareConversationActionSheet
              :conversation="conversation"
              :capabilities="caps"
              :busy="busy"
              @action="apply"
              @close="sheetOpen = false"
            />
          </FlareBottomSheet>
        </div>
      </div>

      <div class="cas-demo__controls">
        <label v-for="k in capKeys" :key="k"><input v-model="caps[k]" type="checkbox" /> {{ k }}</label>
        <label><input v-model="busy" type="checkbox" /> busy</label>
        <button type="button" @click="conversation.unreadCount = conversation.unreadCount ? 0 : 3">切换未读</button>
        <button type="button" @click="reset">重置演示</button>
      </div>
      <p role="status">{{ last }}。{{ stateSummary }}。本地模拟，不触发 SDK。</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.cas-demo { width: 100%; min-width: 0; display: grid; gap: 16px; }
.cas-demo__split { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 20px; align-items: start; }
@media (max-width: 720px) { .cas-demo__split { grid-template-columns: 1fr; } }
.cas-demo__cap { margin-bottom: 8px; font-size: 12px; font-weight: 600; color: var(--flare-color-text-tertiary); }
.cas-demo__popover {
  max-width: 320px;
  border: 1px solid var(--flare-color-border-primary);
  border-radius: 14px;
  background: var(--flare-color-bg-primary);
  box-shadow: var(--flare-shadow-md);
}
.cas-demo__row {
  display: grid;
  gap: 4px;
  width: 100%;
  min-height: 48px;
  padding: 12px 14px;
  border: 1px solid var(--flare-color-border-primary);
  border-radius: 12px;
  background: var(--flare-color-bg-primary);
  color: var(--flare-color-text-primary);
  text-align: start;
  cursor: pointer;
  font: inherit;
}
.cas-demo__row-title { font-weight: 600; }
.cas-demo__row-sub { font-size: 12px; color: var(--flare-color-text-secondary); }
.cas-demo__controls { display: flex; flex-wrap: wrap; gap: 8px 14px; align-items: center; font-size: 13px; }
.cas-demo__controls button { min-height: 40px; padding: 6px 12px; border: 1px solid var(--flare-color-border-primary); border-radius: 8px; background: var(--flare-color-bg-primary); color: inherit; }
p { font-size: 13px; overflow-wrap: anywhere; }
</style>
