<script setup>
import DemoIcon from "./DemoIcon.vue";
import { tint } from "./tint.js";
const rows = [
  { id: "u1", title: "Henry Ford", ini: "HF", preview: "收到，稍后处理", time: "14:32", unread: 2, active: true, pinned: true },
  { id: "u2", title: "产品设计群", ini: "产", preview: "Ivy: 新版切图已上传 🎨", time: "13:05", unread: 0, muted: true },
  { id: "u3", title: "Kai Wang", ini: "KW", preview: "[草稿] 明天的评审", time: "昨天", unread: 0, draft: true },
].map((r) => ({ ...r, av: tint(r.title) }));
</script>

<template>
  <div class="list">
    <div v-for="r in rows" :key="r.id" class="row" :class="{ active: r.active, pinned: r.pinned }">
      <div class="av" :style="{ background: r.av.bg, color: r.av.fg }">{{ r.ini }}</div>
      <div class="body">
        <div class="line1">
          <span class="title" :style="{ fontWeight: r.unread ? 700 : 600 }">{{ r.title }}</span>
          <span class="time">{{ r.time }}</span>
        </div>
        <div class="line2">
          <span class="preview">
            <DemoIcon v-if="r.muted" name="bellOff" :size="13" class="mute" />
            <span v-if="r.draft" class="draft">[草稿] </span>{{ r.preview.replace('[草稿] ', '') }}
          </span>
          <span v-if="r.unread" class="badge">{{ r.unread }}</span>
        </div>
      </div>
      <span v-if="r.pinned" class="pin" title="已置顶"><DemoIcon name="pin" :size="14" /></span>
    </div>
  </div>
</template>

<style scoped>
.list { width: 100%; max-width: 440px; border: 1px solid var(--flare-color-border-primary); border-radius: 12px; overflow: hidden; background: var(--flare-color-bg-primary); }
.row { position: relative; display: flex; gap: 12px; align-items: center; padding: 12px; cursor: pointer; }
.row + .row { border-top: 1px solid var(--flare-color-border-secondary); }
.row.active { background: var(--flare-color-bg-selected); }
.row.pinned { padding-right: 40px; }
.pin { position: absolute; bottom: 10px; right: 12px; display: grid; place-items: center; width: 26px; height: 26px; border-radius: 8px; color: var(--flare-color-primary); border: 1px solid color-mix(in srgb, var(--flare-color-primary) 22%, transparent); background: color-mix(in srgb, var(--flare-color-primary) 10%, var(--flare-color-bg-primary)); }
.av { width: 46px; height: 46px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: 600; }
.body { flex: 1; min-width: 0; }
.line1 { display: flex; justify-content: space-between; align-items: baseline; }
.title { color: var(--flare-color-text-primary); }
.time { font-size: 12px; color: var(--flare-color-text-tertiary); }
.line2 { display: flex; justify-content: space-between; align-items: center; margin-top: 4px; gap: 8px; }
.preview { display: flex; align-items: center; gap: 4px; color: var(--flare-color-text-secondary); font-size: 14px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.draft { color: var(--flare-color-error); font-weight: 500; }
.mute { color: var(--flare-color-text-tertiary); }
.badge { background: var(--flare-color-primary); color: #fff; font-size: 11px; font-weight: 600; min-width: 20px; height: 20px; border-radius: 999px; display: flex; align-items: center; justify-content: center; padding: 0 6px; }
</style>
