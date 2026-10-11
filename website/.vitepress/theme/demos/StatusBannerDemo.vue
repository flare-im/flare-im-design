<script setup>
import { ref } from "vue";
import { FlareStatusBanner } from "@flare-im/vue-ui/components";

const log = ref("");
// 控制台的平台公告：粗体标题在上、正文在下，关闭键上报 dismiss，由宿主记住已关闭的公告。
const noticeOpen = ref(true);
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
    <FlareStatusBanner
      v-if="noticeOpen"
      tone="warning"
      title="计划维护"
      text="今晚 23:00 起维护 30 分钟，期间消息可能延迟送达。"
      :dot="false"
      dismissible
      @dismiss="noticeOpen = false; log = '公告已关闭 · dismissed'"
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
