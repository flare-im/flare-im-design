<script setup lang="ts">
import type { FlareConversationRowModel } from "../../shared/contracts/conversation";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

defineProps<{
  items: FlareConversationRowModel[];
  activeId?: string;
  loading?: boolean;
}>();

const { t } = useFlareI18n();
</script>

<template>
  <div class="im-conv-list" role="list">
    <div v-if="loading" class="im-conv-list__state">{{ t("conversation.loading") }}</div>
    <div v-else-if="!items.length" class="im-conv-list__state">
      <slot name="empty">{{ t("conversation.emptyTitle") }}</slot>
    </div>
    <template v-else>
      <slot
        v-for="item in items"
        :key="item.id"
        name="item"
        :item="item"
        :active="item.id === activeId"
      />
    </template>
  </div>
</template>

<style scoped>
.im-conv-list {
  display: flex;
  flex-direction: column;
  min-height: 0;
  overflow: auto;
  background: var(--im-bg-surface, #ffffff);
}

.im-conv-list__state {
  padding: 42px 16px;
  color: var(--im-text-secondary, #6b7280);
  font-size: 13px;
  text-align: center;
}
</style>
