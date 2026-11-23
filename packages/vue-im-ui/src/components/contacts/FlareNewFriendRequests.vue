<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import type { FlareFriendRequest } from "../../shared/contracts";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

defineProps<{
  items: FlareFriendRequest[];
  emptyText?: string;
  /** Host-owned row status; one in-flight request does not disable other rows. */
  pendingActions?: Readonly<Record<string, "accept" | "reject">>;
  errors?: Readonly<Record<string, string>>;
  /** Label of the withdraw action on outgoing requests; defaults to the localized "Withdraw". */
  withdrawLabel?: string;
}>();
const emit = defineEmits<{
  (e: "accept", r: FlareFriendRequest): void;
  (e: "reject", r: FlareFriendRequest): void;
  (e: "view", r: FlareFriendRequest): void;
  (e: "withdraw", r: FlareFriendRequest): void;
  (e: "retry", r: FlareFriendRequest): void;
}>();
const { t } = useFlareI18n();
// Outgoing requests offer withdraw only when the host handles it.
const instance = getCurrentInstance();
const canWithdraw = computed(() => Boolean(instance?.vnode.props?.onWithdraw));
const canRetry = computed(() => Boolean(instance?.vnode.props?.onRetry));
const canView = computed(() => Boolean(instance?.vnode.props?.onView));
</script>

<template>
  <div class="flare-new-friends">
    <slot v-if="!items.length" name="empty"><FlareEmptyState icon="person-add" :title="emptyText || t('newFriends.empty')" /></slot>
    <div v-for="r in items" :key="r.id" class="flare-new-friends__entry">
    <div class="flare-new-friends__row" :aria-busy="Boolean(pendingActions?.[r.id])" :class="{ 'is-outgoing': r.direction === 'outgoing' }">
      <!-- 按**人**取色,不按申请取色:`id` 是这条申请的 id,拿它配色会让同一个人在这份列表里
           和在别处是两种颜色。 -->
      <FlareAvatar :user-id="r.userId || r.id" :display-name="r.name" :avatar-url="r.avatarUrl" :size="40" />
      <component
        :is="canView ? 'button' : 'div'"
        :type="canView ? 'button' : undefined"
        class="flare-new-friends__body"
        :class="{ 'is-interactive': canView }"
        @click="canView && emit('view', r)"
      >
        <span class="flare-new-friends__name" :title="r.name">{{ r.name }}</span>
        <span v-if="r.message" class="flare-new-friends__msg" :title="r.message">{{ r.message }}</span>
        <span v-if="r.source" class="flare-new-friends__source" :title="r.source" data-request-source="true">{{ r.source }}</span>
      </component>
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
          <FlareButton variant="quiet" size="sm" :loading="pendingActions?.[r.id] === 'reject'" :disabled="Boolean(pendingActions?.[r.id])" :label="t('newFriends.decline')" @click="emit('reject', r)" />
          <FlareButton size="sm" :loading="pendingActions?.[r.id] === 'accept'" :disabled="Boolean(pendingActions?.[r.id])" :label="t('newFriends.accept')" @click="emit('accept', r)" />
        </template>
      </div>
    </div>
    <FlareStatusBanner v-if="errors?.[r.id]" class="flare-new-friends__error" tone="danger" :text="errors[r.id]" :action-text="canRetry && !pendingActions?.[r.id] ? t('common.retry') : undefined" @action="emit('retry', r)" />
    </div>
  </div>
</template>

<style scoped>
.flare-new-friends__row {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-2sm);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-2md);
}
.flare-new-friends__body {
  flex: 1;
  min-width: 0;
  padding: 0;
  border: 0;
  background: transparent;
  font: inherit;
  text-align: start;
}
.flare-new-friends__body.is-interactive {
  min-height: var(--flare-size-layout-touch-target);
  cursor: pointer;
  border-radius: var(--flare-size-radius-sm);
}
.flare-new-friends__body.is-interactive:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: 2px;
}
.flare-new-friends__name {
  display: block;
  color: var(--flare-color-text-primary);
  font-size: var(--flare-size-font-size-lg);
  font-weight: 500;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-new-friends__msg {
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-secondary);
  overflow: hidden;
  overflow-wrap: anywhere;
}
/* 来源(「通过名片添加，由 X 推荐」)是另一件事:自己一行,不和验证消息挤在一行。 */
.flare-new-friends__source {
  display: block;
  font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-tertiary);
  overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}
.flare-new-friends__error { margin: 0 var(--flare-size-spacing-2md) var(--flare-size-spacing-sm); }
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
