<script setup>
import { ref } from "vue";
import DemoIcon from "./DemoIcon.vue";
const notify = ref(true);
const sound = ref(false);
const sections = [
  {
    title: "通知",
    items: [
      { k: "notify", label: "新消息通知", kind: "switch", icon: "bellOff" },
      { k: "sound", label: "提示音", kind: "switch", icon: "volume" },
    ],
  },
  {
    title: "通用",
    items: [
      { k: "theme", label: "主题", kind: "value", value: "跟随系统", icon: "settings" },
      { k: "storage", label: "存储与缓存", kind: "nav", icon: "folder" },
      { k: "about", label: "关于 Flare", kind: "value", value: "v0.3.0", icon: "star" },
    ],
  },
];
const model = { notify, sound };
</script>

<template>
  <div class="wrap">
    <div v-for="s in sections" :key="s.title" class="sec">
      <div class="st">{{ s.title }}</div>
      <div class="card">
        <div v-for="it in s.items" :key="it.k" class="row">
          <span class="i"><DemoIcon :name="it.icon" :size="18" /></span>
          <span class="l">{{ it.label }}</span>
          <button
            v-if="it.kind === 'switch'" class="sw" :class="{ on: model[it.k].value }"
            :aria-pressed="model[it.k].value" @click="model[it.k].value = !model[it.k].value"
          ><span /></button>
          <span v-else-if="it.kind === 'value'" class="v">{{ it.value }}</span>
          <DemoIcon v-if="it.kind !== 'switch'" name="chevronRight" :size="16" class="chev" />
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.wrap { width: 100%; max-width: 400px; }
.sec + .sec { margin-top: 16px; }
.st { font-size: 12px; color: var(--flare-color-text-tertiary); margin: 0 4px 6px; }
.card { border: 1px solid var(--flare-color-border-primary); border-radius: 12px; background: var(--flare-color-bg-primary); overflow: hidden; }
.row { display: flex; align-items: center; gap: 12px; padding: 12px 14px; }
.row + .row { border-top: 1px solid var(--flare-color-border-secondary); }
.i { color: var(--flare-color-text-secondary); display: flex; }
.l { flex: 1; color: var(--flare-color-text-primary); font-size: 14px; }
.v { font-size: 13px; color: var(--flare-color-text-tertiary); }
.chev { color: var(--flare-color-text-tertiary); }
.sw { width: 42px; height: 24px; border-radius: 999px; border: none; background: var(--flare-color-bg-disabled); cursor: pointer; padding: 2px; display: flex; transition: background .16s; }
.sw span { width: 20px; height: 20px; border-radius: 50%; background: #fff; box-shadow: 0 1px 3px rgba(0,0,0,.2); transition: transform .16s; }
.sw.on { background: var(--flare-color-primary); }
.sw.on span { transform: translateX(18px); }
</style>
