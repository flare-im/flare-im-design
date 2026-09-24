<script setup lang="ts">
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import type { FlareGroupSummary } from "../../shared/contracts";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

defineProps<{ items: FlareGroupSummary[]; emptyText?: string }>();
const emit = defineEmits<{ (e: "select", g: FlareGroupSummary): void }>();
// Optional, not required: a group list is a standalone surface a host can mount on its own,
// and a missing provider must fall back to the kit's own strings, not throw.
const { t } = useFlareI18nOptional();
</script>

<template>
  <div class="flare-group-list">
    <slot v-if="!items.length" name="empty">
      <FlareEmptyState icon="people" :title="emptyText || t('group.empty')" />
    </slot>
    <button v-for="g in items" :key="g.id" type="button" class="flare-group-list__row" @click="emit('select', g)">
      <FlareAvatar :user-id="g.id" :display-name="g.name" :avatar-url="g.avatarUrl" :size="44" />
      <div>
        <div class="flare-group-list__name">{{ g.name }}</div>
        <div class="flare-group-list__count">{{ t("group.memberCount", { count: g.memberCount ?? 0 }) }}</div>
      </div>
    </button>
  </div>
</template>

<style scoped>
.flare-group-list__row {
  display: flex;
  align-items: center;
  gap: 12px;
  width: 100%;
  padding: var(--flare-size-spacing-2sm) var(--flare-size-spacing-2md);
  border: 0;
  background: transparent;
  text-align: left;
  font: inherit;
  cursor: pointer;
}
.flare-group-list__row:hover,
.flare-group-list__row:focus-visible { background: var(--flare-color-bg-hover); }
.flare-group-list__row:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
.flare-group-list__name { color: var(--flare-color-text-primary); font-size: var(--flare-size-font-size-lg); font-weight: 500; }
.flare-group-list__count { font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-tertiary); }
</style>
