<script setup lang="ts">
import { ref, computed, onBeforeUnmount } from "vue";
import { NIcon } from "naive-ui";
import { ChevronDownOutline, CheckmarkOutline } from "@vicons/ionicons5";
import type { FlareSelectOption, FlareControlSize } from "../../shared/contracts";
import { useFlareConfig } from "../../shared/useFlareConfig";
import { useFlareAdaptiveSafe } from "../../composables/useAdaptiveMode";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";

const props = withDefaults(
  defineProps<{
    options: FlareSelectOption[];
    placeholder?: string;
    disabled?: boolean;
    /** Falls back to the global config size when omitted. */
    size?: FlareControlSize;
    /** Sheet header title on mobile presentation. */
    title?: string;
  }>(),
  { placeholder: "", disabled: false },
);
const value = defineModel<string>({ default: "" });
const emit = defineEmits<{ (e: "change", value: string): void }>();

const config = useFlareConfig();
const rsize = computed(() => props.size ?? config.size.value);
const adaptive = useFlareAdaptiveSafe();
// Desktop/tablet → anchored dropdown; phone (H5) / native app → bottom sheet.
const asSheet = computed(() => adaptive.isH5.value);

const open = ref(false);
const root = ref<HTMLElement | null>(null);
const current = computed(() => props.options.find((o) => o.value === value.value));

function toggle(): void {
  if (props.disabled) return;
  open.value = !open.value;
}
function close(): void {
  open.value = false;
}
function pick(o: FlareSelectOption): void {
  if (o.disabled) return;
  value.value = o.value;
  emit("change", o.value);
  open.value = false;
}
// Outside-click for the DESKTOP dropdown only (the sheet closes via its scrim).
// Capture phase so a click on another trigger — which stops propagation — still
// reaches here and closes this instance.
function onDocPointer(e: MouseEvent): void {
  if (asSheet.value || !open.value) return;
  if (root.value && !root.value.contains(e.target as Node)) close();
}
function onDocKey(e: KeyboardEvent): void {
  if (e.key === "Escape" && !asSheet.value && open.value) close();
}
if (typeof document !== "undefined") {
  document.addEventListener("click", onDocPointer, true);
  document.addEventListener("keydown", onDocKey);
}
onBeforeUnmount(() => {
  if (typeof document !== "undefined") {
    document.removeEventListener("click", onDocPointer, true);
    document.removeEventListener("keydown", onDocKey);
  }
});
</script>

<template>
  <div ref="root" class="flare-select" :class="[`flare-select--${rsize}`, { 'is-open': open, 'is-disabled': disabled }]">
    <button type="button" class="flare-select__trigger" :disabled="disabled" @click.stop="toggle">
      <span class="flare-select__value" :class="{ 'is-placeholder': !current }">{{ current ? current.label : placeholder }}</span>
      <n-icon :size="16" :component="ChevronDownOutline" class="flare-select__chevron" />
    </button>

    <!-- Desktop / tablet: anchored dropdown -->
    <transition v-if="!asSheet" name="flare-select-pop">
      <div v-if="open" class="flare-select__menu" role="listbox">
        <button
          v-for="o in options"
          :key="o.value"
          type="button"
          class="flare-select__option"
          :class="{ 'is-selected': o.value === value, 'is-disabled': o.disabled }"
          role="option"
          :aria-selected="o.value === value"
          :disabled="o.disabled"
          @click="pick(o)"
        >
          <span>{{ o.label }}</span>
          <n-icon v-if="o.value === value" :size="15" :component="CheckmarkOutline" />
        </button>
      </div>
    </transition>

    <!-- Phone / native app: bottom sheet -->
    <FlareBottomSheet v-if="asSheet" :open="open" :title="title || placeholder || undefined" @close="close">
      <div class="flare-select__list" role="listbox">
        <button
          v-for="o in options"
          :key="o.value"
          type="button"
          class="flare-select__option is-sheet"
          :class="{ 'is-selected': o.value === value, 'is-disabled': o.disabled }"
          role="option"
          :aria-selected="o.value === value"
          :disabled="o.disabled"
          @click="pick(o)"
        >
          <span>{{ o.label }}</span>
          <n-icon v-if="o.value === value" :size="19" :component="CheckmarkOutline" />
        </button>
      </div>
    </FlareBottomSheet>
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

/* Dropdown menu (desktop) */
.flare-select__menu {
  position: absolute;
  z-index: 20;
  top: calc(100% + 4px);
  left: 0;
  right: 0;
  padding: 4px;
  max-height: 240px;
  overflow-y: auto;
  border-radius: var(--flare-size-radius-lg, 10px);
  background: var(--flare-color-bg-primary, #fff);
  border: 1px solid var(--flare-color-border-primary, #e9e6f1);
  box-shadow: var(--flare-shadow-lg, 0 12px 28px rgba(21, 18, 32, 0.16));
}
/* Sheet option list */
.flare-select__list { padding: 0 4px 4px; overflow-y: auto; -webkit-overflow-scrolling: touch; }

.flare-select__option {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  border: none;
  background: transparent;
  text-align: left;
  font: inherit;
  padding: 8px 10px;
  border-radius: var(--flare-size-radius-md, 8px);
  font-size: 14px;
  color: var(--flare-color-text-primary, #15131c);
  cursor: pointer;
}
.flare-select__option:hover:not(.is-disabled),
.flare-select__option:focus-visible:not(.is-disabled) { background: var(--flare-color-bg-secondary, #f6f5fb); outline: none; }
.flare-select__option.is-selected { color: var(--flare-color-primary, #7c3aed); font-weight: 500; }
.flare-select__option.is-disabled { opacity: 0.45; cursor: not-allowed; }

.flare-select__option.is-sheet {
  gap: 10px;
  min-height: 52px;
  padding: 0 16px;
  border-radius: var(--flare-size-radius-lg, 12px);
  font-size: 16px;
}
.flare-select__option.is-sheet:active:not(.is-disabled) { background: var(--flare-color-bg-secondary, #f6f5fb); }
.flare-select__option.is-sheet.is-selected { font-weight: 600; }

.flare-select-pop-enter-active, .flare-select-pop-leave-active { transition: opacity 0.14s ease, transform 0.14s ease; }
.flare-select-pop-enter-from, .flare-select-pop-leave-to { opacity: 0; transform: translateY(-4px); }
</style>
