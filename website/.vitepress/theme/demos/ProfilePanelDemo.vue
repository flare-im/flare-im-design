<script setup>
import { computed, ref } from "vue";
import { FlareButton, FlareProfilePanel } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

const mode = ref('default');
const user = computed(() => ({
  id: "u2",
  name: mode.value === 'long' ? '欧阳明月（产品体验与用户研究团队 · 华东区）' : 'Ivy Chen',
  signature: mode.value === 'empty' ? '' : mode.value === 'long' ? '记录生活与工作中的灵感，也欢迎和我交流设计、产品与日常的小发现。' : '设计即沟通',
  flareId: mode.value === 'long' ? 'ivy_chen_design_and_research' : 'ivy_chen',
}));
const sections = [
  { title: '常用功能', items: [{ key: 'favorites', label: '收藏', icon: 'star' }, { key: 'moments', label: '圈子', icon: 'moments' }] },
  { title: '应用服务', items: [{ key: 'wallet', label: '钱包', icon: 'wallet' }, { key: 'packet', label: '红包记录', icon: 'redpacket' }, { key: 'realname', label: '实名认证', icon: 'shield' }] },
  { title: '偏好设置', items: [{ key: 'settings', label: '设置', icon: 'settings' }] },
];
// The identity and the QR button are controls because the demo handles both intents.
const lastIntent = ref("");
const show = (name) => { lastIntent.value = name; };
</script>

<template>
  <DemoStage>
    <div class="stage">
      <div class="controls">
        <FlareButton v-for="item in [{ key: 'default', label: '默认资料' }, { key: 'long', label: '长资料' }, { key: 'empty', label: '无签名' }]" :key="item.key" size="sm" :variant="mode === item.key ? 'primary' : 'secondary'" :aria-pressed="mode === item.key" @click="mode = item.key">{{ item.label }}</FlareButton>
      </div>
      <FlareProfilePanel :user="user" :sections="sections" @edit="show('edit')" @qr="show('qr')" @action="(item) => show(item.key)" />
      <p class="intent" role="status">{{ lastIntent }}</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: var(--flare-size-layout-readable-width); }
.controls { display: flex; flex-wrap: wrap; gap: var(--flare-size-spacing-sm); padding: var(--flare-size-spacing-md); }
.intent { min-height: 1.5em; margin: 8px 0 0; color: var(--flare-color-text-secondary); font-size: 13px; text-align: center; }
</style>
