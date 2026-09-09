<script setup>
import { ref } from "vue";
import FlareConversationWorkspace from "@flare-im/vue-ui/components/layout/FlareConversationWorkspace.vue";
import DemoStage from "./DemoStage.vue";

const ready = { status: "ready" };
const listState = ref({ ...ready });
const chatState = ref({ ...ready });
const detailState = ref({ ...ready });
const banner = ref(undefined);
const activePane = ref("chat");
const last = ref("尚未操作");

function reset() {
  listState.value = { ...ready };
  chatState.value = { ...ready };
  detailState.value = { ...ready };
  banner.value = undefined;
  last.value = "尚未操作";
}
function loading() {
  listState.value = { status: "loading" };
  chatState.value = { status: "loading" };
  detailState.value = { status: "loading" };
}
function empty() {
  listState.value = { status: "empty", message: "还没有会话，先找个人聊聊" };
  chatState.value = { status: "empty" };
  detailState.value = { status: "empty" };
}
function partialFailure() {
  // The list already loaded and stays readable; only the timeline failed.
  listState.value = { ...ready };
  chatState.value = { status: "failure", message: "消息加载失败：网络中断", actionLabel: "重试" };
  detailState.value = { status: "loading" };
}
function failureWithoutRecovery() {
  chatState.value = { status: "failure", message: "该会话已被管理员关闭，无法加载消息" };
}
function offline() {
  banner.value = { tone: "warning", message: "离线，显示的是缓存内容", actionLabel: "重连" };
}
function retry(pane) {
  last.value = `重试：${pane}`;
  if (pane === "chat") chatState.value = { status: "loading" };
  if (pane === "list") listState.value = { status: "loading" };
  if (pane === "detail") detailState.value = { status: "loading" };
}
</script>

<template>
  <DemoStage>
    <div class="workspace-demo">
      <div class="stage">
        <FlareConversationWorkspace
          has-detail
          :active-pane="activePane"
          :list-state="listState"
          :chat-state="chatState"
          :detail-state="detailState"
          :banner="banner"
          back-label="返回"
          @pane-change="activePane = $event"
          @retry="retry"
          @banner-action="last = '全局提示操作：重连'"
        >
          <template #list><div class="pane pane--list">会话列表内容</div></template>
          <template #chat><div class="pane">消息时间线内容</div></template>
          <template #detail><div class="pane">会话详情内容</div></template>
        </FlareConversationWorkspace>
      </div>
      <div class="controls">
        <button @click="reset">默认</button>
        <button @click="loading">加载中</button>
        <button @click="empty">空</button>
        <button @click="partialFailure">部分失败</button>
        <button @click="failureWithoutRecovery">失败但无恢复动作</button>
        <button @click="offline">离线全局提示</button>
      </div>
      <p role="status">{{ last }}。本地状态演示，不发起任何请求。</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.workspace-demo { width: 100%; min-width: 0; display: grid; gap: 16px; }
.stage { width: 100%; height: 380px; border-radius: 14px; overflow: hidden; border: 1px solid var(--flare-color-border-secondary); }
.pane { display: flex; align-items: center; justify-content: center; height: 100%; color: var(--flare-color-text-tertiary); font-size: 13px; }
.pane--list { align-items: flex-start; padding-top: 24px; }
.controls { display: flex; flex-wrap: wrap; gap: 8px; }
.controls button { min-height: 48px; padding: 8px 12px; border: 1px solid var(--flare-color-border-primary); border-radius: 8px; }
p { font-size: 13px; overflow-wrap: anywhere; }
</style>
