<script setup>
import { ref } from "vue";
import DemoIcon from "./DemoIcon.vue";
const nav = [
  { k: "chats", label: "消息", icon: "message", badge: 3 },
  { k: "contacts", label: "通讯录", icon: "users" },
  { k: "me", label: "我", icon: "person" },
];
const a = ref("chats");
const b = ref("chats");
</script>

<template>
  <div class="pair">
    <figure>
      <div class="phone">
        <div class="body">{{ nav.find(n => n.k === a).label }}</div>
        <nav class="bottom">
          <button v-for="n in nav" :key="n.k" :class="{ on: a === n.k }" @click="a = n.k">
            <span class="ic"><DemoIcon :name="n.icon" :size="21" /><i v-if="n.badge" class="b">{{ n.badge }}</i></span>
            <span class="lb">{{ n.label }}</span>
          </button>
        </nav>
      </div>
      <figcaption>手机 &lt; 600dp — 底部导航栏</figcaption>
    </figure>
    <figure>
      <div class="tablet">
        <nav class="rail">
          <button v-for="n in nav" :key="n.k" :class="{ on: b === n.k }" @click="b = n.k">
            <span class="ic"><DemoIcon :name="n.icon" :size="21" /><i v-if="n.badge" class="b">{{ n.badge }}</i></span>
            <span class="lb">{{ n.label }}</span>
          </button>
        </nav>
        <div class="body">{{ nav.find(n => n.k === b).label }}</div>
      </div>
      <figcaption>平板 / PC ≥ 600dp — 侧边 Rail</figcaption>
    </figure>
  </div>
</template>

<style scoped>
.pair { display: flex; flex-wrap: wrap; gap: 24px; }
figure { margin: 0; }
figcaption { margin-top: 8px; font-size: 11px; color: var(--flare-color-text-tertiary); text-align: center; }
.phone, .tablet { border: 1px solid var(--flare-color-border-primary); border-radius: 14px; background: var(--flare-color-bg-primary); overflow: hidden; }
.phone { width: 190px; height: 240px; display: flex; flex-direction: column; }
.tablet { width: 260px; height: 240px; display: flex; }
.body { flex: 1; display: flex; align-items: center; justify-content: center; background: var(--flare-color-bg-secondary); color: var(--flare-color-text-tertiary); font-size: 13px; }
nav { display: flex; }
.bottom { border-top: 1px solid var(--flare-color-border-secondary); }
.bottom button { flex: 1; }
.rail { flex-direction: column; gap: 4px; padding: 12px 6px; border-right: 1px solid var(--flare-color-border-secondary); }
nav button { display: flex; flex-direction: column; align-items: center; gap: 3px; padding: 8px 10px; border: none; border-radius: 10px; background: none; color: var(--flare-color-text-tertiary); cursor: pointer; }
nav button.on { color: var(--flare-color-primary); }
.rail button.on { background: var(--flare-color-bg-selected); }
.ic { position: relative; display: flex; }
.b { position: absolute; top: -4px; right: -7px; background: var(--flare-color-primary); color: #fff; font-size: 9px; font-style: normal; min-width: 14px; height: 14px; border-radius: 999px; display: flex; align-items: center; justify-content: center; padding: 0 3px; }
.lb { font-size: 10px; }
</style>
