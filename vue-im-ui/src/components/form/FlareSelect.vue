<script setup lang="ts">
import { ref, computed, onBeforeUnmount } from "vue";
import { NIcon } from "naive-ui";
import { ChevronDownOutline, CheckmarkOutline } from "@vicons/ionicons5";
import type { FlareSelectOption, FlareControlSize } from "../../shared/contracts";

const props = withDefaults(
  defineProps<{
    options: FlareSelectOption[];
    placeholder?: string;
    disabled?: boolean;
    size?: FlareControlSize;
  }>(),
  { placeholder: "", disabled: false, size: "md" },
);
const value = defineModel<string>({ default: "" });
const emit = defineEmits<{ (e: "change", value: string): void }>();

const open = ref(false);
const root = ref<HTMLElement | null>(null);
const current = computed(() => props.options.find((o) => o.value === value.value));

function toggle(): void {
  if (props.disabled) return;
  open.value = !open.value;
}
function pick(o: FlareSelectOption): void {
  if (o.disabled) return;
  value.value = o.value;
  emit("change", o.value);
  open.value = false;
}
function onDocClick(e: MouseEvent): void {
  if (root.value && !root.value.contains(e.target as Node)) open.value = false;
}
if (typeof document !== "undefined") document.addEventListener("click", onDocClick);
onBeforeUnmount(() => {
  if (typeof document !== "undefined") document.removeEventListener("click", onDocClick);
});
</script>

<template>
  <div ref="root" class="flare-select" :class="[`flare-select--${size}`, { 'is-open': open, 'is-disabled': disabled }]">
    <button type="button" class="flare-select__trigger" :disabled="disabled" @click.stop="toggle">
      <span class="flare-select__value" :class="{ 'is-placeholder': !current }">{{ current ? current.label : placeholder }}</span>
      <n-icon :size="16" :component="ChevronDownOutline" class="flare-select__chevron" />
    </button>
    <transition name="flare-select-pop">
      <ul v-if="open" class="flare-select__menu" role="listbox">
        <li
          v-for="o in options"
          :key="o.value"
          class="flare-select__option"
          :class="{ 'is-selected': o.value === value, 'is-disabled': o.disabled }"
          role="option"
          :aria-selected="o.value === value"
          @click="pick(o)"
        >
          <span>{{ o.label }}</span>
          <n-icon v-if="o.value === value" :size="15" :component="CheckmarkOutline" />
        </li>
      </ul>
    </transition>
  </div>
</template>

<style scoped>
.flare-select { position: relative; display: inline-block; min-width: 160px; }
.flare-select__trigger {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  border: 1px solid var(--flare-color-border-primary, #e9e6f1);
  border-radius: var(--flare-size-radius-lg, 10px);
  background: var(--flare-color-bg-secondary, #f6f5fb);
  color: var(--flare-color-text-primary, #15131c);
  cursor: pointer;
  transition: border-color var(--flare-transition-fast, 150ms ease), box-shadow var(--flare-transition-fast, 150ms ease);
}
.flare-select--sm .flare-select__trigger { height: 32px; padding: 0 10px; font-size: 13px; }
.flare-select--md .flare-select__trigger { height: 40px; padding: 0 12px; font-size: 14px; }
.flare-select--lg .flare-select__trigger { height: 48px; padding: 0 14px; font-size: 15px; }
.flare-select.is-open .flare-select__trigger {
  border-color: var(--flare-color-primary, #7c3aed);
  box-shadow: 0 0 0 3px var(--flare-color-focus-ring, rgba(124, 58, 237, 0.28));
}
.flare-select.is-disabled { opacity: 0.55; }
.flare-select.is-disabled .flare-select__trigger { cursor: not-allowed; }
.flare-select__value { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.flare-select__value.is-placeholder { color: var(--flare-color-text-tertiary, #a7a2b4); }
.flare-select__chevron { color: var(--flare-color-text-tertiary, #a7a2b4); flex: 0 0 auto; transition: transform var(--flare-transition-fast, 150ms ease); }
.flare-select.is-open .flare-select__chevron { transform: rotate(180deg); }
.flare-select__menu {
  position: absolute;
  z-index: 20;
  top: calc(100% + 4px);
  left: 0;
  right: 0;
  list-style: none;
  margin: 0;
  padding: 4px;
  max-height: 240px;
  overflow-y: auto;
  border-radius: var(--flare-size-radius-lg, 10px);
  background: var(--flare-color-bg-primary, #fff);
  border: 1px solid var(--flare-color-border-primary, #e9e6f1);
  box-shadow: var(--flare-shadow-lg, 0 12px 28px rgba(21, 18, 32, 0.16));
}
.flare-select__option {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  padding: 8px 10px;
  border-radius: var(--flare-size-radius-md, 8px);
  font-size: 14px;
  color: var(--flare-color-text-primary, #15131c);
  cursor: pointer;
}
.flare-select__option:hover:not(.is-disabled) { background: var(--flare-color-bg-secondary, #f6f5fb); }
.flare-select__option.is-selected { color: var(--flare-color-primary, #7c3aed); font-weight: 500; }
.flare-select__option.is-disabled { opacity: 0.45; cursor: not-allowed; }
.flare-select-pop-enter-active, .flare-select-pop-leave-active { transition: opacity 0.14s ease, transform 0.14s ease; }
.flare-select-pop-enter-from, .flare-select-pop-leave-to { opacity: 0; transform: translateY(-4px); }
</style>
