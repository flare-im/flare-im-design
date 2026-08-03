<script setup>
import { ref } from "vue";
import FlareStatusBanner from "@flare-im/vue-ui/components/general/FlareStatusBanner.vue";

const log = ref("");
</script>

<template>
  <div class="sb-demo">
    <FlareStatusBanner tone="info" text="正在连接服务器… · Connecting" pulse />
    <FlareStatusBanner tone="success" text="已连接 · Online" />
    <FlareStatusBanner tone="warning" text="网络不稳定，正在重试 · Reconnecting" pulse />
    <FlareStatusBanner
      tone="danger"
      text="消息同步失败 · 连接超时"
      action-text="重试"
      @action="log = '点击了重试 · retry clicked'"
    />
    <div v-if="log" class="sb-demo__log">{{ log }}</div>
  </div>
</template>

<style scoped>
.sb-demo {
  width: 100%;
  max-width: 420px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.sb-demo__log {
  font-size: 12px;
  color: var(--flare-color-text-tertiary);
}
</style>
