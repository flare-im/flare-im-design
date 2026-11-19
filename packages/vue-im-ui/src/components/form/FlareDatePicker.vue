<script setup lang="ts">
import { ref, computed, onBeforeUnmount } from "vue";
import { NIcon, NPopover } from "naive-ui";
import { CalendarOutline } from "../../shared/icon-glyphs";
import type { FlareControlSize } from "../../shared/contracts";
import { useFlareConfig } from "../../shared/useFlareConfig";
import { useFlareAdaptiveSafe } from "../../composables/useAdaptiveMode";
import { useFlareAnchoredPanel } from "../../shared/useAnchoredPanel";
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
const pop = ref<HTMLElement | null>(null);
const panel = useFlareAnchoredPanel(pop, () => open.value && !asSheet.value, () => root.value?.querySelector<HTMLElement>(".flare-dp__trigger"), [
  ".flare-cal__day.is-selected:not(:disabled)",
  ".flare-cal__day.is-today:not(:disabled)",
]);
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
function close(): void {
  panel.returnFocus();
  open.value = false;
}
function nav(delta: number): void {
  const m = viewM.value + delta;
  viewY.value += Math.floor(m / 12);
  viewM.value = ((m % 12) + 12) % 12;
}
function pick(dateStr: string): void {
  value.value = dateStr;
  emit("change", dateStr);
  panel.returnFocus();
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
  const target = e.target as Node;
  // The panel is drawn outside the root (teleported), so a click in it is not outside.
  if (root.value && !root.value.contains(target) && !pop.value?.contains(target)) open.value = false;
}
// 用掉 Escape 就要 preventDefault:下面可能还有一层上下文层(多选工具条)在听同一下键。
// 键盘监听挂在捕获阶段:弹层放在 Drawer / Modal 里时,面的冒泡监听比这里先注册,
// 冒泡阶段它会先把这下 Escape 当成「返回 / 关闭」。捕获阶段先到这里,面看到
// defaultPrevented 就不再处理。不 stopPropagation —— 别的层还靠 defaultPrevented 判断。
function onDocKey(e: KeyboardEvent): void {
  if (e.key === "Escape" && !asSheet.value && open.value) {
    e.preventDefault();
    panel.returnFocus();
    open.value = false;
  }
}
if (typeof document !== "undefined") {
  document.addEventListener("click", onDocPointer, true);
  document.addEventListener("keydown", onDocKey, true);
}
onBeforeUnmount(() => {
  if (typeof document !== "undefined") {
    document.removeEventListener("click", onDocPointer, true);
    document.removeEventListener("keydown", onDocKey, true);
  }
});
</script>

<template>
  <div ref="root" class="flare-dp" :class="[`flare-dp--${rsize}`, { 'is-open': open, 'is-disabled': disabled }]">
    <!-- Desktop: an anchored popover. Naive draws it outside any dialog's overflow and flips it
         above the trigger when there is no room below. -->
    <NPopover :show="open && !asSheet" trigger="manual" raw :show-arrow="false" placement="bottom-start" :animated="!panel.reduceMotion.value" :style="{ boxShadow: 'none' }">
      <template #trigger>
        <button type="button" class="flare-dp__trigger" :disabled="disabled" @click.stop="show">
          <n-icon aria-hidden="true" :size="16" :component="CalendarOutline" class="flare-dp__icon" />
          <span class="flare-dp__value" :class="{ 'is-placeholder': !value }">{{ value || placeholder }}</span>
        </button>
      </template>
      <div ref="pop" class="flare-dp__pop" @click.stop @keydown="panel.onKeydown">
        <FlareCalendarBody
          :year="viewY" :month="viewM" :selected="value" :today="todayStr" :min="min" :max="max" :locale="locale"
          @pick="pick" @nav="nav" @today="goToday" @cancel="close"
        />
      </div>
    </NPopover>

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
  border: 1px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-primary);
  cursor: pointer;
  transition: border-color var(--flare-transition-fast), box-shadow var(--flare-transition-fast);
}
.flare-dp--sm .flare-dp__trigger { height: 32px; padding: 0 var(--flare-size-spacing-2sm); font-size: 13px; }
.flare-dp--md .flare-dp__trigger { height: 40px; padding: 0 12px; font-size: 14px; }
.flare-dp--lg .flare-dp__trigger { height: 48px; padding: 0 var(--flare-size-spacing-2md); font-size: 15px; }
.flare-dp.is-open .flare-dp__trigger {
  border-color: var(--flare-color-primary);
  box-shadow: 0 0 0 3px var(--flare-color-focus-ring);
}
.flare-dp.is-disabled { opacity: 0.55; }
.flare-dp.is-disabled .flare-dp__trigger { cursor: not-allowed; }
.flare-dp__icon { color: var(--flare-color-text-tertiary); flex: 0 0 auto; }
.flare-dp__value { font-variant-numeric: tabular-nums; }
.flare-dp__value.is-placeholder { color: var(--flare-color-text-tertiary); }

.flare-dp__pop {
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-primary);
  box-shadow: var(--flare-shadow-lg);
}
.flare-dp__sheet { padding: 2px 6px 6px; }
</style>
