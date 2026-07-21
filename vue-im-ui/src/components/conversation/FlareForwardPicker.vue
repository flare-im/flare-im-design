<script setup lang="ts">
import { computed, ref } from "vue";
import { NIcon } from "naive-ui";
import { SearchOutline, CheckmarkOutline, CloseOutline } from "../../shared/icon-glyphs";
import FlareAvatar from "./FlareAvatar.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareForwardTarget } from "../../shared/contracts";

const props = withDefaults(
  defineProps<{
    targets: FlareForwardTarget[];
    /** Allow selecting more than one destination. */
    multiple?: boolean;
    /** Header dismiss control. */
    dismissible?: boolean;
  }>(),
  { multiple: true, dismissible: true },
);
const emit = defineEmits<{
  (e: "confirm", ids: string[]): void;
  (e: "close"): void;
}>();

const { t } = useFlareI18n();
const query = ref("");
const selected = ref<string[]>([]);

const filtered = computed(() => {
  const q = query.value.trim().toLowerCase();
  if (!q) return props.targets;
  return props.targets.filter(
    (x) => x.name.toLowerCase().includes(q) || x.subtitle?.toLowerCase().includes(q),
  );
});

function toggle(id: string): void {
  if (!props.multiple) {
    selected.value = [id];
    return;
  }
  selected.value = selected.value.includes(id)
    ? selected.value.filter((x) => x !== id)
    : [...selected.value, id];
}
const isSelected = (id: string): boolean => selected.value.includes(id);
</script>

<template>
  <div class="flare-forward-picker">
    <header class="flare-forward-picker__head">
      <span class="flare-forward-picker__title">{{ t("forwardPicker.title") }}</span>
      <button
        v-if="dismissible"
        type="button"
        class="flare-forward-picker__close"
        :aria-label="t('forwardPicker.close')"
        @click="emit('close')"
      >
        <n-icon :size="18" :component="CloseOutline" />
      </button>
    </header>

    <div class="flare-forward-picker__search">
      <n-icon :size="16" :component="SearchOutline" class="flare-forward-picker__search-ico" />
      <input v-model="query" type="text" class="flare-forward-picker__input" :placeholder="t('forwardPicker.search')" />
    </div>

    <div class="flare-forward-picker__list">
      <button
        v-for="tgt in filtered"
        :key="tgt.id"
        type="button"
        class="flare-forward-picker__row"
        :class="{ 'is-selected': isSelected(tgt.id) }"
        @click="toggle(tgt.id)"
      >
        <span class="flare-forward-picker__check" :class="{ 'is-on': isSelected(tgt.id) }">
          <n-icon v-if="isSelected(tgt.id)" :size="13" :component="CheckmarkOutline" />
        </span>
        <FlareAvatar :user-id="tgt.id" :display-name="tgt.name" :avatar-url="tgt.avatarUrl" :size="38" />
        <span class="flare-forward-picker__body">
          <span class="flare-forward-picker__name">{{ tgt.name }}</span>
          <span v-if="tgt.subtitle" class="flare-forward-picker__sub">{{ tgt.subtitle }}</span>
        </span>
      </button>
      <FlareEmptyState v-if="filtered.length === 0" :title="t('forwardPicker.empty')" icon="🔍" />
    </div>

    <footer class="flare-forward-picker__footer">
      <span class="flare-forward-picker__count">{{ t("forwardPicker.selected", { count: selected.length }) }}</span>
      <button
        type="button"
        class="flare-forward-picker__send"
        :disabled="selected.length === 0"
        @click="emit('confirm', selected)"
      >
        {{ t("forwardPicker.send") }}
      </button>
    </footer>
  </div>
</template>

<style scoped>
.flare-forward-picker {
  width: 340px;
  max-width: 100%;
  display: flex;
  flex-direction: column;
  border-radius: var(--flare-size-radius-xl, 14px);
  background: var(--flare-color-bg-primary, #fff);
  border: 1px solid var(--flare-color-border-primary, #e9e6f1);
  box-shadow: var(--flare-shadow-lg, 0 12px 28px rgba(21, 18, 32, 0.16));
  overflow: hidden;
}
.flare-forward-picker__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 16px 8px;
}
.flare-forward-picker__title {
  font-size: 15px;
  font-weight: 600;
  color: var(--flare-color-text-primary, #15131c);
}
.flare-forward-picker__close {
  border: none;
  background: transparent;
  color: var(--flare-color-text-tertiary, #a7a2b4);
  cursor: pointer;
  display: inline-flex;
}
.flare-forward-picker__search {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0 12px 4px;
  padding: 8px 10px;
  border-radius: var(--flare-size-radius-lg, 10px);
  background: var(--flare-color-bg-secondary, #f6f5fb);
}
.flare-forward-picker__search-ico { color: var(--flare-color-text-tertiary, #a7a2b4); }
.flare-forward-picker__input {
  flex: 1;
  border: none;
  outline: none;
  background: transparent;
  font-size: 14px;
  color: var(--flare-color-text-primary, #15131c);
}
.flare-forward-picker__list {
  max-height: 300px;
  overflow-y: auto;
  padding: 4px 8px;
}
.flare-forward-picker__row {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 7px 8px;
  border: none;
  border-radius: var(--flare-size-radius-lg, 10px);
  background: transparent;
  cursor: pointer;
  text-align: left;
  transition: background var(--flare-transition-fast, 150ms ease);
}
.flare-forward-picker__row:hover { background: var(--flare-color-bg-secondary, #f6f5fb); }
.flare-forward-picker__row.is-selected { background: var(--flare-color-bg-selected, #f1eaff); }
.flare-forward-picker__check {
  width: 20px;
  height: 20px;
  flex: 0 0 auto;
  border-radius: 50%;
  border: 1.5px solid var(--flare-color-border-hover, #d5d1e0);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #fff;
}
.flare-forward-picker__check.is-on {
  border-color: var(--flare-color-primary, #7c3aed);
  background: var(--flare-color-primary, #7c3aed);
}
.flare-forward-picker__body { min-width: 0; display: flex; flex-direction: column; }
.flare-forward-picker__name {
  font-size: 14px;
  color: var(--flare-color-text-primary, #15131c);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-forward-picker__sub {
  font-size: 12px;
  color: var(--flare-color-text-tertiary, #a7a2b4);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-forward-picker__footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 10px 16px 14px;
  border-top: 1px solid var(--flare-color-border-primary, #e9e6f1);
}
.flare-forward-picker__count {
  font-size: 13px;
  color: var(--flare-color-text-secondary, #6b6780);
}
.flare-forward-picker__send {
  height: 36px;
  padding: 0 20px;
  border: none;
  border-radius: var(--flare-size-radius-lg, 10px);
  background: var(--im-brand-gradient, var(--flare-color-primary, #7c3aed));
  color: #fff;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: filter var(--flare-transition-fast, 150ms ease), opacity var(--flare-transition-fast, 150ms ease);
}
.flare-forward-picker__send:hover:not(:disabled) { filter: brightness(0.97); }
.flare-forward-picker__send:disabled { opacity: 0.45; cursor: not-allowed; }
</style>
