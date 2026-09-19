<script setup lang="ts">
// Confirmation before something destructive. FR-042: the same confirmation, presented the way the
// platform presents things — a bottom sheet on a phone, a centered dialog on a pointer device — so a
// host never has to rebuild it as a sheet to look right on a phone. The events stay `confirm` and
// `cancel`: closing by scrim, Escape or the platform back is a cancel, and while `busy` it does not close.
import { computed } from "vue";
import { NButton, NModal, type ButtonProps } from "naive-ui";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { useFlareNativeBack } from "../../shared/platform/useFlareNativeBack";
import { useFlarePlatformSafe } from "../../shared/platform/useFlarePlatform";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";

const props = defineProps<{
  open: boolean;
  title: string;
  description: string;
  target: string;
  busy?: boolean;
  error?: string;
  confirmText?: string;
  cancelText?: string;
}>();
const { t } = useFlareI18n();
const platform = useFlarePlatformSafe();
const asSheet = computed(() => platform.capabilities.value.bottomSheet);
const strings = computed(() => ({
  confirmText: props.confirmText ?? t("dangerConfirm.confirm"),
  cancelText: props.cancelText ?? t("dangerConfirm.cancel"),
}));
const emit = defineEmits<{ confirm: []; cancel: [] }>();
const positiveProps = computed<ButtonProps & { "aria-label": string }>(() => ({ "aria-label": strings.value.confirmText, disabled: props.busy, type: "error", style: { minHeight: "48px" } }));
const negativeProps = computed<ButtonProps & { "aria-label": string }>(() => ({ "aria-label": strings.value.cancelText, disabled: props.busy, style: { minHeight: "48px" } }));
function confirm(): boolean { if (!props.busy) emit("confirm"); return false; }
function cancel(): boolean { if (!props.busy) emit("cancel"); return false; }
// On a sheet the platform back is claimed by FlareBottomSheet, which reports it as a close.
useFlareNativeBack(() => props.open && !asSheet.value, cancel);
</script>

<template>
  <FlareBottomSheet v-if="asSheet" :open="open" :title="title" :dismissible="!busy" @close="cancel">
    <div class="flare-danger-confirm" data-flare-presentation="sheet">
      <p>{{ description }}</p>
      <strong>{{ target }}</strong>
      <p v-if="error" role="alert" class="flare-danger-confirm__error">{{ error }}</p>
      <div class="flare-danger-confirm__actions">
        <n-button v-bind="negativeProps" block @click="cancel">{{ strings.cancelText }}</n-button>
        <n-button v-bind="positiveProps" block :loading="busy" @click="confirm">{{ strings.confirmText }}</n-button>
      </div>
    </div>
  </FlareBottomSheet>
  <NModal
    v-else
    style="width: min(440px, calc(100vw - 32px))"
    :show="open"
    preset="dialog"
    :title="title"
    :closable="!busy"
    :mask-closable="!busy"
    :close-on-esc="!busy"
    :positive-text="strings.confirmText"
    :negative-text="strings.cancelText"
    :positive-button-props="positiveProps"
    :negative-button-props="negativeProps"
    :loading="busy"
    @positive-click="confirm"
    @negative-click="cancel"
    @update:show="!$event && !busy && emit('cancel')"
  >
    <div class="flare-danger-confirm" data-flare-presentation="dialog">
      <p>{{ description }}</p>
      <strong>{{ target }}</strong>
      <p v-if="error" role="alert" class="flare-danger-confirm__error">{{ error }}</p>
    </div>
  </NModal>
</template>

<style scoped>
.flare-danger-confirm {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-sm);
}
.flare-danger-confirm__error {
  color: var(--flare-color-error-text);
}
/* On a sheet the keys are the sheet's own footer: full width, danger last, thumb-reachable. */
.flare-danger-confirm__actions {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-sm);
  margin-top: var(--flare-size-spacing-md);
}
</style>
