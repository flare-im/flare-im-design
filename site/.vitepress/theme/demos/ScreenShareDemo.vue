<script setup>
import { ref } from 'vue';
import FlareScreenShare from '@flare-im/vue-ui/components/call/FlareScreenShare.vue';
import DemoStage from './DemoStage.vue';

const states = ['idle', 'requesting', 'sharing', 'viewing', 'unavailable'];
const details = {
  idle: undefined,
  requesting: '已向系统发起屏幕录制请求，等待选择共享内容',
  sharing: '上行带宽受限，画面已降到 15 帧',
  viewing: undefined,
  unavailable: '当前浏览器未提供屏幕采集能力，请改用桌面端',
};
const state = ref('idle');
const busy = ref(false);
const last = ref('尚未操作');

function run(name, next) {
  last.value = `${name} · busy 已同步置位`;
  busy.value = true;
  setTimeout(() => { busy.value = false; state.value = next; }, 1200);
}
</script>

<template>
  <DemoStage>
    <div class="ss-demo">
      <FlareScreenShare
        :state="state"
        source-label="整个屏幕 · Display 1"
        presenter-name="林可"
        :detail="details[state]"
        :busy="busy"
        has-start
        has-stop
        has-cancel
        @start="run('start', 'requesting')"
        @stop="run('stop', 'idle')"
        @cancel="run('cancel', 'idle')"
      />
      <div class="controls" role="group" aria-label="切换状态">
        <button v-for="s in states" :key="s" type="button" :aria-pressed="state === s" :class="{ active: state === s }" @click="state = s">{{ s }}</button>
      </div>
      <div class="controls">
        <button type="button" @click="busy = !busy">{{ busy ? '结束 busy' : '模拟 busy' }}</button>
      </div>
      <p role="status">{{ last }}。本地模拟，不采集屏幕、不发起任何网络请求；权限被拒时宿主改用 PermissionPrompt(kind=screen, state=denied)。</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.ss-demo { width: 100%; max-width: 520px; min-width: 0; display: grid; gap: 16px; }
.controls { display: flex; flex-wrap: wrap; gap: 8px; }
.controls button { min-height: 48px; padding: 8px 12px; border: 1px solid var(--flare-color-border-primary); border-radius: 8px; background: var(--flare-color-bg-primary); color: var(--flare-color-text-primary); }
.controls button.active { border-color: var(--flare-color-primary); color: var(--flare-color-primary); }
p { font-size: 13px; overflow-wrap: anywhere; }
</style>
