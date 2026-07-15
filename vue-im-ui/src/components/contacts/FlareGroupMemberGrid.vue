<script setup lang="ts">
import { computed } from "vue";
import { NIcon } from "naive-ui";
import { AddOutline } from "@vicons/ionicons5";
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
const gridStyle = computed(() => ({ gridTemplateColumns: `repeat(${props.columns}, 1fr)` }));
</script>

<template>
  <div class="flare-member-grid">
    <div class="flare-member-grid__head">
      <span class="flare-member-grid__title">{{ t("group.members") }}</span>
      <span class="flare-member-grid__count">{{ t("group.memberCount", { count: members.length }) }}</span>
    </div>
    <div class="flare-member-grid__grid" :style="gridStyle">
      <button
        v-for="m in members"
        :key="m.id"
        type="button"
        class="flare-member-grid__cell"
        @click="emit('select', m.id)"
      >
        <FlareAvatar :user-id="m.id" :display-name="m.name" :avatar-url="m.avatarUrl" :size="48" />
        <span v-if="roleFor(m)" class="flare-member-grid__role" :class="{ 'is-owner': m.id === ownerId }">
          {{ roleFor(m) }}
        </span>
        <span class="flare-member-grid__name">{{ m.name }}</span>
      </button>

      <button v-if="showAdd" type="button" class="flare-member-grid__cell flare-member-grid__add" @click="emit('addMember')">
        <span class="flare-member-grid__add-icon"><n-icon :size="22" :component="AddOutline" /></span>
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
  color: var(--flare-color-text-primary, #15131c);
}
.flare-member-grid__count {
  font-size: 12px;
  color: var(--flare-color-text-tertiary, #a7a2b4);
}
.flare-member-grid__grid {
  display: grid;
  gap: 14px 10px;
}
.flare-member-grid__cell {
  position: relative;
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
  color: #fff;
  background: var(--flare-color-text-tertiary, #a7a2b4);
}
.flare-member-grid__role.is-owner {
  background: var(--flare-color-warning, #f59e0b);
}
.flare-member-grid__name {
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 12px;
  color: var(--flare-color-text-secondary, #6b6780);
}
.flare-member-grid__add-icon {
  display: grid;
  place-items: center;
  width: 48px;
  height: 48px;
  border-radius: 50%;
  color: var(--flare-color-text-tertiary, #a7a2b4);
  border: 1px dashed var(--flare-color-border-hover, #dad5e7);
  transition: color var(--flare-transition-fast, 150ms ease), border-color var(--flare-transition-fast, 150ms ease);
}
.flare-member-grid__add:hover .flare-member-grid__add-icon {
  color: var(--flare-color-primary, #7c3aed);
  border-color: var(--flare-color-primary, #7c3aed);
}
</style>
