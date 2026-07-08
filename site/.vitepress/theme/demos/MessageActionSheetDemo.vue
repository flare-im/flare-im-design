<script setup>
import { ref } from "vue";
import DemoIcon from "./DemoIcon.vue";
// Mirrors the reference app's message long-press sheet (message_long_press_menu.dart):
// a light-grey canvas with floating white cards — a reaction strip, a detached
// quick-action row, then grouped list cards, delete in red.
const last = ref("");
const reactions = ["👍", "❤️", "😂", "🎉", "🙏", "😮"];
const quick = [
  { k: "reply", label: "回复", icon: "reply" },
  { k: "forward", label: "转发", icon: "forward" },
  { k: "recall", label: "撤回", icon: "undo" },
];
const groups = [
  [
    { k: "multi", label: "多选", icon: "checklist" },
    { k: "mark", label: "标记", icon: "flag" },
  ],
  [
    { k: "pin", label: "置顶消息", icon: "pinTop" },
    { k: "pinSelf", label: "仅自己置顶", icon: "pin" },
  ],
  [
    { k: "copy", label: "复制", icon: "copy" },
    { k: "edit", label: "编辑", icon: "edit" },
  ],
  [{ k: "delete", label: "删除", icon: "trash", danger: true }],
];
</script>

<template>
  <div class="sheet">
    <!-- reaction strip -->
    <div class="card strip">
      <button v-for="r in reactions" :key="r" class="emoji" @click="last = r">{{ r }}</button>
      <button class="more" title="更多表情" @click="last = '更多表情'">
        <DemoIcon name="moreHoriz" :size="20" />
      </button>
    </div>

    <!-- detached quick actions -->
    <div class="quick">
      <button v-for="q in quick" :key="q.k" class="card qtile" @click="last = q.label">
        <DemoIcon :name="q.icon" :size="22" />
        <span>{{ q.label }}</span>
      </button>
    </div>

    <!-- grouped list cards -->
    <div v-for="(g, gi) in groups" :key="gi" class="card list">
      <button
        v-for="row in g" :key="row.k"
        class="row" :class="{ danger: row.danger }"
        @click="last = row.label"
      >
        <DemoIcon :name="row.icon" :size="20" class="ric" />
        <span class="rlabel">{{ row.label }}</span>
      </button>
    </div>

    <div class="echo">{{ last ? `已选择：${last}` : "在灰色画布上点任一操作" }}</div>
  </div>
</template>

<style scoped>
/* light-grey canvas; cards float with 6px gaps (reference: #F2F3F5 canvas) */
.sheet {
  width: 100%;
  max-width: 340px;
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 8px;
  border-radius: 14px;
  background: var(--flare-color-bg-tertiary);
}
.card {
  background: var(--flare-color-bg-primary);
  border-radius: 10px;
}

/* reaction strip */
.strip {
  display: flex;
  align-items: center;
  gap: 2px;
  padding: 6px;
}
.emoji {
  flex: 1;
  height: 38px;
  border: none;
  background: none;
  font-size: 22px;
  cursor: pointer;
  border-radius: 8px;
  transition: transform 0.12s, background 0.12s;
}
.emoji:hover {
  background: var(--flare-color-bg-secondary);
  transform: scale(1.12);
}
.more {
  flex: none;
  width: 38px;
  height: 38px;
  border: none;
  border-radius: 8px;
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-secondary);
  cursor: pointer;
  display: grid;
  place-items: center;
}

/* detached quick row — three separate cards */
.quick {
  display: flex;
  gap: 6px;
}
.qtile {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3px;
  padding: 8px 0;
  border: none;
  cursor: pointer;
  color: var(--flare-color-text-primary);
}
.qtile span {
  font-size: 11px;
  font-weight: 500;
  line-height: 1.1;
}
.qtile:active {
  background: var(--flare-color-bg-secondary);
}

/* grouped list cards with hairline dividers */
.list {
  overflow: hidden;
}
.row {
  position: relative;
  display: flex;
  align-items: center;
  gap: 10px;
  width: 100%;
  padding: 9px 12px;
  border: none;
  background: none;
  color: var(--flare-color-text-primary);
  font-size: 14px;
  cursor: pointer;
  text-align: left;
}
.row:hover {
  background: var(--flare-color-bg-secondary);
}
/* hairline divider inset past the icon (reference: indent 40) — a pseudo-element
   so the row content stays full-width */
.row + .row::before {
  content: "";
  position: absolute;
  top: 0;
  left: 42px;
  right: 0;
  height: 1px;
  transform: scaleY(0.5);
  background: var(--flare-color-border-primary);
}
.ric {
  flex: none;
  color: inherit;
}
.rlabel {
  flex: 1;
}
.row.danger {
  color: var(--flare-color-error);
}

.echo {
  padding: 2px 6px 0;
  font-size: 12px;
  color: var(--flare-color-text-tertiary);
}
</style>
