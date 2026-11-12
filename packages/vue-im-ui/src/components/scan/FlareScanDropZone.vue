<script setup lang="ts">
import { ref } from "vue";
import FlareButton from "../general/FlareButton.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
defineProps<{ state?: string; hint?: string; pasteAvailable?: boolean }>();
const emit = defineEmits<{ pickImage: []; paste: []; drop: [files: File[]] }>();
const { t } = useFlareI18n();
const hovering = ref(false);
function drop(event: DragEvent) { hovering.value = false; const files = [...(event.dataTransfer?.files || [])].filter(file => file.type.startsWith('image/')); if (files.length) emit('drop', files); }
</script>
<template><section class="flare-scan-drop" :class="{ 'is-hovering': hovering }" :aria-label="t('scan.title')" @dragover.prevent="hovering = true" @dragleave="hovering = false" @drop.prevent="drop"><p role="status">{{ hint || t('scan.dropHint') }}</p><FlareButton :label="t('scan.album')" @click="emit('pickImage')" /><FlareButton v-if="pasteAvailable" variant="secondary" :label="t('scan.paste')" @click="emit('paste')" /></section></template>
<style scoped>
.flare-scan-drop { display: flex; flex-wrap: wrap; align-items: center; justify-content: center; gap: var(--flare-size-spacing-md); padding: var(--flare-size-spacing-xl); border: 1px dashed var(--flare-color-border-primary); border-radius: var(--flare-size-radius-lg); background: var(--flare-color-bg-secondary); color: var(--flare-color-text-secondary); }
.flare-scan-drop p { flex-basis: 100%; text-align: center; margin: 0; }
.flare-scan-drop.is-hovering { border-color: var(--flare-color-primary); background: var(--flare-color-bg-selected); }
</style>
