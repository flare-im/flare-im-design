<script setup lang="ts">
/**
 * The hour and minute columns with Cancel / Done: the body FlareTimePicker shows in its popover and its sheet, and the
 * one NotificationAlertSettings opens from a settings row. Not exported: it starts from `value` when it is created, so
 * its owner creates it each time the picker opens. Spec: Form/TimePicker.
 */
import { computed, nextTick, onMounted, ref } from "vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    /** The time it starts from, "HH:mm". */
    value: string;
    /** Minute granularity. */
    minuteStep?: number;
    /** The roomier sheet layout. */
    sheet?: boolean;
  }>(),
  { minuteStep: 5, sheet: false },
);
const emit = defineEmits<{ confirm: [value: string]; cancel: [] }>();
const { t } = useFlareI18n();

const pad = (n: number) => String(n).padStart(2, "0");
const hours = Array.from({ length: 24 }, (_, i) => i);
const step = computed(() => Math.max(1, Math.min(30, Math.round(props.minuteStep) || 1)));
const minutes = computed(() => Array.from({ length: Math.ceil(60 / step.value) }, (_, i) => i * step.value));

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

const initial = parse(props.value);
const th = ref(Math.min(23, Math.max(0, initial.h)));
const tm = ref(snapMinute(initial.m));
const hourCol = ref<HTMLElement | null>(null);
const minCol = ref<HTMLElement | null>(null);

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
onMounted(() => nextTick(scrollSelectedIntoView));

function confirm(): void {
  emit("confirm", `${pad(th.value)}:${pad(tm.value)}`);
}
</script>

<template>
  <div class="flare-tp__cols" :class="{ 'is-sheet': sheet }">
    <div ref="hourCol" class="flare-tp__col" role="listbox" :aria-label="t('timePicker.hour')">
      <button v-for="h in hours" :key="h" type="button" class="flare-tp__cell" :class="{ 'is-selected': h === th }" @click="th = h">{{ pad(h) }}</button>
    </div>
    <span class="flare-tp__sep">:</span>
    <div ref="minCol" class="flare-tp__col" role="listbox" :aria-label="t('timePicker.minute')">
      <button v-for="m in minutes" :key="m" type="button" class="flare-tp__cell" :class="{ 'is-selected': m === tm }" @click="tm = m">{{ pad(m) }}</button>
    </div>
  </div>
  <div class="flare-tp__footer" :class="{ 'is-sheet': sheet }">
    <button type="button" class="flare-tp__btn is-ghost" @click="emit('cancel')">{{ t("timePicker.cancel") }}</button>
    <button type="button" class="flare-tp__btn is-primary" @click="confirm">{{ t("timePicker.done") }}</button>
  </div>
</template>

<style scoped>
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
.flare-tp__sep { align-self: center; color: var(--flare-color-text-tertiary); font-weight: 600; }
.flare-tp__cell {
  flex: 0 0 auto;
  border: none;
  background: transparent;
  border-radius: var(--flare-size-radius-md);
  padding: 9px 0;
  font-size: 15px;
  font-variant-numeric: tabular-nums;
  color: var(--flare-color-text-secondary);
  cursor: pointer;
  transition: background var(--flare-transition-fast), color var(--flare-transition-fast);
}
.flare-tp__cols.is-sheet .flare-tp__cell { padding: 12px 0; font-size: 17px; }
.flare-tp__cell:hover { background: var(--flare-color-bg-secondary); color: var(--flare-color-text-primary); }
.flare-tp__cell.is-selected {
  background: var(--flare-color-bg-selected);
  color: var(--flare-color-primary-text);
  font-weight: 600;
}

.flare-tp__footer { display: flex; gap: 8px; padding: 8px; border-top: 1px solid var(--flare-color-border-primary); }
.flare-tp__footer.is-sheet { padding: var(--flare-size-spacing-2sm) 12px calc(12px + env(safe-area-inset-bottom, 0px)); }
.flare-tp__btn {
  flex: 1;
  height: 36px;
  border-radius: var(--flare-size-radius-lg);
  border: 1px solid transparent;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: filter var(--flare-transition-fast), background var(--flare-transition-fast);
}
.flare-tp__footer.is-sheet .flare-tp__btn { height: 44px; }
.flare-tp__btn.is-ghost {
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-secondary);
}
.flare-tp__btn.is-primary {
  background: var(--flare-component-brand-primary);
  color: #fff;
}
.flare-tp__btn.is-primary:hover { filter: brightness(0.97); }
</style>
