<script setup lang="ts">
/**
 * 群公告已读条。
 *
 * 未确认时给确认按钮，确认后转为「x/y 已读」。
 *
 * **计数必须用服务端给的 readCount/memberCount。** 未读名单是截断的
 * （服务端最多返回前 200 个），拿它的长度反推未读数在大群里会显示错的
 * 数字 —— 而且这种错不会报错，只会一直显示错误值。
 */
import { computed } from "vue";
import { NButton, NIcon } from "naive-ui";
import { CheckmarkCircle, MegaphoneOutline } from "../../shared/icon-glyphs";
import { useFlareI18n } from "../../shared/i18n";

const props = defineProps<{
  readCount: number;
  memberCount: number;
  selfRead: boolean;
  /** 是否显示「查看未读」入口，一般仅管理员。 */
  canViewUnread?: boolean;
}>();

const emit = defineEmits<{
  (e: "confirm"): void;
  (e: "viewUnread"): void;
}>();

const { t } = useFlareI18n();

// 成员数为 0（数据未就绪）时不显示比例，避免闪现「0/0」。
const showCount = computed(() => props.memberCount > 0);
const allRead = computed(
  () => props.memberCount > 0 && props.readCount >= props.memberCount,
);
</script>

<template>
  <div class="flare-announcement-read-bar" :class="{ 'is-read': selfRead }">
    <NIcon class="flare-announcement-read-bar__icon" :size="16">
      <CheckmarkCircle v-if="selfRead" />
      <MegaphoneOutline v-else />
    </NIcon>

    <span v-if="showCount" class="flare-announcement-read-bar__count">
      {{ t("announcement.readCount", { read: readCount, total: memberCount }) }}
    </span>

    <div class="flare-announcement-read-bar__actions">
      <NButton
        v-if="!selfRead"
        size="tiny"
        type="primary"
        secondary
        @click="emit('confirm')"
      >
        {{ t("announcement.confirmRead") }}
      </NButton>
      <NButton
        v-if="canViewUnread && !allRead"
        size="tiny"
        quaternary
        @click="emit('viewUnread')"
      >
        {{ t("announcement.viewUnread") }}
      </NButton>
    </div>
  </div>
</template>

<style scoped>
.flare-announcement-read-bar {
  display: flex;
  align-items: center;
  gap: var(--flare-space-2, 8px);
  padding: var(--flare-space-2, 8px) var(--flare-space-3, 12px);
  border-radius: var(--flare-radius-md, 8px);
  background: var(--flare-color-surface-subtle, rgba(127, 127, 127, 0.08));
  font-size: var(--flare-font-size-sm, 13px);
  color: var(--flare-color-text-secondary, #666);
}

.flare-announcement-read-bar.is-read {
  color: var(--flare-color-text-tertiary, #999);
}

.flare-announcement-read-bar__icon {
  flex: none;
}

.flare-announcement-read-bar__count {
  flex: 1;
  min-width: 0;
}

.flare-announcement-read-bar__actions {
  display: flex;
  gap: var(--flare-space-1, 4px);
  flex: none;
}
</style>
