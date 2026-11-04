<script setup lang="ts">
import { computed } from 'vue';
import FlareModal from '../general/FlareModal.vue';
const props = withDefaults(defineProps<{ mode: 'audio' | 'video'; expanded?: boolean; label?: string }>(), { expanded: false });
const emit = defineEmits<{ minimize: [] }>();
const width = computed(() => props.expanded ? 'calc(100vw - var(--flare-size-spacing-xl) * 2)' : props.mode === 'video' ? 'calc(var(--flare-size-component-sheet-dialog-width) * 1.5)' : 'var(--flare-size-component-sheet-dialog-width)');
const height = computed(() => props.expanded ? '90vh' : props.mode === 'video' ? 'min(80vh, calc(var(--flare-size-component-sheet-dialog-width) * 1.25))' : 'min(80vh, var(--flare-size-component-sheet-dialog-width))');
</script>
<template>
  <FlareModal :open="true" edge-to-edge :label="label" :title-hidden="true" :show-close="false" :width="width" :max-height="height" :fill="true" :scrollable="false" @close="emit('minimize')">
    <div class="flare-call-surface" :data-expanded="expanded" :data-mode="mode"><slot /></div>
  </FlareModal>
</template>
<style scoped>
.flare-call-surface { width: 100%; height: 100%; min-height: 0; overflow: hidden; }
</style>
