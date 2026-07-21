<script setup lang="ts">
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import type { FlareGroupSummary } from "../../shared/contracts";

defineProps<{ items: FlareGroupSummary[]; emptyText?: string }>();
const emit = defineEmits<{ (e: "select", g: FlareGroupSummary): void }>();
</script>

<template>
  <div class="flare-group-list">
    <FlareEmptyState v-if="!items.length" icon="people" :title="emptyText || 'No groups yet'" />
    <div v-for="g in items" :key="g.id" class="flare-group-list__row" @click="emit('select', g)">
      <FlareAvatar :user-id="g.id" :display-name="g.name" :avatar-url="g.avatarUrl" :size="44" />
      <div>
        <div class="flare-group-list__name">{{ g.name }}</div>
        <div class="flare-group-list__count">{{ g.memberCount ?? 0 }} members</div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.flare-group-list__row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 14px;
  cursor: pointer;
}
.flare-group-list__name { color: var(--flare-color-text-primary); font-weight: 500; }
.flare-group-list__count { font-size: 12px; color: var(--flare-color-text-tertiary); }
</style>
