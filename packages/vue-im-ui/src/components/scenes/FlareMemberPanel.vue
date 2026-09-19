<script setup lang="ts">
import { computed } from "vue";
import SceneList from './SceneList.vue';
import type { SceneEntry } from '../../shared/contracts/scenes';
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
const props = defineProps<{items:SceneEntry[];loading?:boolean;error?:string;title?:string;emptyText?:string}>();
const { t } = useFlareI18n();
const strings = computed(() => ({
  title: props.title ?? t("memberPanel.title"),
  emptyText: props.emptyText ?? t("memberPanel.empty"),
}));
const emit=defineEmits<{action:[value:{id:string;action:string}];reload:[]}>();
</script>
<template><SceneList :items="items" :title="strings.title" :loading="loading" :error="error" :empty-text="strings.emptyText" @action="emit('action',$event)" @reload="emit('reload')" /></template>
