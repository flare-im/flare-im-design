<script setup lang="ts">
import { computed } from "vue";
import { NIcon } from "naive-ui";
import { AddOutline } from "../../shared/icon-glyphs";
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
}>();

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
    <div class="flare-member-grid__head">
      <span class="flare-member-grid__title">{{ t("group.members") }}</span>
      <span class="flare-member-grid__count">{{ t("group.memberCount", { count: total ?? members.length }) }}</span>
    </div>
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
        <span class="flare-member-grid__add-icon"><n-icon aria-hidden="true" :size="22" :component="AddOutline" /></span>
        <span class="flare-member-grid__name">{{ t("group.addMember") }}</span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.flare-member-grid {
  padding: 16px;
}
.flare-member-grid__head {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  margin-bottom: 14px;
}
.flare-member-grid__title {
  font-size: 14px;
  font-weight: 600;
  color: var(--flare-color-text-primary);
}
.flare-member-grid__count {
  font-size: 12px;
  color: var(--flare-color-text-tertiary);
}
.flare-member-grid__grid {
  display: grid;
  gap: 14px 10px;
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
  font-size: 10px;
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
