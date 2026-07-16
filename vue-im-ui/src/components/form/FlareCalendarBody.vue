<script setup lang="ts">
// Shared calendar grid used by FlareDatePicker in both the desktop popover and
// the mobile sheet — one implementation, so the two presentations never drift.
// Pure/presentational: the parent owns the view month + selection and reacts to
// the emitted events.
import { computed } from "vue";
import { NIcon } from "naive-ui";
import { ChevronBackOutline, ChevronForwardOutline } from "@vicons/ionicons5";

const props = defineProps<{
  /** Displayed year. */
  year: number;
  /** Displayed month, 0-11. */
  month: number;
  /** Selected date "YYYY-MM-DD" (or ""). */
  selected: string;
  /** Today "YYYY-MM-DD". */
  today: string;
  min?: string;
  max?: string;
  locale: "zh-CN" | "en-US";
}>();
const emit = defineEmits<{
  (e: "pick", date: string): void;
  (e: "nav", delta: number): void;
  (e: "today"): void;
  (e: "cancel"): void;
}>();

const zh = computed(() => props.locale === "zh-CN");
const pad = (n: number) => String(n).padStart(2, "0");
const weekdays = computed(() =>
  zh.value ? ["日", "一", "二", "三", "四", "五", "六"] : ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"],
);
const monthLabel = computed(() =>
  zh.value
    ? `${props.year}年${props.month + 1}月`
    : new Date(props.year, props.month, 1).toLocaleString("en-US", { month: "long", year: "numeric" }),
);
function dstr(d: number): string {
  return `${props.year}-${pad(props.month + 1)}-${pad(d)}`;
}
const weeks = computed(() => {
  const startDow = new Date(props.year, props.month, 1).getDay();
  const daysIn = new Date(props.year, props.month + 1, 0).getDate();
  const cells: (number | null)[] = [];
  for (let i = 0; i < startDow; i++) cells.push(null);
  for (let d = 1; d <= daysIn; d++) cells.push(d);
  while (cells.length % 7) cells.push(null);
  const out: (number | null)[][] = [];
  for (let i = 0; i < cells.length; i += 7) out.push(cells.slice(i, i + 7));
  return out;
});
function isDisabled(d: number): boolean {
  const s = dstr(d);
  return (!!props.min && s < props.min) || (!!props.max && s > props.max);
}
</script>

<template>
  <div class="flare-cal">
    <div class="flare-cal__head">
      <button type="button" class="flare-cal__nav" :aria-label="zh ? '上个月' : 'Previous month'" @click="emit('nav', -1)">
        <n-icon :size="18" :component="ChevronBackOutline" />
      </button>
      <span class="flare-cal__label">{{ monthLabel }}</span>
      <button type="button" class="flare-cal__nav" :aria-label="zh ? '下个月' : 'Next month'" @click="emit('nav', 1)">
        <n-icon :size="18" :component="ChevronForwardOutline" />
      </button>
    </div>

    <div class="flare-cal__grid flare-cal__weekdays">
      <span v-for="(w, i) in weekdays" :key="i" class="flare-cal__wd">{{ w }}</span>
    </div>

    <div class="flare-cal__grid" role="grid">
      <template v-for="(week, wi) in weeks" :key="wi">
        <template v-for="(d, di) in week" :key="`${wi}-${di}`">
          <button
            v-if="d"
            type="button"
            class="flare-cal__day"
            :class="{ 'is-selected': dstr(d) === selected, 'is-today': dstr(d) === today, 'is-disabled': isDisabled(d) }"
            :disabled="isDisabled(d)"
            :aria-current="dstr(d) === today ? 'date' : undefined"
            :aria-selected="dstr(d) === selected"
            @click="emit('pick', dstr(d))"
          >
            {{ d }}
          </button>
          <span v-else class="flare-cal__blank" aria-hidden="true" />
        </template>
      </template>
    </div>

    <div class="flare-cal__footer">
      <button type="button" class="flare-cal__btn is-ghost" @click="emit('cancel')">{{ zh ? "取消" : "Cancel" }}</button>
      <button type="button" class="flare-cal__btn is-primary" @click="emit('today')">{{ zh ? "今天" : "Today" }}</button>
    </div>
  </div>
</template>

<style scoped>
.flare-cal { display: flex; flex-direction: column; gap: 8px; padding: 10px; min-width: 262px; }
.flare-cal__head { display: flex; align-items: center; justify-content: space-between; padding: 2px 4px 4px; }
.flare-cal__label { font-size: 14px; font-weight: 600; color: var(--flare-color-text-primary, #15131c); font-variant-numeric: tabular-nums; }
.flare-cal__nav {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 30px;
  height: 30px;
  border: none;
  border-radius: var(--flare-size-radius-md, 8px);
  background: transparent;
  color: var(--flare-color-text-secondary, #6b6780);
  cursor: pointer;
  transition: background var(--flare-transition-fast, 150ms ease), color var(--flare-transition-fast, 150ms ease);
}
.flare-cal__nav:hover { background: var(--flare-color-bg-secondary, #f6f5fb); color: var(--flare-color-primary, #7c3aed); }

.flare-cal__grid { display: grid; grid-template-columns: repeat(7, 1fr); gap: 2px; }
.flare-cal__weekdays { margin-bottom: 2px; }
.flare-cal__wd { text-align: center; font-size: 12px; font-weight: 500; color: var(--flare-color-text-tertiary, #a7a2b4); padding: 4px 0; }
.flare-cal__blank { aspect-ratio: 1; }
.flare-cal__day {
  aspect-ratio: 1;
  min-width: 34px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 1px solid transparent;
  border-radius: var(--flare-size-radius-md, 8px);
  background: transparent;
  font: inherit;
  font-size: 14px;
  font-variant-numeric: tabular-nums;
  color: var(--flare-color-text-primary, #15131c);
  cursor: pointer;
  transition: background var(--flare-transition-fast, 150ms ease), color var(--flare-transition-fast, 150ms ease);
}
.flare-cal__day:hover:not(.is-disabled):not(.is-selected),
.flare-cal__day:focus-visible:not(.is-disabled):not(.is-selected) { background: var(--flare-color-bg-secondary, #f6f5fb); outline: none; }
.flare-cal__day.is-today:not(.is-selected) { border-color: var(--flare-color-primary, #7c3aed); color: var(--flare-color-primary, #7c3aed); }
.flare-cal__day.is-selected { background: var(--im-brand-gradient, var(--flare-color-primary, #7c3aed)); color: #fff; font-weight: 600; }
.flare-cal__day.is-disabled { opacity: 0.32; cursor: not-allowed; }

.flare-cal__footer { display: flex; gap: 8px; padding-top: 6px; }
.flare-cal__btn {
  flex: 1;
  height: 36px;
  border-radius: var(--flare-size-radius-lg, 10px);
  border: 1px solid transparent;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: filter var(--flare-transition-fast, 150ms ease), background var(--flare-transition-fast, 150ms ease);
}
.flare-cal__btn.is-ghost { background: var(--flare-color-bg-secondary, #f6f5fb); color: var(--flare-color-text-secondary, #6b6780); }
.flare-cal__btn.is-primary { background: var(--im-brand-gradient, var(--flare-color-primary, #7c3aed)); color: #fff; }
.flare-cal__btn.is-primary:hover { filter: brightness(0.97); }
</style>
