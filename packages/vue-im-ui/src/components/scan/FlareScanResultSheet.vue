<script setup lang="ts">
import { reactive, watch } from "vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareInput from "../general/FlareInput.vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareScanSheetPhase, FlareScanHeader, FlareScanFact, FlareScanAction } from "../../shared/contracts/scan";
const props = withDefaults(defineProps<{ open?: boolean; phase: FlareScanSheetPhase; header: FlareScanHeader; facts?: FlareScanFact[]; notice?: string; actions?: FlareScanAction[]; busy?: boolean }>(), { open: true, facts: () => [], actions: () => [], busy: false });
const emit = defineEmits<{ action: [id: string, values: Record<string, string>]; dismiss: []; retry: [] }>();
const { t } = useFlareI18n();
const values = reactive<Record<string, Record<string, string>>>({});
watch(() => props.actions, () => { for (const key of Object.keys(values)) delete values[key]; for (const action of props.actions) values[action.id] = {}; }, { immediate: true });
function supported(action: FlareScanAction) { return (action.inputs || []).every(input => input.kind === 'text' && input.maxLen > 0); }
function submit(action: FlareScanAction) { if (props.busy || props.phase !== 'ready' || !supported(action)) return; const result: Record<string, string> = {}; for (const input of action.inputs || []) result[input.id] = (values[action.id]?.[input.id] || '').slice(0, input.maxLen); emit('action', action.id, result); }
</script>
<template>
  <FlareBottomSheet :open="open" :title="t('scan.result')" :dismissible="!busy" show-close @close="emit('dismiss')">
    <div class="flare-scan-result" :aria-busy="busy || phase === 'loading' || phase === 'slow'">
      <header class="flare-scan-result__header"><FlareAvatar :user-id="header.title" :display-name="header.title" :avatar-url="header.avatarUrl" :size="48" /><div><h2>{{ header.title }}</h2><p v-if="header.subtitle">{{ header.subtitle }}</p></div></header>
      <dl v-if="facts.length"><template v-for="(fact, index) in facts" :key="index"><dt>{{ fact.label }}</dt><dd>{{ fact.value }}</dd></template></dl>
      <FlareStatusBanner v-if="notice || phase !== 'ready'" :text="notice || t(`scan.phases.${phase}`)" :tone="phase === 'failed' || phase === 'unknown' ? 'warning' : 'info'" />
      <div v-for="action in actions" :key="action.id" class="flare-scan-result__action">
        <template v-for="input in action.inputs || []" :key="input.id"><label v-if="input.kind === 'text'" :for="`scan-${action.id}-${input.id}`">{{ input.label }}<FlareInput :id="`scan-${action.id}-${input.id}`" v-model="values[action.id]![input.id]" :max-length="input.maxLen" :disabled="busy" /></label></template>
        <p v-if="!supported(action)" role="status">{{ t('scan.upgradeRequired') }}</p>
        <FlareButton block :label="action.label" :variant="action.primary ? 'primary' : 'secondary'" :loading="busy" :disabled="phase !== 'ready' || !supported(action)" @click="submit(action)" />
      </div>
      <FlareButton v-if="['failed', 'offlineWaiting', 'unknown'].includes(phase)" block :label="t('common.retry')" :disabled="busy" @click="emit('retry')" />
      <slot />
    </div>
  </FlareBottomSheet>
</template>
<style scoped>
.flare-scan-result { display: flex; flex-direction: column; gap: var(--flare-size-spacing-md); padding: var(--flare-size-spacing-lg); overflow-wrap: anywhere; }
.flare-scan-result__header { display: flex; align-items: center; gap: var(--flare-size-spacing-md); }
.flare-scan-result h2 { font-size: var(--flare-size-font-size-xl); margin: 0; color: var(--flare-color-text-primary); }
.flare-scan-result p { color: var(--flare-color-text-secondary); margin: var(--flare-size-spacing-xs) 0; }
.flare-scan-result dl { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 2fr); gap: var(--flare-size-spacing-sm); margin: 0; }
.flare-scan-result dt { color: var(--flare-color-text-tertiary); }
.flare-scan-result dd { margin: 0; color: var(--flare-color-text-primary); white-space: pre-wrap; }
.flare-scan-result__action { display: flex; flex-direction: column; gap: var(--flare-size-spacing-sm); }
.flare-scan-result label { display: grid; gap: var(--flare-size-spacing-xs); color: var(--flare-color-text-secondary); }
</style>
