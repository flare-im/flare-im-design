<script setup>
import { computed, ref } from "vue";
import { FlareInAppNotificationHost, FlareButton } from "@flare-im/vue-ui/components";
import { createFlareInAppNotifications } from "@flare-im/vue-ui/composables";
import DemoStage from "./DemoStage.vue";

// The app owns the presenter and feeds it; the host decides what shows, what waits and for how long.
const inApp = createFlareInAppNotifications();
const last = ref("尚未打开会话");
let aliceCount = 0;
let sequence = 0;

function fromAlice() {
  aliceCount += 1;
  inApp.present({ collapseId: "c:alice", conversationId: "alice", messageId: `a${aliceCount}`, title: "张三", body: `第 ${aliceCount} 条：周会改到明天上午了`, count: aliceCount });
}
function mention() {
  sequence += 1;
  inApp.present({ collapseId: "c:design", conversationId: "design", messageId: `d${sequence}`, title: "设计评审群", body: "李四：@你 这一版的配色确认一下", channel: "mentions" });
}
function urgent() {
  sequence += 1;
  inApp.present({ collapseId: "c:ops", conversationId: "ops", messageId: `o${sequence}`, title: "值班告警", body: "支付服务响应超时，请尽快处理", channel: "urgent" });
}
function readAlice() {
  aliceCount = 0;
  inApp.clear(["c:alice"]);
}
const waiting = computed(() => inApp.pending.value.map((entry) => entry.title).join("、") || "无");
function open(conversationId, messageId) { last.value = `宿主打开会话 ${conversationId}，定位到 ${messageId}`; }
</script>
<template><DemoStage><div class="host-demo">
  <FlareInAppNotificationHost :notifications="inApp" @open="open" />
  <div class="controls">
    <FlareButton size="sm" @click="fromAlice">张三发来一条</FlareButton>
    <FlareButton size="sm" variant="secondary" @click="mention">群里有人 @你</FlareButton>
    <FlareButton size="sm" variant="secondary" @click="urgent">加急消息</FlareButton>
    <FlareButton size="sm" variant="secondary" @click="readAlice">在别处读了张三</FlareButton>
    <FlareButton size="sm" variant="secondary" @click="inApp.clearAll()">全部清除</FlareButton>
  </div>
  <p>排队中：{{ waiting }}</p>
  <p role="status">{{ last }}。横幅出现在页面顶部，停留 4 秒，按住或悬停时暂停计时。</p>
</div></DemoStage></template>
<style scoped>
.host-demo { width: 100%; min-width: 0; display: grid; gap: 12px; }
.controls { display: flex; flex-wrap: wrap; gap: 8px; }
p { font-size: 13px; overflow-wrap: anywhere; }
</style>
