<script setup lang="ts">
import { NAvatar } from "naive-ui";
defineProps<{
  label: string;
  name: string;
  description?: string;
  avatarUrl?: string;
  selected?: boolean;
}>();
</script>
<template>
  <span
    class="flare-admin-entity-label"
    :class="{ 'flare-admin-entity-label--selected': selected }"
    :title="label"
  >
    <NAvatar
      class="flare-admin-entity-label__avatar"
      :size="selected ? 20 : 28"
      round
      :src="avatarUrl"
      :img-props="{
        referrerpolicy: 'no-referrer',
      }"
      aria-hidden="true"
    >
      <template v-if="!avatarUrl" #default>{{ Array.from(name)[0] }}</template>
      <template #fallback>{{ Array.from(name)[0] }}</template>
    </NAvatar>
    <span class="flare-admin-entity-label__name">{{ name }}</span>
    <span
      v-if="description && !selected"
      class="flare-admin-entity-label__description"
      >{{ description }}</span
    >
  </span>
</template>
<style scoped>
.flare-admin-entity-label {
  display: inline-flex;
  align-items: center;
  flex-wrap: nowrap;
  gap: var(--flare-size-spacing-sm, 8px);
  width: 100%;
  max-width: 100%;
  min-width: 0;
  vertical-align: middle;
  white-space: nowrap;
  padding-block: var(--flare-size-spacing-xs, 4px);
}
.flare-admin-entity-label__avatar {
  flex-shrink: 0;
}
.flare-admin-entity-label__name,
.flare-admin-entity-label__description {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-admin-entity-label__name {
  flex: 1;
}
.flare-admin-entity-label__description {
  flex: 0 1 auto;
  max-width: 45%;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-xs, 11px);
}
.flare-admin-entity-label--selected {
  padding-block: 0;
}
</style>
