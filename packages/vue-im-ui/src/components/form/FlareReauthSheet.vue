<script setup lang="ts">
import { computed } from "vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareInput from "../general/FlareInput.vue";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";
import FlareFormField from "./FlareFormField.vue";
import FlareSelect from "./FlareSelect.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareReauthDestination } from "../../shared/contracts/reauth";
const props = withDefaults(defineProps<{ open?: boolean; title?: string; subtitle?: string; destinations: FlareReauthDestination[]; selectedId: string; code: string; codeLength?: number; sending?: boolean; submitting?: boolean; canSend: boolean; canSubmit: boolean; resendInSeconds?: number; error?: string; notice?: string }>(), { open: true, codeLength: 6, sending: false, submitting: false, resendInSeconds: 0 });
const emit = defineEmits<{ selectDestination: [id: string]; changeCode: [value: string]; send: []; submit: []; cancel: [] }>();
const { t } = useFlareI18n();
const busy = computed(() => props.sending || props.submitting);
const destination = computed(() => props.destinations.find(item => item.id === props.selectedId));
const canSend = computed(() => props.canSend && Boolean(destination.value) && !busy.value && props.resendInSeconds <= 0);
const canSubmit = computed(() => props.canSubmit && Boolean(destination.value) && !busy.value);
function send() { if (canSend.value) emit("send"); }
function submit() { if (canSubmit.value) emit("submit"); }
</script>
<template>
  <FlareBottomSheet :open="open" :title="title || t('reauth.title')" show-close @close="open && emit('cancel')">
    <div class="flare-reauth-sheet" :aria-busy="busy">
      <p v-if="subtitle" class="flare-reauth-sheet__subtitle">{{ subtitle }}</p>
      <FlareStatusBanner v-if="notice" :text="notice" tone="info" />
      <FlareStatusBanner v-if="error" :text="error" tone="danger" />
      <FlareStatusBanner v-if="!destinations.length" :text="t('reauth.unavailable')" tone="warning" />
      <FlareFormField :label="t('reauth.destination')" :hint="destination?.detail">
        <FlareSelect :options="destinations.map(item => ({ value: item.id, label: item.label }))" :model-value="selectedId" :disabled="busy || !destinations.length" @update:model-value="emit('selectDestination', $event)" />
      </FlareFormField>
      <FlareFormField :label="t('reauth.code')">
        <FlareInput :model-value="code" :max-length="codeLength" :show-count="false" :disabled="busy" autocomplete="one-time-code" inputmode="numeric" monospace @update:model-value="emit('changeCode', $event)" @submit="submit" />
      </FlareFormField>
      <FlareButton :label="resendInSeconds > 0 ? t('reauth.resendIn', { seconds: Math.ceil(resendInSeconds) }) : t('reauth.sendCode')" variant="secondary" :disabled="!canSend" :loading="sending" block @click="send" />
      <FlareButton :label="t('common.confirm')" :disabled="!canSubmit" :loading="submitting" block @click="submit" />
      <FlareButton :label="t('common.cancel')" variant="quiet" block @click="emit('cancel')" />
    </div>
  </FlareBottomSheet>
</template>
<style scoped>
.flare-reauth-sheet { display: flex; flex-direction: column; gap: var(--flare-size-spacing-md); padding: var(--flare-size-spacing-lg); }
.flare-reauth-sheet__subtitle { margin: 0; color: var(--flare-color-text-secondary); overflow-wrap: anywhere; }
</style>
