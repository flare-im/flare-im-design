<script setup>
import { ref } from "vue";
import { FlareInAppNotificationBanner } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

// The three looks: a plain message, a mention standing for three unread messages, and an urgent one.
const banners = [
  { collapseId: "c:alice", conversationId: "alice", messageId: "m1", title: "张三", body: "下午三点的评审改到四点了，记得带上原型。", channel: "messages" },
  { collapseId: "c:design", conversationId: "design", messageId: "m2", title: "设计评审群", body: "李四：@你 这一版的配色确认一下", count: 3, channel: "mentions" },
  { collapseId: "c:ops", conversationId: "ops", messageId: "m3", title: "值班告警", body: "支付服务响应超时，请尽快处理", channel: "urgent" },
];
const last = ref("尚未操作");
function open(conversationId, messageId) { last.value = `宿主打开会话 ${conversationId}，定位到 ${messageId}`; }
function dismiss(banner) { last.value = `收起「${banner.title}」`; }
</script>
<template><DemoStage><div class="banner-demo">
  <FlareInAppNotificationBanner
    v-for="banner in banners"
    :key="banner.collapseId"
    :notification="banner"
    @open="open"
    @dismiss="dismiss(banner)"
  />
  <p role="status">{{ last }}。向上轻扫、关闭键或 Escape 都会收起。</p>
</div></DemoStage></template>
<style scoped>
.banner-demo { width: 100%; max-width: 420px; min-width: 0; display: grid; gap: 12px; }
p { font-size: 13px; overflow-wrap: anywhere; }
</style>
