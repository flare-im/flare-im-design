<script setup lang="ts">
// The control bar of a failed call (§3.3): close and, when the host can, call again (recover).
import FlareButton from "../general/FlareButton.vue";
import { flareIcons } from "../../shared/icons";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

defineProps<{ mode: "audio" | "video"; redial: boolean; redialText?: string }>();
const emit = defineEmits<{ (e: "close"): void; (e: "redial"): void }>();
const { t } = useFlareI18n();
</script>

<template>
  <div class="flare-call-failed" data-call-failed="true">
    <FlareButton variant="secondary" size="lg" :label="t('common.close')" data-call-close="true" @click="emit('close')" />
    <FlareButton
      v-if="redial"
      variant="primary"
      size="lg"
      :icon="mode === 'video' ? flareIcons.video : flareIcons.phone"
      :label="redialText || t('call.redial')"
      data-call-redial="true"
      @click="emit('redial')"
    />
  </div>
</template>

<style scoped>
/* Phones: equal halves of the row. PC: each key component.callFailedActionWidth (160), centred. */
.flare-call-failed {
  display: grid;
  grid-auto-flow: column;
  grid-auto-columns: minmax(0, 1fr);
  gap: var(--flare-size-spacing-lg);
  width: 100%;
}
@media (min-width: 600px) {
  .flare-call-failed { grid-auto-columns: var(--flare-size-component-call-failed-action-width); justify-content: center; }
}
</style>
