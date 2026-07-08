<script setup>
import DemoIcon from "./DemoIcon.vue";
import { tint } from "./tint.js";
const thread = [
  { id: 1, kind: "system", text: "Ivy 加入了群聊" },
  { id: 2, self: false, name: "Ivy", ini: "I", av: tint("Ivy Chen"), text: "新版设计稿已经上传啦，帮忙看下～", time: "14:30" },
  { id: 3, self: true, text: "收到，我下午过一遍给你反馈 👍", time: "14:31" },
  { id: 4, self: true, text: "整体方向没问题", time: "14:32", status: "read" },
];
</script>

<template>
  <div class="canvas">
    <template v-for="m in thread" :key="m.id">
      <div v-if="m.kind === 'system'" class="sys">{{ m.text }}</div>
      <div v-else class="line" :class="{ self: m.self }">
        <div v-if="!m.self" class="av" :style="{ background: m.av.bg, color: m.av.fg }">{{ m.ini }}</div>
        <div class="col">
          <span v-if="!m.self" class="name">{{ m.name }}</span>
          <div class="bubble" :class="{ self: m.self }">
            <span class="text">{{ m.text }}</span>
            <span class="meta">
              {{ m.time }}
              <DemoIcon v-if="m.self && m.status === 'read'" name="checkDouble" :size="14" />
            </span>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
/* faint chat canvas so white received bubbles read as cards */
.canvas { width: 100%; max-width: 460px; display: flex; flex-direction: column; gap: 8px; padding: 16px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.sys { align-self: center; font-size: 12px; color: var(--flare-color-text-tertiary); background: var(--flare-color-bg-tertiary); padding: 4px 12px; border-radius: 999px; }
.line { display: flex; gap: 8px; align-items: flex-end; }
.line.self { justify-content: flex-end; }
.av { width: 32px; height: 32px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: 600; font-size: 13px; }
.col { display: flex; flex-direction: column; gap: 2px; max-width: 78%; }
.name { font-size: 12px; color: var(--flare-color-text-tertiary); }

/* Flare thread bubble: received = white card + hairline border + whisper lift */
.bubble {
  padding: 9px 14px;
  border-radius: 16px 16px 16px 4px;
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-secondary);
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
  color: var(--flare-color-text-primary);
  font-size: 15px;
  line-height: 1.45;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}
.bubble.self {
  background: var(--flare-color-bubble-self);
  border-color: transparent;
  color: #fff;
  border-radius: 16px 16px 4px 16px;
  align-items: flex-end;
}
.meta { display: flex; align-items: center; gap: 3px; font-size: 11px; margin-top: 3px; color: var(--flare-color-text-tertiary); }
.bubble.self .meta { color: rgba(255, 255, 255, 0.8); }
</style>
