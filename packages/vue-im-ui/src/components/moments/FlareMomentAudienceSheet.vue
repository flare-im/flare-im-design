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
import { computed } from "vue";
import { NButton, NIcon } from "naive-ui";
import {
  CheckmarkOutline,
  EarthOutline,
  EyeOffOutline,
  LockClosedOutline,
  PeopleOutline,
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
  { value: "friends", key: "friends", icon: PeopleOutline },
  { value: "public", key: "public", icon: EarthOutline },
  { value: "private", key: "private", icon: LockClosedOutline },
] as const;

// 私密时名单没有意义：没人看得到，加减谁都不改变结果。留着入口只会让人
// 以为自己设了什么。
const audienceApplies = computed(() => flareMomentAudienceApplies(props.visibility));

const selected = computed(() => new Set(props.audienceUserIds));

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
    <header class="flare-moment-audience__title">{{ t("momentAudience.title") }}</header>

    <ul class="flare-moment-audience__options">
      <li
        v-for="opt in VISIBILITY"
        :key="opt.value"
        class="flare-moment-audience__row"
        :class="{ 'is-active': visibility === opt.value }"
        @click="emit('update:visibility', opt.value)"
      >
        <NIcon aria-hidden="true" :size="16"><component :is="opt.icon" /></NIcon>
        <div class="flare-moment-audience__labels">
          <span>{{ t(`momentAudience.${opt.key}`) }}</span>
          <small>{{ t(`momentAudience.${opt.key}Hint`) }}</small>
        </div>
        <NIcon aria-hidden="true" v-if="visibility === opt.value" :size="16" class="flare-moment-audience__check">
          <CheckmarkOutline />
        </NIcon>
      </li>
    </ul>

    <template v-if="audienceApplies">
      <ul class="flare-moment-audience__options">
        <li
          class="flare-moment-audience__row is-include"
          :class="{ 'is-active': audienceMode === 'include' }"
          @click="pickMode('include')"
        >
          <NIcon aria-hidden="true" :size="16"><PersonAddOutline /></NIcon>
          <div class="flare-moment-audience__labels">
            <span>{{ t("momentAudience.include") }}</span>
            <small>{{ t("momentAudience.includeHint") }}</small>
          </div>
          <span v-if="audienceMode === 'include'" class="flare-moment-audience__count">
            {{ t("momentAudience.selected", { count: audienceUserIds.length }) }}
          </span>
        </li>
        <li
          class="flare-moment-audience__row is-exclude"
          :class="{ 'is-active': audienceMode === 'exclude' }"
          @click="pickMode('exclude')"
        >
          <NIcon aria-hidden="true" :size="16"><EyeOffOutline /></NIcon>
          <div class="flare-moment-audience__labels">
            <span>{{ t("momentAudience.exclude") }}</span>
            <small>{{ t("momentAudience.excludeHint") }}</small>
          </div>
          <span v-if="audienceMode === 'exclude'" class="flare-moment-audience__count">
            {{ t("momentAudience.selected", { count: audienceUserIds.length }) }}
          </span>
        </li>
      </ul>

      <div v-if="audienceMode !== 'everyone'" class="flare-moment-audience__picker">
        <div class="flare-moment-audience__picker-head">{{ t("momentAudience.pick") }}</div>
        <div
          v-for="c in contacts"
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
        </div>
      </div>
    </template>

    <footer class="flare-moment-audience__foot">
      <NButton size="small" type="primary" @click="emit('close')">
        {{ t("momentAudience.done") }}
      </NButton>
    </footer>
  </section>
</template>

<style scoped>
.flare-moment-audience__title {
  padding: var(--flare-size-spacing-md);
  font-size: var(--flare-size-font-size-lg);
  color: var(--flare-color-text-primary);
}

.flare-moment-audience__options {
  margin: 0;
  padding: 0;
  list-style: none;
  border-top: 1px solid var(--flare-color-border-primary);
}

.flare-moment-audience__row {
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
  max-height: 240px;
  overflow-y: auto;
  border-top: 1px solid var(--flare-color-border-primary);
}

.flare-moment-audience__picker-head {
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-tertiary);
}

.flare-moment-audience__contact {
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

.flare-moment-audience__foot {
  display: flex;
  justify-content: flex-end;
  padding: var(--flare-size-spacing-md);
  border-top: 1px solid var(--flare-color-border-primary);
}
</style>
