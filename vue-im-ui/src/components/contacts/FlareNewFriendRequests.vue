<script setup lang="ts">
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import type { FlareFriendRequest } from "../../shared/contracts";

defineProps<{ items: FlareFriendRequest[] }>();
const emit = defineEmits<{
  (e: "accept", r: FlareFriendRequest): void;
  (e: "reject", r: FlareFriendRequest): void;
  (e: "view", r: FlareFriendRequest): void;
}>();
</script>

<template>
  <div class="flare-new-friends">
    <FlareEmptyState v-if="!items.length" title="No new friend requests" />
    <div v-for="r in items" :key="r.id" class="flare-new-friends__row">
      <FlareAvatar :user-id="r.id" :display-name="r.name" :avatar-url="r.avatarUrl" :size="44" />
      <div class="flare-new-friends__body" @click="emit('view', r)">
        <div class="flare-new-friends__name">{{ r.name }}</div>
        <div v-if="r.message" class="flare-new-friends__msg">{{ r.message }}</div>
      </div>
      <button class="is-ghost" @click="emit('reject', r)">Decline</button>
      <button class="is-primary" @click="emit('accept', r)">Accept</button>
    </div>
  </div>
</template>

<style scoped>
.flare-new-friends__row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 14px;
}
.flare-new-friends__body { flex: 1; min-width: 0; cursor: pointer; }
.flare-new-friends__name { color: var(--flare-color-text-primary); font-weight: 500; }
.flare-new-friends__msg {
  font-size: 12px; color: var(--flare-color-text-tertiary);
  overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}
.flare-new-friends__row button {
  padding: 5px 14px;
  border-radius: var(--flare-size-radius-md, 6px);
  border: 1px solid var(--flare-color-border-primary);
  background: none;
  color: var(--flare-color-text-secondary);
  font-size: 13px;
  cursor: pointer;
}
.flare-new-friends__row button.is-primary {
  border-color: var(--flare-color-primary);
  background: var(--flare-color-primary);
  color: #fff;
}
</style>
