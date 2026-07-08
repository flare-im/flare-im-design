<script setup lang="ts">
import { computed } from "vue";
import { CheckmarkDoneOutline, CloseOutline, LibraryOutline, PinOutline, ShareSocialOutline, TrashOutline } from "@vicons/ionicons5";
import { NButton, NIcon } from "naive-ui";
import { useFlareI18n } from "../../shared/i18n";
const { t } = useFlareI18n();

const props = defineProps<{
  count: number;
  total: number;
  busy?: boolean;
}>();

const emit = defineEmits<{
  (event: "selectAll"): void;
  (event: "clear"): void;
  (event: "forwardSeparate"): void;
  (event: "forwardMerged"): void;
  (event: "pin"): void;
  (event: "pinSelf"): void;
  (event: "delete"): void;
  (event: "exit"): void;
}>();

const disabled = computed(() => props.busy || props.count === 0);
</script>

<template>
  <div class="message-batch-toolbar" role="toolbar" :aria-label="t('enhance.batchToolbar')">
    <div class="message-batch-toolbar__meta">
      <strong>{{ count }}</strong>
      <span>/ {{ total }} {{ t('enhance.selected') }}</span>
    </div>
    <div class="message-batch-toolbar__actions">
      <n-button size="small" quaternary :disabled="busy || total === 0" @click="emit('selectAll')">
        <template #icon><n-icon :component="CheckmarkDoneOutline" /></template>
        {{ t('enhance.selectAll') }}
      </n-button>
      <n-button size="small" quaternary :disabled="disabled" @click="emit('clear')">{{ t('enhance.clear') }}</n-button>
      <n-button size="small" secondary :disabled="disabled" @click="emit('forwardSeparate')">
        <template #icon><n-icon :component="ShareSocialOutline" /></template>
        {{ t('enhance.forwardEach') }}
      </n-button>
      <n-button size="small" secondary :disabled="busy || count < 2" @click="emit('forwardMerged')">
        <template #icon><n-icon :component="LibraryOutline" /></template>
        {{ t('enhance.forwardMerged') }}
      </n-button>
      <n-button size="small" secondary :disabled="disabled" @click="emit('pin')">
        <template #icon><n-icon :component="PinOutline" /></template>
        {{ t('enhance.pin') }}
      </n-button>
      <n-button size="small" secondary :disabled="disabled" @click="emit('pinSelf')">
        <template #icon><n-icon :component="PinOutline" /></template>
        {{ t('enhance.selfOnly') }}
      </n-button>
      <n-button size="small" tertiary type="error" :disabled="disabled" @click="emit('delete')">
        <template #icon><n-icon :component="TrashOutline" /></template>
        {{ t('enhance.delete') }}
      </n-button>
      <n-button circle quaternary :disabled="busy" :aria-label="t('enhance.exitMultiSelect')" @click="emit('exit')">
        <template #icon><n-icon :component="CloseOutline" /></template>
      </n-button>
    </div>
  </div>
</template>
