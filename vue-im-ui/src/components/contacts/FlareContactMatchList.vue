<script setup lang="ts">
/**
 * 通讯录匹配结果列表。
 *
 * 新用户上手的关键一屏：导入通讯录后，这里显示哪些联系人已经在用。
 *
 * 每条回显 `matchedBy`（命中的号码/邮箱）—— 匹配结果里的显示名可能是
 * 对方设的昵称，与通讯录里存的名字对不上；不回显号码，用户根本认不出这是谁。
 */
import { NButton, NEmpty, NSkeleton } from "naive-ui";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import { useFlareI18n } from "../../shared/i18n";
import type { FlareMatchedContact } from "../../shared/contracts";

defineProps<{
  matches: FlareMatchedContact[];
  loading?: boolean;
}>();

const emit = defineEmits<{
  (e: "addFriend", contact: FlareMatchedContact): void;
  (e: "openConversation", contact: FlareMatchedContact): void;
  (e: "selectContact", contact: FlareMatchedContact): void;
}>();

const { t } = useFlareI18n();
</script>

<template>
  <div class="flare-contact-match-list">
    <template v-if="loading">
      <div v-for="i in 3" :key="i" class="flare-contact-match-list__row">
        <NSkeleton circle :width="40" :height="40" />
        <NSkeleton text style="flex: 1" :repeat="2" />
      </div>
    </template>

    <NEmpty
      v-else-if="!matches.length"
      :description="t('contactMatch.empty')"
      class="flare-contact-match-list__empty"
    />

    <div
      v-for="c in matches"
      v-else
      :key="c.userId"
      class="flare-contact-match-list__row"
      @click="emit('selectContact', c)"
    >
      <FlareAvatar :user-id="c.userId" :display-name="c.displayName" :avatar-url="c.avatarUrl" :size="40" />
      <div class="flare-contact-match-list__meta">
        <div class="flare-contact-match-list__name">{{ c.displayName }}</div>
        <div class="flare-contact-match-list__matched">{{ c.matchedBy }}</div>
      </div>
      <NButton
        v-if="c.alreadyFriend"
        size="small"
        quaternary
        @click.stop="emit('openConversation', c)"
      >
        {{ t("contactMatch.message") }}
      </NButton>
      <NButton
        v-else
        size="small"
        type="primary"
        secondary
        @click.stop="emit('addFriend', c)"
      >
        {{ t("contactMatch.add") }}
      </NButton>
    </div>
  </div>
</template>

<style scoped>
.flare-contact-match-list__row {
  display: flex;
  align-items: center;
  gap: var(--flare-space-3, 12px);
  padding: var(--flare-space-2, 8px) var(--flare-space-3, 12px);
  border-radius: var(--flare-radius-md, 8px);
  cursor: pointer;
}

.flare-contact-match-list__row:hover {
  background: var(--flare-color-surface-hover, rgba(127, 127, 127, 0.08));
}

.flare-contact-match-list__meta {
  flex: 1;
  min-width: 0;
}

.flare-contact-match-list__name {
  font-size: var(--flare-font-size-md, 14px);
  color: var(--flare-color-text-primary, #222);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* 命中的号码用弱化色：它是辅助识别信息，不该抢主名的视觉权重。 */
.flare-contact-match-list__matched {
  font-size: var(--flare-font-size-sm, 12px);
  color: var(--flare-color-text-tertiary, #999);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.flare-contact-match-list__empty {
  padding: var(--flare-space-6, 24px) 0;
}
</style>
