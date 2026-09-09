<script setup lang="ts">
import { computed } from 'vue';
import { transferActions, transferProgress, type TransferState, type TransferAction } from '../../shared/contracts/transfer';
const props = withDefaults(defineProps<{
  name: string; state: TransferState; statusText: string; progress?: number | null;
  actionLabels?: Partial<Record<TransferAction, string>>; busy?: boolean;
}>(), { progress: null, actionLabels: () => ({}), busy: false });
const emit = defineEmits<{ action: [action: TransferAction] }>();
const progressValue = computed(() => transferProgress(props.state, props.progress));
const actions = computed(() => transferActions[props.state].filter(a => props.actionLabels[a]?.trim()));
</script>
<template>
  <section class="flare-transfer" :aria-label="name" :aria-busy="busy">
    <strong class="flare-transfer__name">{{ name }}</strong>
    <span class="flare-transfer__status" role="status">{{ statusText }}</span>
    <progress v-if="progressValue !== null || state === 'transferring'" :value="progressValue ?? undefined" max="1" :aria-label="name + ' — ' + statusText" />
    <div v-if="actions.length" class="flare-transfer__actions">
      <button v-for="action in actions" :key="action" type="button" :disabled="busy" @click="!busy && emit('action', action)">{{ actionLabels[action] }}</button>
    </div>
  </section>
</template>
<style scoped>
.flare-transfer { box-sizing: border-box; display: grid; gap: 8px; min-width: 0; width: 100%; padding: 12px; border: 1px solid var(--flare-color-border-primary); border-radius: 10px; background: var(--flare-color-bg-primary); color: var(--flare-color-text-primary); }
.flare-transfer__name { font-size: 14px; font-weight: 600; overflow-wrap: anywhere; }
.flare-transfer__status { font-size: 13px; color: var(--flare-color-text-secondary); overflow-wrap: anywhere; }
progress { appearance: none; width: 100%; height: 6px; border: 0; border-radius: 3px; overflow: hidden; background: var(--flare-color-bg-tertiary); }
progress::-webkit-progress-bar { background: var(--flare-color-bg-tertiary); }
progress::-webkit-progress-value { background: var(--flare-color-primary); }
progress::-moz-progress-bar { background: var(--flare-color-primary); }
.flare-transfer__actions { display: flex; flex-wrap: wrap; gap: 8px; }
button { min-width: 48px; min-height: 48px; max-width: 100%; padding: 8px 12px; border: 1px solid var(--flare-color-border-primary); border-radius: 8px; background: transparent; color: var(--flare-color-text-primary); font: inherit; overflow-wrap: anywhere; cursor: pointer; }
button:focus-visible { outline: 2px solid var(--flare-color-primary); outline-offset: 2px; }
button:disabled { opacity: .5; cursor: default; }
</style>
