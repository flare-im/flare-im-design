<script setup lang="ts">
import FlareBottomSheet from "./FlareBottomSheet.vue";
import FlareButton from "./FlareButton.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
const props = withDefaults(defineProps<{
  open: boolean; title: string; busy?: boolean; confirmDisabled?: boolean;
  confirmLabel?: string; cancelLabel?: string; error?: string;
}>(), { busy: false, confirmDisabled: false });
const emit = defineEmits<{ confirm: []; close: [] }>();
const { t } = useFlareI18n();
function close() { if (!props.busy) emit("close"); }
function confirm() { if (!props.busy && !props.confirmDisabled) emit("confirm"); }
</script>
<template>
  <FlareBottomSheet :open="open" :title="title" :dismissible="!busy" @close="close">
    <form class="flare-form-sheet" :aria-busy="busy" @submit.prevent="confirm">
      <fieldset class="flare-form-sheet__fields" :disabled="busy"><slot /></fieldset>
      <p v-if="error" class="flare-form-sheet__error" role="alert">{{ error }}</p>
      <footer class="flare-form-sheet__actions">
        <FlareButton variant="secondary" :disabled="busy" @click="close">{{ cancelLabel ?? t('common.cancel') }}</FlareButton>
        <FlareButton :loading="busy" :disabled="busy || confirmDisabled" @click="confirm">{{ confirmLabel ?? t('common.confirm') }}</FlareButton>
      </footer>
    </form>
  </FlareBottomSheet>
</template>
<style scoped>
.flare-form-sheet { width: min(100%, 480px); box-sizing: border-box; margin-inline: auto; padding: 12px 16px 20px; display: flex; flex-direction: column; gap: 16px; }
.flare-form-sheet__fields { min-width: 0; border: 0; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 12px; }
.flare-form-sheet__actions { display: flex; gap: 12px; }
.flare-form-sheet__actions > * { flex: 1; }
.flare-form-sheet__error { margin: 0; color: var(--flare-color-error); font-size: var(--flare-size-font-size-sm, 12px); }
</style>
