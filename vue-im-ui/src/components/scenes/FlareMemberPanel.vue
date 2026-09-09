<script setup lang="ts">
import SceneList from './SceneList.vue';
import type { SceneEntry } from '../../shared/contracts/scenes';
withDefaults(defineProps<{items:SceneEntry[];loading?:boolean;error?:string;title?:string}>(),{title:'群成员'});
const emit=defineEmits<{action:[value:{id:string;action:string}];reload:[]}>();
</script>
<template><SceneList :items="items" :title="title" :loading="loading" :error="error" empty-text="暂无成员" @action="emit('action',$event)" @reload="emit('reload')" /></template>
