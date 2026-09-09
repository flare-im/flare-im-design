<script setup>
import { ref } from "vue";
const pane = ref("list");
const scale = ref(1);
import FlareResponsiveLayout from "@flare-im/vue-ui/components/layout/FlareResponsiveLayout.vue";
import DemoStage from "./DemoStage.vue";
</script>

<template>
  <DemoStage>
    <div class="controls">
      <button @click="pane = 'list'">列表</button>
      <button @click="pane = 'chat'">聊天</button>
      <button @click="pane = 'detail'">详情</button>
      <label>字号 <select v-model.number="scale"><option :value="1">标准</option><option :value="2">200%</option></select></label>
    </div>
    <div class="stage">
      <FlareResponsiveLayout has-detail :active-pane="pane" :text-scale="scale" back-label="返回" @pane-change="pane = $event">
        <template #list><div class="pane list">会话列表</div></template>
        <template #chat><div class="pane chat">聊天窗口</div></template>
        <template #detail><div class="pane detail">会话详情</div></template>
      </FlareResponsiveLayout>
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 560px; height: 300px; border-radius: 14px; overflow: hidden; border: 1px solid var(--flare-color-border-secondary); }
.pane { display: flex; align-items: center; justify-content: center; height: 100%; color: var(--flare-color-text-tertiary); }
.list { background: var(--flare-color-bg-secondary); }
.controls { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; margin-bottom: 12px; }
.controls button, .controls select { min-height: 48px; padding: 8px 12px; border: 1px solid var(--flare-color-border-primary); border-radius: 8px; }
</style>
