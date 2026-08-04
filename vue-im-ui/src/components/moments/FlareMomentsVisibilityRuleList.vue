<script setup lang="ts">
/**
 * 朋友圈可见性名单。
 *
 * 承载「不让他看我的」与「不看他的」两类规则的成员管理。
 *
 * **两类方向相反，同屏时必须视觉可分。** 设反了用户不会立刻察觉，
 * 却会造成「本想屏蔽对方，结果自己的动态对他可见」这类隐私后果 ——
 * 所以标题、空态文案、强调色都按 kind 分开，不共用一套措辞。
 */
import { computed } from "vue";
import { NButton, NEmpty, NIcon, NSkeleton } from "naive-ui";
import { EyeOffOutline, PersonAddOutline, VolumeMuteOutline } from "../../shared/icon-glyphs";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import { useFlareI18n } from "../../shared/i18n";
import type {
  FlareContactBrief,
  FlareMomentsVisibilityRuleKind,
} from "../../shared/contracts";

const props = defineProps<{
  kind: FlareMomentsVisibilityRuleKind;
  members: FlareContactBrief[];
  loading?: boolean;
}>();

const emit = defineEmits<{
  (e: "add"): void;
  (e: "remove", member: FlareContactBrief): void;
  (e: "selectMember", member: FlareContactBrief): void;
}>();

const { t } = useFlareI18n();

const isHideFrom = computed(() => props.kind === "hideFrom");

// 文案按 kind 完全分开 —— 共用一套会让两个方向读起来一样，正是设反的根源。
const title = computed(() =>
  t(isHideFrom.value ? "momentsVisibility.hideFromTitle" : "momentsVisibility.muteTitle"),
);
const hint = computed(() =>
  t(isHideFrom.value ? "momentsVisibility.hideFromHint" : "momentsVisibility.muteHint"),
);
</script>

<template>
  <section class="flare-moments-visibility" :class="`is-${kind}`">
    <header class="flare-moments-visibility__head">
      <NIcon :size="16" class="flare-moments-visibility__icon">
        <EyeOffOutline v-if="isHideFrom" />
        <VolumeMuteOutline v-else />
      </NIcon>
      <div class="flare-moments-visibility__titles">
        <div class="flare-moments-visibility__title">{{ title }}</div>
        <div class="flare-moments-visibility__hint">{{ hint }}</div>
      </div>
      <NButton size="tiny" quaternary @click="emit('add')">
        <template #icon>
          <NIcon><PersonAddOutline /></NIcon>
        </template>
      </NButton>
    </header>

    <div v-if="loading" class="flare-moments-visibility__body">
      <NSkeleton text :repeat="2" />
    </div>

    <NEmpty
      v-else-if="!members.length"
      size="small"
      :description="t('momentsVisibility.empty')"
      class="flare-moments-visibility__empty"
    />

    <ul v-else class="flare-moments-visibility__body">
      <li
        v-for="m in members"
        :key="m.userId"
        class="flare-moments-visibility__row"
        @click="emit('selectMember', m)"
      >
        <FlareAvatar :user-id="m.userId" :display-name="m.displayName" :avatar-url="m.avatarUrl" :size="32" />
        <span class="flare-moments-visibility__name">{{ m.displayName }}</span>
        <NButton size="tiny" quaternary @click.stop="emit('remove', m)">
          {{ t("momentsVisibility.remove") }}
        </NButton>
      </li>
    </ul>
  </section>
</template>

<style scoped>
.flare-moments-visibility__head {
  display: flex;
  align-items: flex-start;
  gap: var(--flare-space-2, 8px);
  padding: var(--flare-space-3, 12px);
}

.flare-moments-visibility__icon {
  margin-top: 2px;
  flex: none;
  color: var(--flare-color-text-secondary, #666);
}

/* 两类用不同强调色，让同屏时一眼可分。 */
.is-hideFrom .flare-moments-visibility__icon {
  color: var(--flare-color-warning, #d97706);
}

.is-mute .flare-moments-visibility__icon {
  color: var(--flare-color-text-tertiary, #999);
}

.flare-moments-visibility__titles {
  flex: 1;
  min-width: 0;
}

.flare-moments-visibility__title {
  font-size: var(--flare-font-size-md, 14px);
  color: var(--flare-color-text-primary, #222);
}

.flare-moments-visibility__hint {
  font-size: var(--flare-font-size-sm, 12px);
  color: var(--flare-color-text-tertiary, #999);
  margin-top: 2px;
}

.flare-moments-visibility__body {
  padding: 0 var(--flare-space-3, 12px) var(--flare-space-2, 8px);
  margin: 0;
  list-style: none;
}

.flare-moments-visibility__row {
  display: flex;
  align-items: center;
  gap: var(--flare-space-2, 8px);
  padding: var(--flare-space-1, 6px) 0;
  cursor: pointer;
}

.flare-moments-visibility__name {
  flex: 1;
  min-width: 0;
  font-size: var(--flare-font-size-md, 14px);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.flare-moments-visibility__empty {
  padding: var(--flare-space-4, 16px) 0;
}
</style>
