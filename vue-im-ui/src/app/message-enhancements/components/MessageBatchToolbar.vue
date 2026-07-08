<script setup lang="ts">
import { computed } from "vue";
import { CheckmarkDoneOutline, CloseOutline, LibraryOutline, PinOutline, ShareSocialOutline, TrashOutline } from "@vicons/ionicons5";
import { NButton, NIcon } from "naive-ui";

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
  <div class="message-batch-toolbar" role="toolbar" aria-label="批量消息操作">
    <div class="message-batch-toolbar__meta">
      <strong>{{ count }}</strong>
      <span>/ {{ total }} 已选</span>
    </div>
    <div class="message-batch-toolbar__actions">
      <n-button size="small" quaternary :disabled="busy || total === 0" @click="emit('selectAll')">
        <template #icon><n-icon :component="CheckmarkDoneOutline" /></template>
        全选
      </n-button>
      <n-button size="small" quaternary :disabled="disabled" @click="emit('clear')">清空</n-button>
      <n-button size="small" secondary :disabled="disabled" @click="emit('forwardSeparate')">
        <template #icon><n-icon :component="ShareSocialOutline" /></template>
        逐条转发
      </n-button>
      <n-button size="small" secondary :disabled="busy || count < 2" @click="emit('forwardMerged')">
        <template #icon><n-icon :component="LibraryOutline" /></template>
        合并转发
      </n-button>
      <n-button size="small" secondary :disabled="disabled" @click="emit('pin')">
        <template #icon><n-icon :component="PinOutline" /></template>
        置顶
      </n-button>
      <n-button size="small" secondary :disabled="disabled" @click="emit('pinSelf')">
        <template #icon><n-icon :component="PinOutline" /></template>
        仅自己
      </n-button>
      <n-button size="small" tertiary type="error" :disabled="disabled" @click="emit('delete')">
        <template #icon><n-icon :component="TrashOutline" /></template>
        删除
      </n-button>
      <n-button circle quaternary :disabled="busy" aria-label="退出多选" @click="emit('exit')">
        <template #icon><n-icon :component="CloseOutline" /></template>
      </n-button>
    </div>
  </div>
</template>
