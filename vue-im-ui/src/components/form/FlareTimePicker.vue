<script setup lang="ts">
import { ref, computed, onBeforeUnmount, nextTick } from "vue";
import { NIcon } from "naive-ui";
import { TimeOutline } from "@vicons/ionicons5";
import type { FlareControlSize } from "../../shared/contracts";
import { useFlareConfig } from "../../shared/useFlareConfig";
import { useFlareAdaptiveSafe } from "../../composables/useAdaptiveMode";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";

const props = withDefaults(
  defineProps<{
    placeholder?: string;
    disabled?: boolean;
    /** Falls back to the global config size when omitted. */
    size?: FlareControlSize;
    /** Minute granularity. */
    minuteStep?: number;
    /** Sheet header title on mobile (defaults to placeholder). */
    title?: string;
  }>(),
  { placeholder: "", disabled: false, minuteStep: 5 },
);
/** v-model as "HH:mm". */
const value = defineModel<string>({ default: "" });
const emit = defineEmits<{ (e: "change", value: string): void }>();

const config = useFlareConfig();
const rsize = computed(() => props.size ?? config.size.value);
const zh = computed(() => config.locale.value === "zh-CN");
const adaptive = useFlareAdaptiveSafe();
const asSheet = computed(() => adaptive.isH5.value);

const pad = (n: number) => String(n).padStart(2, "0");
const hours = Array.from({ length: 24 }, (_, i) => i);
const step = computed(() => Math.max(1, Math.min(30, Math.round(props.minuteStep) || 1)));
const minutes = computed(() => Array.from({ length: Math.ceil(60 / step.value) }, (_, i) => i * step.value));

const open = ref(false);
const root = ref<HTMLElement | null>(null);
const th = ref(0);
const tm = ref(0);
const hourCol = ref<HTMLElement | null>(null);
const minCol = ref<HTMLElement | null>(null);

function parse(v: string): { h: number; m: number } {
  const [h, m] = v.split(":");
  return { h: Number(h) || 0, m: Number(m) || 0 };
}
/** Clamp to 0-59 and snap to the nearest step so a cell always matches. */
function snapMinute(m: number): number {
  const s = step.value;
  const last = minutes.value[minutes.value.length - 1];
  return Math.min(last, Math.max(0, Math.round(Math.min(59, Math.max(0, m)) / s) * s));
}

function scrollSelectedIntoView(): void {
  // Scroll ONLY within each column — never sel.scrollIntoView(), which bubbles to
  // window/ancestor scrollers and would jump the whole page.
  for (const col of [hourCol.value, minCol.value]) {
    const sel = col?.querySelector<HTMLElement>(".is-selected");
    if (!col || !sel) continue;
    const cr = col.getBoundingClientRect();
    const sr = sel.getBoundingClientRect();
    col.scrollTop += sr.top - cr.top - (col.clientHeight - sel.clientHeight) / 2;
  }
}

function show(): void {
  if (props.disabled) return;
  const { h, m } = parse(value.value);
  th.value = Math.min(23, Math.max(0, h));
  tm.value = snapMinute(m);
  open.value = true;
  nextTick(scrollSelectedIntoView);
}
function close(): void { open.value = false; }
function confirm(): void {
  const next = `${pad(th.value)}:${pad(tm.value)}`;
  value.value = next;
  emit("change", next);
  open.value = false;
}
// Outside-click for the DESKTOP popover only (capture phase → still fires when
// another trigger stops propagation). Escape closes the popover.
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
  <div ref="root" class="flare-tp" :class="[`flare-tp--${rsize}`, { 'is-open': open, 'is-disabled': disabled }]">
    <button type="button" class="flare-tp__trigger" :disabled="disabled" @click.stop="show">
      <n-icon :size="16" :component="TimeOutline" class="flare-tp__clock" />
      <span class="flare-tp__value" :class="{ 'is-placeholder': !value }">{{ value || placeholder }}</span>
    </button>

    <!-- Desktop: anchored popover -->
    <transition v-if="!asSheet" name="flare-tp-pop">
      <div v-if="open" class="flare-tp__pop" @click.stop>
        <div class="flare-tp__cols">
          <div ref="hourCol" class="flare-tp__col" role="listbox" :aria-label="zh ? '时' : 'Hour'">
            <button v-for="h in hours" :key="h" type="button" class="flare-tp__cell" :class="{ 'is-selected': h === th }" @click="th = h">{{ pad(h) }}</button>
          </div>
          <span class="flare-tp__sep">:</span>
          <div ref="minCol" class="flare-tp__col" role="listbox" :aria-label="zh ? '分' : 'Minute'">
            <button v-for="m in minutes" :key="m" type="button" class="flare-tp__cell" :class="{ 'is-selected': m === tm }" @click="tm = m">{{ pad(m) }}</button>
          </div>
        </div>
        <div class="flare-tp__footer">
          <button type="button" class="flare-tp__btn is-ghost" @click="close">{{ zh ? "取消" : "Cancel" }}</button>
          <button type="button" class="flare-tp__btn is-primary" @click="confirm">{{ zh ? "确定" : "Done" }}</button>
        </div>
      </div>
    </transition>

    <!-- Phone / native app: bottom sheet -->
    <FlareBottomSheet v-if="asSheet" :open="open" :title="title || placeholder || undefined" max-height="82vh" @close="close">
      <div class="flare-tp__cols is-sheet">
        <div ref="hourCol" class="flare-tp__col" role="listbox" :aria-label="zh ? '时' : 'Hour'">
          <button v-for="h in hours" :key="h" type="button" class="flare-tp__cell" :class="{ 'is-selected': h === th }" @click="th = h">{{ pad(h) }}</button>
        </div>
        <span class="flare-tp__sep">:</span>
        <div ref="minCol" class="flare-tp__col" role="listbox" :aria-label="zh ? '分' : 'Minute'">
          <button v-for="m in minutes" :key="m" type="button" class="flare-tp__cell" :class="{ 'is-selected': m === tm }" @click="tm = m">{{ pad(m) }}</button>
        </div>
      </div>
      <div class="flare-tp__footer is-sheet">
        <button type="button" class="flare-tp__btn is-ghost" @click="close">{{ zh ? "取消" : "Cancel" }}</button>
        <button type="button" class="flare-tp__btn is-primary" @click="confirm">{{ zh ? "确定" : "Done" }}</button>
      </div>
    </FlareBottomSheet>
  </div>
