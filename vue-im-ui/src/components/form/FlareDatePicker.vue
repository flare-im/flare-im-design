<script setup lang="ts">
import { ref, computed, onBeforeUnmount } from "vue";
import { NIcon } from "naive-ui";
import { CalendarOutline } from "../../shared/icon-glyphs";
import type { FlareControlSize } from "../../shared/contracts";
import { useFlareConfig } from "../../shared/useFlareConfig";
import { useFlareAdaptiveSafe } from "../../composables/useAdaptiveMode";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareCalendarBody from "./FlareCalendarBody.vue";

const props = withDefaults(
  defineProps<{
    placeholder?: string;
    disabled?: boolean;
    /** Falls back to the global config size when omitted. */
    size?: FlareControlSize;
    /** Earliest selectable date "YYYY-MM-DD". */
    min?: string;
    /** Latest selectable date "YYYY-MM-DD". */
    max?: string;
    /** Sheet header title on mobile (defaults to placeholder). */
    title?: string;
  }>(),
  { placeholder: "", disabled: false },
);
/** v-model as "YYYY-MM-DD". */
const value = defineModel<string>({ default: "" });
const emit = defineEmits<{ (e: "change", value: string): void }>();

const config = useFlareConfig();
const rsize = computed(() => props.size ?? config.size.value);
const locale = computed(() => config.locale.value);
const adaptive = useFlareAdaptiveSafe();
const asSheet = computed(() => adaptive.isH5.value);

const pad = (n: number) => String(n).padStart(2, "0");
const now = new Date();
const todayStr = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;

const open = ref(false);
const root = ref<HTMLElement | null>(null);
const viewY = ref(now.getFullYear());
const viewM = ref(now.getMonth());

function show(): void {
  if (props.disabled) return;
  const d = value.value ? new Date(`${value.value}T00:00:00`) : now;
  if (!Number.isNaN(d.getTime())) {
    viewY.value = d.getFullYear();
    viewM.value = d.getMonth();
  }
  open.value = true;
}
function close(): void { open.value = false; }
function nav(delta: number): void {
  const m = viewM.value + delta;
  viewY.value += Math.floor(m / 12);
  viewM.value = ((m % 12) + 12) % 12;
}
function pick(dateStr: string): void {
  value.value = dateStr;
  emit("change", dateStr);
  open.value = false;
}
function goToday(): void {
  viewY.value = now.getFullYear();
  viewM.value = now.getMonth();
  pick(todayStr);
}
// Outside-click (capture phase) + Escape for the desktop popover only.
function onDocPointer(e: MouseEvent): void {
  if (asSheet.value || !open.value) return;
  if (root.value && !root.value.contains(e.target as Node)) open.value = false;
}
function onDocKey(e: KeyboardEvent): void {
  if (e.key === "Escape" && !asSheet.value && open.value) open.value = false;
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
  <div ref="root" class="flare-dp" :class="[`flare-dp--${rsize}`, { 'is-open': open, 'is-disabled': disabled }]">
    <button type="button" class="flare-dp__trigger" :disabled="disabled" @click.stop="show">
      <n-icon :size="16" :component="CalendarOutline" class="flare-dp__icon" />
      <span class="flare-dp__value" :class="{ 'is-placeholder': !value }">{{ value || placeholder }}</span>
    </button>

    <!-- Desktop: anchored popover -->
    <transition v-if="!asSheet" name="flare-dp-pop">
      <div v-if="open" class="flare-dp__pop" @click.stop>
        <FlareCalendarBody
          :year="viewY" :month="viewM" :selected="value" :today="todayStr" :min="min" :max="max" :locale="locale"
          @pick="pick" @nav="nav" @today="goToday" @cancel="close"
        />
      </div>
    </transition>

    <!-- Phone / native app: bottom sheet -->
    <FlareBottomSheet v-if="asSheet" :open="open" :title="title || placeholder || undefined" max-height="80vh" @close="close">
      <div class="flare-dp__sheet">
        <FlareCalendarBody
          :year="viewY" :month="viewM" :selected="value" :today="todayStr" :min="min" :max="max" :locale="locale"
          @pick="pick" @nav="nav" @today="goToday" @cancel="close"
        />
      </div>
    </FlareBottomSheet>
  </div>
</template>

<style scoped>
.flare-dp { position: relative; display: inline-block; min-width: 150px; }
.flare-dp__trigger {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 8px;
  border: 1px solid var(--flare-color-border-primary, #e9e6f1);
  border-radius: var(--flare-size-radius-lg, 10px);
  background: var(--flare-color-bg-secondary, #f6f5fb);
  color: var(--flare-color-text-primary, #15131c);
  cursor: pointer;
  transition: border-color var(--flare-transition-fast, 150ms ease), box-shadow var(--flare-transition-fast, 150ms ease);
}
.flare-dp--sm .flare-dp__trigger { height: 32px; padding: 0 10px; font-size: 13px; }
.flare-dp--md .flare-dp__trigger { height: 40px; padding: 0 12px; font-size: 14px; }
.flare-dp--lg .flare-dp__trigger { height: 48px; padding: 0 14px; font-size: 15px; }
.flare-dp.is-open .flare-dp__trigger {
  border-color: var(--flare-color-primary, #7c3aed);
  box-shadow: 0 0 0 3px var(--flare-color-focus-ring, rgba(124, 58, 237, 0.28));
}
.flare-dp.is-disabled { opacity: 0.55; }
.flare-dp.is-disabled .flare-dp__trigger { cursor: not-allowed; }
.flare-dp__icon { color: var(--flare-color-text-tertiary, #a7a2b4); flex: 0 0 auto; }
.flare-dp__value { font-variant-numeric: tabular-nums; }
.flare-dp__value.is-placeholder { color: var(--flare-color-text-tertiary, #a7a2b4); }

.flare-dp__pop {
  position: absolute;
  z-index: 20;
  top: calc(100% + 6px);
  left: 0;
  border-radius: var(--flare-size-radius-lg, 12px);
  background: var(--flare-color-bg-primary, #fff);
  border: 1px solid var(--flare-color-border-primary, #e9e6f1);
  box-shadow: var(--flare-shadow-lg, 0 12px 28px rgba(21, 18, 32, 0.16));
}
.flare-dp__sheet { padding: 2px 6px 6px; }

.flare-dp-pop-enter-active, .flare-dp-pop-leave-active { transition: opacity 0.14s ease, transform 0.14s ease; }
.flare-dp-pop-enter-from, .flare-dp-pop-leave-to { opacity: 0; transform: translateY(-4px); }
</style>
