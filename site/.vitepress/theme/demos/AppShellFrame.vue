<script setup>
// Full-bleed AppShell for the responsive iframe preview: wide viewport → side
// rail; narrow viewport → bottom tab bar (FlareAppShell switches on innerWidth).
import { ref } from "vue";
import FlareAppShell from "@flare-im/vue-ui/components/layout/FlareAppShell.vue";

const items = [
  { key: "chat", label: "消息", badge: 3 },
  { key: "contacts", label: "通讯录" },
  { key: "moments", label: "动态" },
  { key: "me", label: "我" },
];
const active = ref("chat");
const labels = { chat: "消息", contacts: "通讯录", moments: "动态", me: "我" };
</script>

<template>
  <div class="frame">
    <FlareAppShell :items="items" :active-key="active" @navigate="(k) => (active = k)">
      <div class="pane">
        <div class="pane__title">{{ labels[active] }}</div>
        <div class="pane__sub">切到窄屏看底部 tab · 宽屏看侧边导航栏</div>
      </div>
    </FlareAppShell>
  </div>
</template>

<style scoped>
.frame { height: 100dvh; background: var(--flare-color-bg-primary, #fff); }
.pane {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
  height: 100%;
  background: var(--flare-color-bg-secondary, #f5f6f8);
}
.pane__title { font-size: 22px; font-weight: 700; color: var(--flare-color-text-primary); }
.pane__sub { font-size: 13px; color: var(--flare-color-text-tertiary); }
</style>
