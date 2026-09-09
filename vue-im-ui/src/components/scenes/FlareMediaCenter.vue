<script setup lang="ts">
import SceneList from './SceneList.vue';
import FlareTransferQueue from '../media/FlareTransferQueue.vue';
import type { MediaEntry } from '../../shared/contracts/scenes';
import type { TransferQueueItem, TransferAction } from '../../shared/contracts/transfer';
withDefaults(defineProps<{items:MediaEntry[];transfers?:TransferQueueItem[];loading?:boolean;error?:string;title?:string}>(),{title:'文件与媒体'});
const emit=defineEmits<{action:[value:{id:string;action:string}];reload:[];transferAction:[value:{id:string;action:TransferAction}];retryFailed:[ids:string[]]}>();
</script>
<template><div><SceneList :title="title" :items="items.map(i=>({...i,actions:i.actions.filter(a=>i.availability==='available'||a.id!=='open')}))" :loading="loading" :error="error" empty-text="暂无文件或媒体" @action="emit('action',$event)" @reload="emit('reload')" /><FlareTransferQueue v-if="transfers" :items="transfers" @action="emit('transferAction',$event)" @retry-failed="emit('retryFailed',$event)" /></div></template>
