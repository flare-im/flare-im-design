<script setup>
import {ref,computed} from 'vue';
import FlareCallDevicePicker from '@flare-im/vue-ui/components/call/FlareCallDevicePicker.vue';
import DemoStage from './DemoStage.vue';
const permission=ref('available'),busy=ref(false),selected=ref('built-in'),removed=ref(false),last=ref('尚未切换');
const groups=computed(()=>[{kind:'microphone',label:'麦克风',selectedId:selected.value,busy:busy.value,devices:[...(removed.value?[]:[{id:'built-in',label:'内置麦克风'}]),{id:'usb',label:'USB 麦克风'},{id:'unavailable',label:'不可用设备',disabled:true}]}]);
</script>
<template><DemoStage><section class="device-picker-demo">
  <label>权限状态 <select v-model="permission" aria-label="权限状态"><option v-for="state in ['available','loading','denied','unavailable','failed']" :key="state">{{ state }}</option></select></label>
  <label><input v-model="busy" type="checkbox" /> 正在切换</label><button @click="removed=true">模拟设备拔出</button>
  <FlareCallDevicePicker :groups="groups" :permission="permission" permission-text="RTC 设备与权限由宿主提供" action-text="申请权限" @permission-action="permission='available'" @select="selected=$event.deviceId;last=$event.kind+'/'+$event.deviceId" />
  <p>{{ last }}。本地夹具，不访问麦克风。</p>
</section></DemoStage></template>
<style scoped>.device-picker-demo{display:grid;gap:12px;min-width:0;width:100%}button,select{min-height:48px}label{display:flex;align-items:center;gap:8px;flex-wrap:wrap}p{overflow-wrap:anywhere}</style>
