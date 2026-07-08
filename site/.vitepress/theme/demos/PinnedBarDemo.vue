<script setup>
import { ref } from "vue";
import DemoIcon from "./DemoIcon.vue";
const pins = [
  { id: "p1", sender: "Ivy", text: "评审会议：周四 15:00 三楼会议室" },
  { id: "p2", sender: "Kai", text: "本周排期已更新到看板" },
];
const i = ref(0);
function next() { i.value = (i.value + 1) % pins.length; }
</script>

<template>
  <div class="bar" @click="next">
    <span class="rail" />
    <span class="pin"><DemoIcon name="pin" :size="15" /></span>
    <div class="body">
      <div class="sender">{{ pins[i].sender }}</div>
      <div class="text">{{ pins[i].text }}</div>
    </div>
    <span class="count">{{ i + 1 }}/{{ pins.length }}</span>
  </div>
</template>

<style scoped>
.bar { width: 100%; max-width: 460px; display: flex; align-items: center; gap: 8px; padding: 8px 12px; background: var(--flare-color-bg-secondary); border-radius: 8px; cursor: pointer; position: relative; }
.rail { position: absolute; left: 0; top: 0; bottom: 0; width: 3px; background: var(--flare-color-pinned); border-radius: 3px; }
.pin { color: var(--flare-color-pinned); display: flex; }
.body { flex: 1; min-width: 0; }
.sender { font-size: 11px; font-weight: 600; color: var(--flare-color-pinned); }
.text { font-size: 13px; color: var(--flare-color-text-secondary); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.count { font-size: 11px; color: var(--flare-color-text-tertiary); }
</style>
