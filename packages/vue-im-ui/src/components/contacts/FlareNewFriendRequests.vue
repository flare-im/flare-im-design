<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareButton from "../general/FlareButton.vue";
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
      <!-- 按**人**取色,不按申请取色:`id` 是这条申请的 id,拿它配色会让同一个人在这份列表里
           和在别处是两种颜色。 -->
      <FlareAvatar :user-id="r.userId || r.id" :display-name="r.name" :avatar-url="r.avatarUrl" :size="44" />
      <div class="flare-new-friends__body" @click="emit('view', r)">
        <div class="flare-new-friends__name">{{ r.name }}</div>
        <div v-if="r.message" class="flare-new-friends__msg">{{ r.message }}</div>
      </div>
      <div class="flare-new-friends__actions">
        <template v-if="r.direction === 'outgoing'">
          <span class="flare-new-friends__status">{{ t('newFriends.pending') }}</span>
          <FlareButton
            v-if="canWithdraw"
            variant="quiet"
            size="sm"
            :label="withdrawLabel || t('newFriends.withdraw')"
            @click="emit('withdraw', r)"
          />
        </template>
        <template v-else>
          <!-- 一条申请只有一个主动作。拒绝与接受原来是两颗等重的描边按钮,并排吃掉 375 宽里的
               130px,名字只剩 155px 还不截断;而「拒绝」本来就是次要出口,不该和「接受」抢眼。 -->
          <FlareButton variant="quiet" size="sm" :label="t('newFriends.decline')" @click="emit('reject', r)" />
          <FlareButton size="sm" :label="t('newFriends.accept')" @click="emit('accept', r)" />
        </template>
      </div>
    </div>
  </div>
</template>

<style scoped>
.flare-new-friends__row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: var(--flare-size-spacing-2sm) var(--flare-size-spacing-2md);
}
.flare-new-friends__body { flex: 1; min-width: 0; cursor: pointer; }
.flare-new-friends__name {
  color: var(--flare-color-text-primary);
  font-size: var(--flare-size-font-size-lg);
  font-weight: 500;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-new-friends__msg {
  font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-tertiary);
  overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}
.flare-new-friends__status {
  flex: none;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-secondary);
}
/* 动作自成一组,组内 8px(与三个原生端的 spacingSm 同值),与名字之间才是行的 12px。 */
.flare-new-friends__actions {
  display: flex;
  flex: none;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
}
</style>
