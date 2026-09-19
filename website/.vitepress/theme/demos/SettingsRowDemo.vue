<script setup>
import { ref } from "vue";
import { FlareSettingsRow } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
const notify = ref(true);
const log = ref("");
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareSettingsRow :item="{ key: 'notify', label: '新消息通知', kind: 'toggle', value: notify }" @toggle="(_, value) => (notify = value)" />
      <FlareSettingsRow :item="{ key: 'lang', label: '语言', detail: '简体中文' }" @select="log = 'select · lang'" />
      <FlareSettingsRow :item="{ key: 'block', label: '黑名单', detail: '2 人', disabled: true }" />
      <FlareSettingsRow :item="{ key: 'logout', label: '退出登录', danger: true }" @select="log = 'select · logout'" />
      <div class="echo">{{ log || "开关行发 toggle(item, value)，其余行发 select(item)" }}</div>
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { width: 100%; max-width: 380px; border-radius: var(--flare-size-radius-lg); overflow: hidden; background: var(--flare-color-bg-primary); }
.echo { font-size: 12px; color: var(--flare-color-text-tertiary); padding: 10px 16px; }
</style>
