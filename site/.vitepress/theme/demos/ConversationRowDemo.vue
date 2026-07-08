<script setup>
import { tint } from "./tint.js";
import DemoIcon from "./DemoIcon.vue";
const item = {
  id: "u2", title: "Ivy Chen", initials: "IC",
  preview: "好的，那我们明天上午同步一下 👍", time: "14:32", unread: 3, pinned: true,
};
const av = tint(item.title);
</script>

<template>
  <div class="row" :class="{ pinned: item.pinned }">
    <div class="av" :style="{ background: av.bg, color: av.fg }">{{ item.initials }}</div>
    <div class="body">
      <div class="line1">
        <span class="title">{{ item.title }}</span>
        <span class="time">{{ item.time }}</span>
      </div>
      <div class="line2">
        <span class="preview">{{ item.preview }}</span>
        <span v-if="item.unread" class="badge">{{ item.unread }}</span>
      </div>
    </div>
    <span v-if="item.pinned" class="pin" title="已置顶"><DemoIcon name="pin" :size="15" /></span>
  </div>
</template>

<style scoped>
.row { position: relative; display: flex; gap: 12px; align-items: center; width: 100%; max-width: 420px; padding: 10px 12px; border-radius: 10px; background: var(--flare-color-bg-primary); }
.row.pinned { padding-right: 40px; }
/* pin marker — matches the shipped FlareConversationRow: soft purple tile + purple glyph */
.pin { position: absolute; bottom: 8px; right: 8px; display: grid; place-items: center; width: 28px; height: 28px; border-radius: 8px; color: var(--flare-color-primary); border: 1px solid color-mix(in srgb, var(--flare-color-primary) 22%, transparent); background: color-mix(in srgb, var(--flare-color-primary) 10%, var(--flare-color-bg-primary)); }
.av { width: 48px; height: 48px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: 600; }
.body { flex: 1; min-width: 0; }
.line1 { display: flex; justify-content: space-between; align-items: baseline; }
.title { font-weight: 700; color: var(--flare-color-text-primary); }
.time { font-size: 12px; color: var(--flare-color-text-tertiary); }
.line2 { display: flex; justify-content: space-between; align-items: center; margin-top: 4px; }
.preview { color: var(--flare-color-text-secondary); font-size: 14px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.badge { background: var(--flare-color-primary); color: #fff; font-size: 11px; font-weight: 600; min-width: 20px; height: 20px; border-radius: 999px; display: flex; align-items: center; justify-content: center; padding: 0 6px; }
</style>
