<script setup lang="ts">
// Shared calendar grid used by FlareDatePicker in both the desktop popover and
// the mobile sheet — one implementation, so the two presentations never drift.
// Pure/presentational: the parent owns the view month + selection and reacts to
// the emitted events.
import { computed } from "vue";
import { NIcon } from "naive-ui";
import { ChevronBackOutline, ChevronForwardOutline } from "../../shared/icon-glyphs";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

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
  /** BCP 47 tag used for the Intl month name; copy itself comes from the i18n provider. */
  locale: string;
}>();
const emit = defineEmits<{
  (e: "pick", date: string): void;
  (e: "nav", delta: number): void;
  (e: "today"): void;
  (e: "cancel"): void;
}>();

const { t } = useFlareI18n();
const pad = (n: number) => String(n).padStart(2, "0");
const WEEKDAY_KEYS = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"] as const;
const weekdays = computed(() => WEEKDAY_KEYS.map((k) => t(`calendarBody.weekday.${k}`)));
// "{year}年{month}月" in zh-CN, "{monthName} {year}" in en-US; `monthName` is the
// Intl long month name for the `locale` prop so any registered locale can pick.
const monthLabel = computed(() =>
  t("calendarBody.monthTitle", {
    year: props.year,
    month: props.month + 1,
    monthName: new Date(props.year, props.month, 1).toLocaleString(props.locale, { month: "long" }),
  }),
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
      <button type="button" class="flare-cal__nav" :aria-label="t('calendarBody.previousMonth')" @click="emit('nav', -1)">
        <n-icon aria-hidden="true" :size="18" :component="ChevronBackOutline" />
      </button>
      <span class="flare-cal__label">{{ monthLabel }}</span>
      <button type="button" class="flare-cal__nav" :aria-label="t('calendarBody.nextMonth')" @click="emit('nav', 1)">
        <n-icon aria-hidden="true" :size="18" :component="ChevronForwardOutline" />
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
      <button type="button" class="flare-cal__btn is-ghost" @click="emit('cancel')">{{ t("calendarBody.cancel") }}</button>
      <button type="button" class="flare-cal__btn is-primary" @click="emit('today')">{{ t("calendarBody.today") }}</button>
    </div>
  </div>
</template>

<style scoped>
.flare-cal { display: flex; flex-direction: column; gap: 8px; padding: var(--flare-size-spacing-2sm); min-width: 262px; }
.flare-cal__head { display: flex; align-items: center; justify-content: space-between; padding: 2px 4px 4px; }
.flare-cal__label { font-size: 14px; font-weight: 600; color: var(--flare-color-text-primary); font-variant-numeric: tabular-nums; }
.flare-cal__nav {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 30px;
  height: 30px;
  border: none;
  border-radius: var(--flare-size-radius-md);
  background: transparent;
  color: var(--flare-color-text-secondary);
  cursor: pointer;
  transition: background var(--flare-transition-fast), color var(--flare-transition-fast);
}
.flare-cal__nav:hover { background: var(--flare-color-bg-secondary); color: var(--flare-color-primary-text); }

.flare-cal__grid { display: grid; grid-template-columns: repeat(7, 1fr); gap: 2px; }
.flare-cal__weekdays { margin-bottom: 2px; }
.flare-cal__wd { text-align: center; font-size: 12px; font-weight: 500; color: var(--flare-color-text-tertiary); padding: 4px 0; }
.flare-cal__blank { aspect-ratio: 1; }
.flare-cal__day {
  aspect-ratio: 1;
  min-width: 34px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 1px solid transparent;
  border-radius: var(--flare-size-radius-md);
  background: transparent;
  font: inherit;
  font-size: 14px;
  font-variant-numeric: tabular-nums;
  color: var(--flare-color-text-primary);
  cursor: pointer;
  transition: background var(--flare-transition-fast), color var(--flare-transition-fast);
}
.flare-cal__day:hover:not(.is-disabled):not(.is-selected),
.flare-cal__day:focus-visible:not(.is-disabled):not(.is-selected) { background: var(--flare-color-bg-secondary); outline: none; }
.flare-cal__day.is-today:not(.is-selected) { border-color: var(--flare-color-primary); color: var(--flare-color-primary-text); }
.flare-cal__day.is-selected { background: var(--flare-component-brand-primary); color: #fff; font-weight: 600; }
.flare-cal__day.is-disabled { opacity: 0.32; cursor: not-allowed; }

.flare-cal__footer { display: flex; gap: 8px; padding-top: 6px; }
.flare-cal__btn {
  flex: 1;
  height: 36px;
  border-radius: var(--flare-size-radius-lg);
  border: 1px solid transparent;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: filter var(--flare-transition-fast), background var(--flare-transition-fast);
}
.flare-cal__btn.is-ghost { background: var(--flare-color-bg-secondary); color: var(--flare-color-text-secondary); }
.flare-cal__btn.is-primary { background: var(--flare-component-brand-primary); color: #fff; }
.flare-cal__btn.is-primary:hover { filter: brightness(0.97); }
</style>
