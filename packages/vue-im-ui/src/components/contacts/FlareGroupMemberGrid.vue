<script setup lang="ts">
import { flareIcons } from "../../shared/icons";
import { computed, getCurrentInstance } from "vue";
import { NIcon } from "naive-ui";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareContact } from "../../shared/contracts";

const props = withDefaults(
  defineProps<{
    members: FlareContact[];
    ownerId?: string;
    adminIds?: string[];
    showAdd?: boolean;
    columns?: number;
    /** Members in the group when `members` is a preview of the first few. */
    total?: number;
  }>(),
  { adminIds: () => [], showAdd: true, columns: 5 },
);
const emit = defineEmits<{
  (e: "select", id: string): void;
  (e: "addMember"): void;
  /** Open the full roster. The head becomes the entry to it only when the host handles this. */
  (e: "viewAll"): void;
}>();

const instance = getCurrentInstance();
// 同 FlareProfilePanel：宿主接了才画成可点的入口，没接就还是一行说明文字。
const opensRoster = computed(() => Boolean(instance?.vnode.props?.onViewAll));

const { t } = useFlareI18n();
const roleFor = (m: FlareContact) => {
  if (m.id === props.ownerId) return t("group.owner");
  if (props.adminIds.includes(m.id)) return t("group.admin");
  return "";
};
// minmax(0, 1fr): a long nickname truncates inside its cell instead of widening the column.
const gridStyle = computed(() => ({ gridTemplateColumns: `repeat(${props.columns}, minmax(0, 1fr))` }));
</script>

<template>
  <div class="flare-member-grid">
    <component
      :is="opensRoster ? 'button' : 'div'"
      :type="opensRoster ? 'button' : undefined"
      class="flare-member-grid__head"
      :class="{ 'is-interactive': opensRoster }"
      :aria-label="opensRoster ? t('group.membersTitle', { count: total ?? members.length }) : undefined"
      @click="opensRoster && emit('viewAll')"
    >
      <span class="flare-member-grid__title">{{ t("group.members") }}</span>
      <span class="flare-member-grid__count">{{ t("group.memberCount", { count: total ?? members.length }) }}</span>
      <span v-if="opensRoster" class="flare-member-grid__chev">
        <n-icon aria-hidden="true" :size="16" :component="flareIcons['chevron-right']" />
      </span>
    </component>
    <div class="flare-member-grid__grid" :style="gridStyle">
      <button
        v-for="m in members"
        :key="m.id"
        type="button"
        class="flare-member-grid__cell"
        :title="m.name"
        @click="emit('select', m.id)"
      >
        <FlareAvatar :user-id="m.id" :display-name="m.name" :avatar-url="m.avatarUrl" :size="48" />
        <span v-if="roleFor(m)" class="flare-member-grid__role" :class="{ 'is-owner': m.id === ownerId }">
          {{ roleFor(m) }}
        </span>
        <span class="flare-member-grid__name">{{ m.name }}</span>
      </button>

      <button v-if="showAdd" type="button" class="flare-member-grid__cell flare-member-grid__add" @click="emit('addMember')">
        <span class="flare-member-grid__add-icon"><n-icon aria-hidden="true" :size="22" :component="flareIcons['add']" /></span>
        <span class="flare-member-grid__name">{{ t("group.addMember") }}</span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.flare-member-grid {
  padding: 16px;
}
/* 组名 + 人数。人数原来只是一行说明文字，同时「群成员 / N 名成员」在下面的设置列表里
   又整行重复了一遍 —— 现在这一行就是打开完整成员名单的入口，那一行随之去掉。 */
.flare-member-grid__head {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
  width: 100%;
  margin-bottom: var(--flare-size-spacing-xs);
  padding: 0;
  border: 0;
  background: none;
  font: inherit;
  text-align: start;
}
.flare-member-grid__head.is-interactive {
  /* 它替掉的是一整行设置行，触达区得跟那一行一样够得着。 */
  min-height: var(--flare-size-layout-touch-target);
  cursor: pointer;
}
.flare-member-grid__head.is-interactive:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: 2px;
  border-radius: var(--flare-size-radius-sm);
}
.flare-member-grid__title {
  font-size: 14px;
  font-weight: 600;
  color: var(--flare-color-text-primary);
}
.flare-member-grid__count {
  margin-inline-start: auto;
  font-size: 12px;
  color: var(--flare-color-text-tertiary);
}
.flare-member-grid__chev {
  display: inline-flex;
  align-items: center;
  color: var(--flare-color-text-tertiary);
}
.flare-member-grid__grid {
  display: grid;
  gap: var(--flare-size-spacing-2md) var(--flare-size-spacing-2sm);
}
.flare-member-grid__cell {
  position: relative;
  min-width: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  padding: 0;
  border: 0;
  background: none;
  cursor: pointer;
}
.flare-member-grid__role {
  position: absolute;
  top: 34px;
  padding: 1px 6px;
  border-radius: 999px;
  font-size: var(--flare-size-font-size-2xs);
  line-height: 1.4;
  /* A neutral chip, not white on a text colour: `text-tertiary` is light enough in dark mode
     that white on it reads at 2.54:1. The owner chip below keeps its colour. */
  color: var(--flare-color-text-secondary);
  background: var(--flare-color-bg-tertiary);
}
.flare-member-grid__role.is-owner {
  /* The coloured chip carries its own foreground: the neutral one above would read at 1.2:1 on it. */
  color: #fff;
  background: var(--flare-color-warning);
}
.flare-member-grid__name {
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 12px;
  color: var(--flare-color-text-secondary);
}
.flare-member-grid__add-icon {
  display: grid;
  place-items: center;
  width: 48px;
  height: 48px;
  border-radius: 50%;
  color: var(--flare-color-text-tertiary);
  border: 1px dashed var(--flare-color-border-hover);
  transition: color var(--flare-transition-fast), border-color var(--flare-transition-fast);
}
.flare-member-grid__add:hover .flare-member-grid__add-icon {
  color: var(--flare-color-primary-text);
  border-color: var(--flare-color-primary);
}
</style>
