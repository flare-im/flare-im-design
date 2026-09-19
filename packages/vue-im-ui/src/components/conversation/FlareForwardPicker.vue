<script setup lang="ts">
import { computed, ref, watch } from "vue";
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
    busy?: boolean;
    /** Use inside a public form/sheet without a second frame or footer. */
    embedded?: boolean;
  }>(),
  { multiple: true, dismissible: true, busy: false, embedded: false },
);
const emit = defineEmits<{
  (e: "confirm", ids: string[]): void;
  (e: "close"): void;
}>();

const { t } = useFlareI18n();
const query = ref("");
const selected = defineModel<string[]>({ default: () => [] });
watch(() => props.targets, (targets) => {
  const ids = new Set(targets.map(target => target.id));
  const valid = selected.value.filter(id => ids.has(id));
  if (valid.length !== selected.value.length) selected.value = valid;
});

const filtered = computed(() => {
  const q = query.value.trim().toLowerCase();
  if (!q) return props.targets;
  return props.targets.filter(
    (x) => x.name.toLowerCase().includes(q) || x.subtitle?.toLowerCase().includes(q),
  );
});

function toggle(id: string): void {
  if (props.busy) return;
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
  <div class="flare-forward-picker" :class="{ 'is-embedded': embedded }" :aria-busy="busy">
    <header v-if="!embedded" class="flare-forward-picker__head">
      <span class="flare-forward-picker__title">{{ t("forwardPicker.title") }}</span>
      <button
        v-if="dismissible"
        type="button"
        class="flare-forward-picker__close"
        :aria-label="t('forwardPicker.close')"
        :disabled="busy"
        @click="emit('close')"
      >
        <n-icon aria-hidden="true" :size="18" :component="CloseOutline" />
      </button>
    </header>

    <div class="flare-forward-picker__search">
      <n-icon aria-hidden="true" :size="16" :component="SearchOutline" class="flare-forward-picker__search-ico" />
      <input v-model="query" type="text" class="flare-forward-picker__input" :disabled="busy" :aria-label="t('forwardPicker.search')" :placeholder="t('forwardPicker.search')" />
    </div>

    <div class="flare-forward-picker__list">
      <button
        v-for="tgt in filtered"
        :key="tgt.id"
        type="button"
        class="flare-forward-picker__row"
        :class="{ 'is-selected': isSelected(tgt.id) }"
        :aria-pressed="isSelected(tgt.id)"
        :disabled="busy"
        @click="toggle(tgt.id)"
      >
        <span class="flare-forward-picker__check" :class="{ 'is-on': isSelected(tgt.id) }">
          <n-icon aria-hidden="true" v-if="isSelected(tgt.id)" :size="13" :component="CheckmarkOutline" />
        </span>
        <FlareAvatar :user-id="tgt.id" :display-name="tgt.name" :avatar-url="tgt.avatarUrl" :size="38" />
        <span class="flare-forward-picker__body">
          <span class="flare-forward-picker__name">{{ tgt.name }}</span>
          <span v-if="tgt.subtitle" class="flare-forward-picker__sub">{{ tgt.subtitle }}</span>
        </span>
      </button>
      <FlareEmptyState v-if="filtered.length === 0" :title="t('forwardPicker.empty')" icon="search" />
    </div>

    <footer v-if="!embedded" class="flare-forward-picker__footer">
      <span class="flare-forward-picker__count">{{ t("forwardPicker.selected", { count: selected.length }) }}</span>
      <button
        type="button"
        class="flare-forward-picker__send"
        :disabled="busy || selected.length === 0"
        @click="emit('confirm', selected)"
      >
        {{ t("forwardPicker.send") }}
      </button>
    </footer>
  </div>
</template>

<style scoped>
.flare-forward-picker.is-embedded { width: 100%; border: 0; border-radius: 0; box-shadow: none; }
.flare-forward-picker__row:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
.flare-forward-picker {
  width: 340px;
  max-width: 100%;
  display: flex;
  flex-direction: column;
  border-radius: var(--flare-size-radius-xl);
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-primary);
  box-shadow: var(--flare-shadow-lg);
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
  color: var(--flare-color-text-primary);
}
.flare-forward-picker__close {
  border: none;
  background: transparent;
  color: var(--flare-color-text-tertiary);
  cursor: pointer;
  display: inline-flex;
}
.flare-forward-picker__search {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0 12px 4px;
  padding: 8px 10px;
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-secondary);
}
.flare-forward-picker__search-ico { color: var(--flare-color-text-tertiary); }
.flare-forward-picker__input {
  flex: 1;
  border: none;
  outline: none;
  background: transparent;
  font-size: 14px;
  color: var(--flare-color-text-primary);
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
  border-radius: var(--flare-size-radius-lg);
  background: transparent;
  cursor: pointer;
  text-align: left;
  transition: background var(--flare-transition-fast);
}
.flare-forward-picker__row:hover { background: var(--flare-color-bg-secondary); }
.flare-forward-picker__row.is-selected { background: var(--flare-color-bg-selected); }
.flare-forward-picker__check {
  width: 20px;
  height: 20px;
  flex: 0 0 auto;
  border-radius: 50%;
  border: 1.5px solid var(--flare-color-border-hover);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #fff;
}
.flare-forward-picker__check.is-on {
  border-color: var(--flare-color-primary);
  background: var(--flare-color-primary);
}
.flare-forward-picker__body { min-width: 0; display: flex; flex-direction: column; }
.flare-forward-picker__name {
  font-size: 14px;
  color: var(--flare-color-text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-forward-picker__sub {
  font-size: 12px;
  color: var(--flare-color-text-tertiary);
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
  border-top: 1px solid var(--flare-color-border-primary);
}
.flare-forward-picker__count {
  font-size: 13px;
  color: var(--flare-color-text-secondary);
}
.flare-forward-picker__send {
  height: 36px;
  padding: 0 20px;
  border: none;
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-component-brand-primary);
  color: #fff;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: filter var(--flare-transition-fast), opacity var(--flare-transition-fast);
}
.flare-forward-picker__send:hover:not(:disabled) { filter: brightness(0.97); }
.flare-forward-picker__send:disabled { opacity: 0.45; cursor: not-allowed; }
</style>
