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
      <!-- key 必须挂在 <template> 上，不能挂在 <slot> 上。挂在 slot 出口上时
           Vue 无法对它做带 key 的 diff：items 每换一次引用，整个列表的 DOM
           就被销毁重建一遍。表现是列表闪、点击落空（元素在点击落地前已被换掉）。 -->
      <template v-for="item in items" :key="item.id">
        <slot
          name="item"
          :item="item"
          :active="item.id === activeId"
        />
      </template>
    </template>
  </div>
</template>

<style scoped>
.im-conv-list {
  display: flex;
  flex-direction: column;
  min-height: 0;
  overflow: auto;
  background: var(--im-bg-surface, var(--flare-color-bg-primary, #ffffff));
}

.im-conv-list__state {
  padding: 42px 16px;
  color: var(--im-text-secondary, var(--flare-color-text-secondary, #6b7280));
  font-size: 13px;
  text-align: center;
}
</style>
