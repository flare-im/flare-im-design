<script setup lang="ts">
import { computed } from 'vue';
import SceneList from './SceneList.vue';
import { deviceSessionActions,type DeviceSessionEntry } from '../../shared/contracts/scenes';
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
const props = defineProps<{items:DeviceSessionEntry[];loading?:boolean;error?:string;title?:string;currentText?:string;emptyText?:string}>();
const { t } = useFlareI18n();
const strings = computed(() => ({
  title: props.title ?? t("deviceSessions.title"),
  currentText: props.currentText ?? t("deviceSessions.current"),
  emptyText: props.emptyText ?? t("deviceSessions.empty"),
}));
const emit=defineEmits<{action:[value:{id:string;action:string}];reload:[]}>();
const rows=computed(()=>props.items.map(i=>({...i,badge:i.current?strings.value.currentText:i.badge,actions:deviceSessionActions(i)})));
</script>
<template><SceneList :items="rows" :title="strings.title" :loading="loading" :error="error" :empty-text="strings.emptyText" @action="emit('action',$event)" @reload="emit('reload')" /></template>
