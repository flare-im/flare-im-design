<script setup lang="ts">
import { computed } from "vue";
import SceneList from './SceneList.vue';
import FlareTransferQueue from '../media/FlareTransferQueue.vue';
import type { MediaEntry } from '../../shared/contracts/scenes';
import type { TransferQueueItem, TransferAction } from '../../shared/contracts/transfer';
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
const props = defineProps<{items:MediaEntry[];transfers?:TransferQueueItem[];loading?:boolean;error?:string;title?:string;emptyText?:string}>();
const { t } = useFlareI18n();
const strings = computed(() => ({
  title: props.title ?? t("mediaCenter.title"),
  emptyText: props.emptyText ?? t("mediaCenter.empty"),
}));
const emit=defineEmits<{action:[value:{id:string;action:string}];reload:[];transferAction:[value:{id:string;action:TransferAction}];retryFailed:[ids:string[]]}>();
</script>
<template><div><SceneList :title="strings.title" :items="items.map(i=>({...i,actions:i.actions.filter(a=>i.availability==='available'||a.id!=='open')}))" :loading="loading" :error="error" :empty-text="strings.emptyText" @action="emit('action',$event)" @reload="emit('reload')" /><FlareTransferQueue v-if="transfers" :items="transfers" @action="emit('transferAction',$event)" @retry-failed="emit('retryFailed',$event)" /></div></template>
