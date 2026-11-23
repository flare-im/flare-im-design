<script setup lang="ts">
import FlareBottomSheet, { type FlareSheetPresentation } from "./FlareBottomSheet.vue";
import FlareButton from "./FlareButton.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
const props = withDefaults(defineProps<{
  open: boolean; title: string; busy?: boolean; confirmDisabled?: boolean;
  confirmLabel?: string; cancelLabel?: string; error?: string;
  /** Short context under the title, such as the person being replied to. */
  description?: string;
  density?: "normal" | "compact";
  /**
   * `auto` (default): a bottom sheet on phones and a FlareModal on pointer devices; `sheet` always a sheet.
   * A long-lived form that belongs beside the main view is a FlareDrawer, not this.
   */
  presentation?: FlareSheetPresentation;
  /** 交给 FlareModal 时这张面有多宽;`class` 与外部的自定义属性都到不了那里,见 FlareBottomSheet。 */
  dialogWidth?: string;
  /** Long forms keep actions visible while their fields scroll inside a bounded surface. */
  fill?: boolean;
  maxHeight?: string;
}>(), { busy: false, confirmDisabled: false, density: "normal", presentation: "auto", fill: false, maxHeight: "72vh" });
const emit = defineEmits<{ confirm: []; close: [] }>();
const { t } = useFlareI18n();
function close() { if (!props.busy) emit("close"); }
function confirm() { if (!props.busy && !props.confirmDisabled) emit("confirm"); }
</script>
<template>
  <FlareBottomSheet :open="open" :title="title" :dismissible="!busy" :presentation="presentation" :dialog-width="dialogWidth" :fill="fill" :max-height="maxHeight" @close="close">
    <form class="flare-form-sheet" :class="{ 'is-fill': fill, 'is-compact': density === 'compact' }" :aria-busy="busy" @submit.prevent="confirm">
      <p v-if="description" class="flare-form-sheet__description" :title="description">{{ description }}</p>
      <div class="flare-form-sheet__fields"><fieldset class="flare-form-sheet__fieldset" :disabled="busy"><slot /></fieldset></div>
      <p v-if="error" class="flare-form-sheet__error" role="alert">{{ error }}</p>
      <footer class="flare-form-sheet__actions">
        <FlareButton size="sm" variant="secondary" :disabled="busy" @click="close">{{ cancelLabel ?? t('common.cancel') }}</FlareButton>
        <FlareButton size="sm" :loading="busy" :disabled="busy || confirmDisabled" @click="confirm">{{ confirmLabel ?? t('common.confirm') }}</FlareButton>
      </footer>
    </form>
  </FlareBottomSheet>
</template>
<style scoped>
.flare-form-sheet { min-height: 0; overflow: hidden; flex-shrink: 1; width: min(100%, 480px); box-sizing: border-box; margin-inline: auto; padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg) var(--flare-size-spacing-md); display: flex; flex-direction: column; gap: var(--flare-size-spacing-md); }
.flare-form-sheet.is-compact { gap: var(--flare-size-spacing-sm); }
.flare-form-sheet__description { margin: 0; color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); line-height: 1.4; overflow-wrap: anywhere; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.flare-form-sheet__fields { min-width: 0; min-height: 0; overflow-y: auto; overscroll-behavior: contain; border: 0; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 12px; }
.flare-form-sheet__description, .flare-form-sheet__error, .flare-form-sheet__actions { flex: none; }
/* Keep native disabled inheritance without a fieldset anonymous box preventing flex children from shrinking. */
.flare-form-sheet__fieldset { display: contents; border: 0; margin: 0; padding: 0; }
.flare-form-sheet__actions { display: flex; gap: 12px; }
.flare-form-sheet__actions > * { flex: 1; }
.flare-form-sheet__error { margin: 0; color: var(--flare-color-error-text); font-size: var(--flare-size-font-size-sm); }
.flare-form-sheet.is-fill { flex: 1 1 auto; min-height: 0; }
.flare-form-sheet.is-fill .flare-form-sheet__fields { flex: 1 1 auto; min-height: 0; overflow-y: auto; overscroll-behavior: contain; }
.flare-form-sheet.is-fill .flare-form-sheet__actions,
.flare-form-sheet.is-fill .flare-form-sheet__error { flex: none; }
</style>
