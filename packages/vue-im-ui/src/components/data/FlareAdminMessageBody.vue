<script setup lang="ts">
import { NButton, NSpace, NText } from "naive-ui";
export interface FlareAdminAttachment {
  id: string;
  kind: string;
  name: string;
  size: number;
}
defineProps<{
  text?: string;
  attachments?: FlareAdminAttachment[];
  state: string;
  compact?: boolean;
  truncated?: boolean;
  disabled?: boolean;
  labels: {
    empty: string;
    recalled: string;
    unavailable: string;
    preview: string;
    download: string;
    more: string;
    kinds: Record<string, string>;
  };
}>();
const emit = defineEmits<{ preview: [string]; download: [string]; more: [] }>();
</script>
<template>
  <div class="flare-admin-message-body" :class="{ 'is-compact': compact }">
    <NText v-if="state !== 'available'" depth="3">{{
      state === "recalled" ? labels.recalled : labels.unavailable
    }}</NText>
    <template v-else>
      <p v-if="text" class="flare-admin-message-body__text">{{ text }}</p>
      <NText v-if="!text && !attachments?.length" depth="3">{{
        labels.empty
      }}</NText>
      <NSpace v-if="attachments?.length" :size="[8, 4]" :vertical="!compact">
        <NButton
          v-for="(item, index) in attachments"
          :key="item.id"
          size="small"
          text
          type="primary"
          :disabled="disabled"
          @click="
            item.kind === 'file'
              ? emit('download', item.id)
              : emit('preview', item.id)
          "
        >
          <span class="flare-admin-message-body__attachment"
            >{{ item.kind === "file" ? labels.download : labels.preview }} ·
            {{
              item.name ||
              `${labels.kinds[item.kind] || item.kind} ${index + 1}`
            }}<span v-if="item.size > 0">
              ({{ Math.ceil(item.size / 1024) }} KB)</span
            ></span
          >
        </NButton>
      </NSpace>
      <NButton
        v-if="truncated"
        size="small"
        text
        type="primary"
        :disabled="disabled"
        @click="emit('more')"
        >{{ labels.more }}</NButton
      >
    </template>
  </div>
</template>
<style scoped>
.flare-admin-message-body {
  min-width: 0;
  max-width: 100%;
}
.flare-admin-message-body__text {
  margin: 0 0 var(--flare-size-spacing-xs);
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}
.is-compact .flare-admin-message-body__text {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.flare-admin-message-body__attachment {
  display: inline-block;
  max-width: min(380px, 65vw);
  white-space: normal;
  overflow-wrap: anywhere;
  text-align: start;
}
</style>
