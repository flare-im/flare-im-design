<script setup lang="ts">
/**
 * 发动态时的「谁可以看」。
 *
 * 两层正交：`visibility` 圈定人群（公开/朋友/私密），`audienceMode` 在其上做加减
 * （部分可见 / 不给谁看）。
 *
 * **两个方向的出错后果不对称。** 把「部分可见」设成「不给谁看」，动态会发给
 * 你本想避开的所有人；反过来只是少给几个人看。所以两项不共用措辞，也不共用
 * 强调色 —— 一眼要能看出自己选的是哪一个。
 */
import { computed, ref } from "vue";
import { NIcon } from "naive-ui";
import FlareButton from "../general/FlareButton.vue";
import FlareSegmentedControl from "../general/FlareSegmentedControl.vue";
import FlareSearchBar from "../general/FlareSearchBar.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import {
  CheckmarkOutline,
  EyeOffOutline,
  PersonAddOutline,
} from "../../shared/icon-glyphs";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import { useFlareI18n } from "../../shared/i18n";
import type { FlareContactBrief } from "../../shared/contracts";
import {
  flareMomentAudienceApplies,
  type FlareMomentAudienceMode,
  type FlareMomentVisibility,
} from "../../shared/contracts/moments";

const props = defineProps<{
  visibility: FlareMomentVisibility;
  audienceMode: FlareMomentAudienceMode;
  audienceUserIds: string[];
  contacts: FlareContactBrief[];
  open?: boolean;
}>();

const emit = defineEmits<{
  (e: "update:visibility", v: FlareMomentVisibility): void;
  (e: "update:audience", payload: { mode: FlareMomentAudienceMode; userIds: string[] }): void;
  (e: "close"): void;
}>();

const { t } = useFlareI18n();

const VISIBILITY = [
  { value: "friends", key: "friends" },
  { value: "public", key: "public" },
  { value: "private", key: "private" },
] as const;

// 私密时名单没有意义：没人看得到，加减谁都不改变结果。留着入口只会让人
// 以为自己设了什么。
const audienceApplies = computed(() => flareMomentAudienceApplies(props.visibility));

const selected = computed(() => new Set(props.audienceUserIds));
const query = ref("");
const visibilityIndex = computed(() => VISIBILITY.findIndex(option => option.value === props.visibility));
const filteredContacts = computed(() => {
  const needle = query.value.trim().toLocaleLowerCase();
  return needle ? props.contacts.filter(contact => `${contact.displayName} ${contact.userId}`.toLocaleLowerCase().includes(needle)) : props.contacts;
});
function pickVisibility(index: number) { emit("update:visibility", VISIBILITY[index].value); }

function pickMode(mode: FlareMomentAudienceMode) {
  // 再点一次当前模式即取消，同时清空名单 —— 留着名单而把 mode 归零，
  // 下次切回来会突然冒出一份用户以为已经删掉的名单。
  const next = props.audienceMode === mode ? "everyone" : mode;
  emit("update:audience", { mode: next, userIds: next === "everyone" ? [] : props.audienceUserIds });
}

function toggle(c: FlareContactBrief) {
  const ids = new Set(props.audienceUserIds);
  if (ids.has(c.userId)) ids.delete(c.userId);
  else ids.add(c.userId);
  emit("update:audience", { mode: props.audienceMode, userIds: [...ids] });
}
</script>

