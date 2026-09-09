<script setup lang="ts">
import { computed } from 'vue';
import SceneList from './SceneList.vue';
import { deviceSessionActions,type DeviceSessionEntry } from '../../shared/contracts/scenes';
const props=withDefaults(defineProps<{items:DeviceSessionEntry[];loading?:boolean;error?:string;title?:string;currentText?:string}>(),{title:'登录设备',currentText:'当前设备'});
const emit=defineEmits<{action:[value:{id:string;action:string}];reload:[]}>();
const rows=computed(()=>props.items.map(i=>({...i,badge:i.current?props.currentText:i.badge,actions:deviceSessionActions(i)})));
</script>
<template><SceneList :items="rows" :title="title" :loading="loading" :error="error" empty-text="暂无其他设备" @action="emit('action',$event)" @reload="emit('reload')" /></template>
