<script setup>
import { ref } from 'vue';
import FlarePermissionPrompt from '@flare-im/vue-ui/components/general/FlarePermissionPrompt.vue';
import DemoStage from './DemoStage.vue';
const kinds = ['microphone', 'camera', 'notifications', 'storage', 'photos', 'contacts', 'location'];
const states = ['undetermined', 'denied', 'restricted', 'unavailable'];
const kind = ref('microphone'), state = ref('undetermined'), busy = ref(false), compact = ref(false), dismissed = ref(false), last = ref('尚未操作');
function request() { last.value = '宿主收到 request，正在向系统申请'; busy.value = true; setTimeout(() => { busy.value = false; state.value = 'denied'; last.value = '模拟：系统拒绝了申请，切换为 denied'; }, 900); }
function openSettings() { last.value = '宿主收到 openSettings，交由平台打开系统设置'; }
function dismiss() { dismissed.value = true; last.value = '宿主收到 dismiss，已关闭提示'; }
function reset() { kind.value = 'microphone'; state.value = 'undetermined'; busy.value = false; dismissed.value = false; last.value = '尚未操作'; }
</script>
<template><DemoStage><div class="permission-demo">
  <FlarePermissionPrompt v-if="!dismissed" :kind="kind" :state="state" :busy="busy" :compact="compact" feature-label="发送语音消息" :detail="state === 'denied' ? '开启后返回本页即可继续。' : undefined" @request="request" @open-settings="openSettings" @dismiss="dismiss" />
  <p v-else role="status">提示已关闭。</p>
  <div class="controls">
    <label>权限 <select v-model="kind"><option v-for="k in kinds" :key="k" :value="k">{{ k }}</option></select></label>
    <label>状态 <select v-model="state"><option v-for="s in states" :key="s" :value="s">{{ s }}</option></select></label>
    <label><input v-model="busy" type="checkbox" /> busy</label>
    <label><input v-model="compact" type="checkbox" /> compact</label>
    <button type="button" @click="reset">重置演示</button>
  </div>
  <p role="status">{{ last }}。本地模拟，不申请任何系统权限。</p>
</div></DemoStage></template>
<style scoped>
.permission-demo { width: 100%; min-width: 0; display: grid; gap: 16px; }
.controls { display: flex; flex-wrap: wrap; gap: 12px; align-items: center; }
.controls label { display: inline-flex; align-items: center; gap: 6px; font-size: 13px; }
.controls select { min-height: 36px; padding: 4px 8px; border: 1px solid var(--flare-color-border-primary); border-radius: 8px; }
.controls button { min-height: 48px; padding: 8px 12px; border: 1px solid var(--flare-color-border-primary); border-radius: 8px; }
p { font-size: 13px; overflow-wrap: anywhere; }
</style>
