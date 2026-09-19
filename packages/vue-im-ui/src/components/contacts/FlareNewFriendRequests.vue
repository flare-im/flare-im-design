<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import type { FlareFriendRequest } from "../../shared/contracts";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

defineProps<{
  items: FlareFriendRequest[];
  emptyText?: string;
  /** Label of the withdraw action on outgoing requests; defaults to the localized "Withdraw". */
  withdrawLabel?: string;
}>();
const emit = defineEmits<{
  (e: "accept", r: FlareFriendRequest): void;
  (e: "reject", r: FlareFriendRequest): void;
  (e: "view", r: FlareFriendRequest): void;
  (e: "withdraw", r: FlareFriendRequest): void;
}>();
const { t } = useFlareI18n();
// Outgoing requests offer withdraw only when the host handles it.
const instance = getCurrentInstance();
const canWithdraw = computed(() => Boolean(instance?.vnode.props?.onWithdraw));
</script>

<template>
  <div class="flare-new-friends">
    <FlareEmptyState v-if="!items.length" icon="person-add" :title="emptyText || t('newFriends.empty')" />
    <div v-for="r in items" :key="r.id" class="flare-new-friends__row" :class="{ 'is-outgoing': r.direction === 'outgoing' }">
      <FlareAvatar :user-id="r.id" :display-name="r.name" :avatar-url="r.avatarUrl" :size="44" />
      <div class="flare-new-friends__body" @click="emit('view', r)">
        <div class="flare-new-friends__name">{{ r.name }}</div>
        <div v-if="r.message" class="flare-new-friends__msg">{{ r.message }}</div>
      </div>
      <template v-if="r.direction === 'outgoing'">
        <span class="flare-new-friends__status">{{ t('newFriends.pending') }}</span>
        <button v-if="canWithdraw" type="button" class="is-ghost" @click="emit('withdraw', r)">{{ withdrawLabel || t('newFriends.withdraw') }}</button>
      </template>
      <template v-else>
        <button type="button" class="is-ghost" @click="emit('reject', r)">{{ t('newFriends.decline') }}</button>
        <button type="button" class="is-primary" @click="emit('accept', r)">{{ t('newFriends.accept') }}</button>
      </template>
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
.flare-new-friends__name { color: var(--flare-color-text-primary); font-size: var(--flare-size-font-size-lg); font-weight: 500; }
.flare-new-friends__msg {
  font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-tertiary);
  overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}
.flare-new-friends__status {
  flex: none;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-secondary);
}
.flare-new-friends__row button {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 5px 14px;
  border-radius: var(--flare-size-radius-md);
  border: 1px solid var(--flare-color-border-primary);
  background: none;
  color: var(--flare-color-text-secondary);
  font-size: 13px;
  cursor: pointer;
}
/* The pill stays compact; the hit area still meets the touch target. */
.flare-new-friends__row button::after {
  content: "";
  position: absolute;
  width: max(100%, var(--flare-size-layout-touch-target));
  height: max(100%, var(--flare-size-layout-touch-target));
}
.flare-new-friends__row button:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: 2px;
}
.flare-new-friends__row button.is-primary {
  border-color: var(--flare-color-primary);
  background: var(--flare-color-primary);
  color: #fff;
}
</style>