</template>

<style scoped>
.flare-tp { position: relative; display: inline-block; min-width: 130px; }
.flare-tp__trigger {
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
.flare-tp--sm .flare-tp__trigger { height: 32px; padding: 0 10px; font-size: 13px; }
.flare-tp--md .flare-tp__trigger { height: 40px; padding: 0 12px; font-size: 14px; }
.flare-tp--lg .flare-tp__trigger { height: 48px; padding: 0 14px; font-size: 15px; }
.flare-tp.is-open .flare-tp__trigger {
  border-color: var(--flare-color-primary, #7c3aed);
  box-shadow: 0 0 0 3px var(--flare-color-focus-ring, rgba(124, 58, 237, 0.28));
}
.flare-tp.is-disabled { opacity: 0.55; }
.flare-tp.is-disabled .flare-tp__trigger { cursor: not-allowed; }
.flare-tp__clock { color: var(--flare-color-text-tertiary, #a7a2b4); flex: 0 0 auto; }
.flare-tp__value { font-variant-numeric: tabular-nums; }
.flare-tp__value.is-placeholder { color: var(--flare-color-text-tertiary, #a7a2b4); }

/* Popover (desktop) */
.flare-tp__pop {
  position: absolute;
  z-index: 20;
  top: calc(100% + 6px);
  left: 0;
  border-radius: var(--flare-size-radius-lg, 12px);
  background: var(--flare-color-bg-primary, #fff);
  border: 1px solid var(--flare-color-border-primary, #e9e6f1);
  box-shadow: var(--flare-shadow-lg, 0 12px 28px rgba(21, 18, 32, 0.16));
  overflow: hidden;
}

.flare-tp__cols { display: flex; align-items: stretch; gap: 4px; padding: 8px; }
.flare-tp__cols.is-sheet { justify-content: center; padding: 6px 8px 4px; }
.flare-tp__col {
  display: flex;
  flex-direction: column;
  gap: 2px;
  width: 68px;
  max-height: 208px;
  overflow-y: auto;
  scroll-behavior: smooth;
  scrollbar-width: thin;
}
.flare-tp__cols.is-sheet .flare-tp__col { width: 96px; max-height: 240px; }
.flare-tp__sep { align-self: center; color: var(--flare-color-text-tertiary, #a7a2b4); font-weight: 600; }
.flare-tp__cell {
  flex: 0 0 auto;
  border: none;
  background: transparent;
  border-radius: var(--flare-size-radius-md, 8px);
  padding: 9px 0;
  font-size: 15px;
  font-variant-numeric: tabular-nums;
  color: var(--flare-color-text-secondary, #6b6780);
  cursor: pointer;
  transition: background var(--flare-transition-fast, 150ms ease), color var(--flare-transition-fast, 150ms ease);
}
.flare-tp__cols.is-sheet .flare-tp__cell { padding: 12px 0; font-size: 17px; }
.flare-tp__cell:hover { background: var(--flare-color-bg-secondary, #f6f5fb); color: var(--flare-color-text-primary, #15131c); }
.flare-tp__cell.is-selected {
  background: var(--flare-color-bg-selected, #f1eaff);
  color: var(--flare-color-primary, #7c3aed);
  font-weight: 600;
}

.flare-tp__footer { display: flex; gap: 8px; padding: 8px; border-top: 1px solid var(--flare-color-border-primary, #e9e6f1); }
.flare-tp__footer.is-sheet { padding: 10px 12px calc(12px + env(safe-area-inset-bottom, 0px)); }
.flare-tp__btn {
  flex: 1;
  height: 36px;
  border-radius: var(--flare-size-radius-lg, 10px);
  border: 1px solid transparent;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: filter var(--flare-transition-fast, 150ms ease), background var(--flare-transition-fast, 150ms ease);
}
.flare-tp__footer.is-sheet .flare-tp__btn { height: 44px; }
.flare-tp__btn.is-ghost {
  background: var(--flare-color-bg-secondary, #f6f5fb);
  color: var(--flare-color-text-secondary, #6b6780);
}
.flare-tp__btn.is-primary {
  background: var(--im-brand-gradient, var(--flare-color-primary, #7c3aed));
  color: #fff;
}
.flare-tp__btn.is-primary:hover { filter: brightness(0.97); }

.flare-tp-pop-enter-active, .flare-tp-pop-leave-active { transition: opacity 0.14s ease, transform 0.14s ease; }
.flare-tp-pop-enter-from, .flare-tp-pop-leave-to { opacity: 0; transform: translateY(-4px); }
</style>