<template>
  <section class="flare-moment-audience">
    <header class="flare-moment-audience__head">
      <h3 class="flare-moment-audience__title">{{ t("momentAudience.title") }}</h3>
      <FlareButton size="sm" :label="t('momentAudience.done')" @click="emit('close')" />
    </header>
    <div class="flare-moment-audience__visibility">
      <FlareSegmentedControl :model-value="visibilityIndex" :options="VISIBILITY.map(option => t(`momentAudience.${option.key}`))" :aria-label="t('momentAudience.title')" @update:model-value="pickVisibility" />
      <p class="flare-moment-audience__hint">{{ t(`momentAudience.${visibility}Hint`) }}</p>
    </div>

    <template v-if="audienceApplies">
      <ul class="flare-moment-audience__options">
        <li>
        <button
          type="button"
          :aria-pressed="audienceMode === 'include'"
          class="flare-moment-audience__row is-include"
          :class="{ 'is-active': audienceMode === 'include' }"
          @click="pickMode('include')"
        >
          <NIcon aria-hidden="true" :size="16"><PersonAddOutline /></NIcon>
          <span class="flare-moment-audience__labels">
            <span>{{ t("momentAudience.include") }}</span>
            <small>{{ t("momentAudience.includeHint") }}</small>
          </span>
          <NIcon v-if="audienceMode === 'include'" aria-hidden="true" :size="16" class="flare-moment-audience__check"><CheckmarkOutline /></NIcon>
        </button>
        </li>
        <li>
        <button
          type="button"
          :aria-pressed="audienceMode === 'exclude'"
          class="flare-moment-audience__row is-exclude"
          :class="{ 'is-active': audienceMode === 'exclude' }"
          @click="pickMode('exclude')"
        >
          <NIcon aria-hidden="true" :size="16"><EyeOffOutline /></NIcon>
          <span class="flare-moment-audience__labels">
            <span>{{ t("momentAudience.exclude") }}</span>
            <small>{{ t("momentAudience.excludeHint") }}</small>
          </span>
          <NIcon v-if="audienceMode === 'exclude'" aria-hidden="true" :size="16" class="flare-moment-audience__check"><CheckmarkOutline /></NIcon>
        </button>
        </li>
      </ul>

      <div v-if="audienceMode !== 'everyone'" class="flare-moment-audience__picker">
        <div class="flare-moment-audience__picker-head">
          <span>{{ t("momentAudience.pick") }}</span>
          <span class="flare-moment-audience__count" role="status">{{ t("momentAudience.selected", { count: audienceUserIds.length }) }}</span>
        </div>
        <div class="flare-moment-audience__search"><FlareSearchBar v-model="query" density="compact" /></div>
        <div class="flare-moment-audience__contacts">
        <FlareEmptyState v-if="!filteredContacts.length" :title="query.trim() ? t('search.empty') : t('contact.empty')" :description="query.trim() ? t('search.emptyHint') : undefined" icon="search" />
        <button
          v-for="c in filteredContacts"
          type="button"
          :aria-pressed="selected.has(c.userId)"
          :key="c.userId"
          class="flare-moment-audience__contact"
          :class="{ 'is-picked': selected.has(c.userId) }"
          @click="toggle(c)"
        >
          <FlareAvatar
            :user-id="c.userId"
            :display-name="c.displayName"
            :avatar-url="c.avatarUrl"
            :size="32"
          />
          <span class="flare-moment-audience__contact-name">{{ c.displayName }}</span>
          <NIcon aria-hidden="true" v-if="selected.has(c.userId)" :size="16" class="flare-moment-audience__check">
            <CheckmarkOutline />
          </NIcon>
        </button>
        </div>
      </div>
    </template>

  </section>
</template>

<style scoped>
.flare-moment-audience { min-width: 0; }
.flare-moment-audience__head { display: flex; align-items: center; justify-content: space-between; gap: var(--flare-size-spacing-sm); position: sticky; top: 0; z-index: 1; min-height: var(--flare-size-layout-touch-target); padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-md); box-sizing: border-box; background: var(--flare-color-bg-primary); }
.flare-moment-audience__title { margin: 0; font-size: var(--flare-size-font-size-md); color: var(--flare-color-text-primary); }
.flare-moment-audience__visibility { display: grid; gap: var(--flare-size-spacing-xs); padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md); }
.flare-moment-audience__hint { margin: 0; font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-secondary); }
.flare-moment-audience__search { padding: 0 var(--flare-size-spacing-md) var(--flare-size-spacing-xs); }
.flare-moment-audience__contacts { max-height: min(30dvh, 240px); overflow-y: auto; overscroll-behavior: contain; }

.flare-moment-audience__options {
  margin: 0;
  padding: 0;
  list-style: none;
  border-top: 1px solid var(--flare-color-border-primary);
}

.flare-moment-audience__row {
  width: 100%;
  min-height: var(--flare-size-layout-touch-target);
  border: 0;
  background: transparent;
  font: inherit;
  text-align: start;
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  cursor: pointer;
  color: var(--flare-color-text-secondary);
}

.flare-moment-audience__row:hover {
  background: var(--flare-color-bg-hover);
}

.flare-moment-audience__row.is-active {
  color: var(--flare-color-text-primary);
}

/* 两个方向分开着色：设反的后果不对称，得一眼看出选的是哪个。 */
.flare-moment-audience__row.is-include.is-active {
  color: var(--flare-color-primary-text);
}

.flare-moment-audience__row.is-exclude.is-active {
  color: var(--flare-color-warning-text);
}

.flare-moment-audience__labels {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
}

.flare-moment-audience__labels small {
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-tertiary);
}

.flare-moment-audience__count {
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-tertiary);
}

.flare-moment-audience__picker {
  border-top: 1px solid var(--flare-color-border-primary);
}

.flare-moment-audience__picker-head {
  display: flex; justify-content: space-between; gap: var(--flare-size-spacing-sm);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-secondary);
}

.flare-moment-audience__contact {
  width: 100%;
  min-height: var(--flare-size-layout-touch-target);
  border: 0;
  background: transparent;
  font: inherit;
  text-align: start;
  color: var(--flare-color-text-primary);
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  padding: 6px var(--flare-size-spacing-md);
  cursor: pointer;
}

.flare-moment-audience__contact.is-picked {
  background: var(--flare-color-bg-hover);
}

.flare-moment-audience__contact-name {
  flex: 1;
  min-width: 0;
  font-size: var(--flare-size-font-size-lg);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.flare-moment-audience__check {
  color: var(--flare-color-primary-text);
}

.flare-moment-audience__row:focus-visible,
.flare-moment-audience__contact:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: -2px;
}
</style>
