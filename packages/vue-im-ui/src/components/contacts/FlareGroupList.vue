<script setup lang="ts">
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import type { FlareGroupSummary } from "../../shared/contracts";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

defineProps<{ items: FlareGroupSummary[]; emptyText?: string; /** The group displayed in the adjacent detail pane. */ activeId?: string }>();
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
    <button v-for="g in items" :key="g.id" type="button" class="flare-group-list__row" :class="{ 'is-current': g.id === activeId }" :aria-current="g.id === activeId ? 'true' : undefined" @click="emit('select', g)">
      <FlareAvatar :user-id="g.id" :display-name="g.name" :avatar-url="g.avatarUrl" :size="40" />
      <div class="flare-group-list__body">
        <div class="flare-group-list__name" :title="g.name">{{ g.name }}</div>
        <div class="flare-group-list__count">{{ t("group.memberCount", { count: g.memberCount ?? 0 }) }}</div>
      </div>
    </button>
  </div>
</template>

<style scoped>
.flare-group-list__row {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-md);
  width: 100%;
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-2md);
  border: 0;
  background: transparent;
  text-align: left;
  font: inherit;
  cursor: pointer;
}
.flare-group-list__row:hover,
.flare-group-list__row:focus-visible { background: var(--flare-color-bg-hover); }
.flare-group-list__row:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
.flare-group-list__name { color: var(--flare-color-text-primary); font-size: var(--flare-size-font-size-lg); font-weight: 500; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.flare-group-list__body { flex: 1; min-width: 0; }
.flare-group-list__row.is-current { background: var(--flare-color-bg-selected); box-shadow: inset 3px 0 var(--flare-color-primary); }
.flare-group-list__row.is-current .flare-group-list__name { color: var(--flare-color-primary-text); font-weight: 600; }
.flare-group-list__count { font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-tertiary); }
</style>
