<script setup>
import { ref } from "vue";
import DemoIcon from "./DemoIcon.vue";
const holding = ref(false);
const cancel = ref(false);
const log = ref("");
function down() { holding.value = true; cancel.value = false; }
function move(e) { if (holding.value) cancel.value = e.offsetY < -30; }
function up() {
  if (!holding.value) return;
  log.value = cancel.value ? "cancel · 已取消" : "end · 语音已发送 · 2\"";
  holding.value = false; cancel.value = false;
}
</script>
<template>
  <div class="wrap">
    <button
      class="hold" :class="{ holding, cancel }"
      @pointerdown="down" @pointermove="move" @pointerup="up" @pointerleave="up"
    >
      <DemoIcon name="mic" :size="17" />
      <span>{{ holding ? (cancel ? "松开取消" : "松开发送 · 上滑取消") : "按住 说话" }}</span>
    </button>
    <div class="echo">{{ log || "按住试试 —— start / end / cancel 三个回调" }}</div>
  </div>
</template>
<style scoped>
.wrap { width: 100%; max-width: 420px; }
.hold { width: 100%; display: flex; align-items: center; justify-content: center; gap: 8px; height: 40px; border: none; border-radius: 12px; background: var(--flare-color-bg-secondary); color: var(--flare-color-text-secondary); font-size: 14px; font-weight: 500; cursor: pointer; touch-action: none; user-select: none; }
.hold.holding { background: var(--flare-color-bg-selected); color: var(--flare-color-primary); }
.hold.cancel { background: color-mix(in srgb, var(--flare-color-error) 12%, transparent); color: var(--flare-color-error); }
.echo { margin-top: 10px; font-size: 12px; color: var(--flare-color-text-tertiary); }
</style>
