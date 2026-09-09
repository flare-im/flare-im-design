<script setup>
import { computed, ref } from 'vue';
import FlareTransferProgress from '@flare-im/vue-ui/components/media/FlareTransferProgress.vue';
import FlareStatusBanner from '@flare-im/vue-ui/components/general/FlareStatusBanner.vue';
import DemoStage from './DemoStage.vue';
const state = ref('failed');
const busy = ref(false);
const unknown = ref(false);
const value = ref(37);
const lastAction = ref('');
const names = { queued: '排队中', transferring: '传输中', paused: '已暂停', failed: '传输失败', completed: '已完成', cancelled: '已取消' };
const status = computed(() => state.value === 'failed' ? '网络中断，文件保留在队列中，可重新尝试。' : names[state.value]);
const labels = { pause: '暂停', resume: '继续传输', cancel: '取消', retry: '重新尝试', open: '打开文件' };
function action(a) { lastAction.value = labels[a]; }
</script>
<template>
  <DemoStage>
    <div class="transfer-demo">
      <div class="controls">
        <label>状态 <select v-model="state" aria-label="传输状态"><option v-for="(label, key) in names" :key="key" :value="key">{{ label }}</option></select></label>
        <label><input v-model="busy" type="checkbox" /> 操作处理中</label>
        <label><input v-model="unknown" type="checkbox" /> 未知进度</label>
        <label>进度 {{ value }}% <input v-model.number="value" type="range" min="0" max="100" aria-label="模拟进度" /></label>
      </div>
      <FlareStatusBanner text="连接恢复后可以继续传输，已有消息仍可查看。" tone="warning" action-text="检查连接" @action="lastAction = '检查连接'" />
      <FlareTransferProgress name="设计交付-跨平台组件规范-2026.pdf" :state="state" :status-text="status" :progress="unknown ? null : value / 100" :action-labels="labels" :busy="busy" @action="action" />
      <p role="status" class="result">{{ lastAction ? `收到操作：${lastAction}` : '本地状态演示：不上传文件、不发网络请求。' }}</p>
    </div>
  </DemoStage>
</template>
<style scoped>
.transfer-demo { display: grid; gap: 16px; min-width: 0; width: 100%; }
.controls { display: flex; align-items: center; flex-wrap: wrap; gap: 12px; font-size: 14px; }
.controls label { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; min-height: 48px; }
select { min-height: 48px; padding: 8px; border: 1px solid var(--flare-color-border-primary); border-radius: 8px; }
.result { font-size: 13px; color: var(--flare-color-text-secondary); }
</style>
