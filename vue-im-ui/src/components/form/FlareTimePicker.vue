<script setup lang="ts">
import { ref, computed, watch, onBeforeUnmount, nextTick } from "vue";
import { NIcon } from "naive-ui";
import { TimeOutline } from "@vicons/ionicons5";
import type { FlareControlSize } from "../../shared/contracts";
import { useFlareConfig } from "../../shared/useFlareConfig";
import { useFlareAdaptiveSafe } from "../../composables/useAdaptiveMode";
import { useFlareOverlayContainer } from "../../shared/useOverlayContainer";

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
const overlayContainer = useFlareOverlayContainer();
const asSheet = computed(() => adaptive.isH5.value);

const pad = (n: number) => String(n).padStart(2, "0");
const hours = Array.from({ length: 24 }, (_, i) => i);
const minutes = computed(() => {
  const step = Math.max(1, Math.min(30, props.minuteStep));
  return Array.from({ length: Math.ceil(60 / step) }, (_, i) => i * step);
});

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
  th.value = h;
  tm.value = m;
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
function onDocClick(e: MouseEvent): void {
  if (asSheet.value) return;
  if (root.value && !root.value.contains(e.target as Node)) open.value = false;
}
watch([open, asSheet], ([isOpen, sheet]) => {
  if (typeof document === "undefined") return;
  document.body.style.overflow = isOpen && sheet ? "hidden" : "";
});
if (typeof document !== "undefined") document.addEventListener("click", onDocClick);
onBeforeUnmount(() => {
  if (typeof document !== "undefined") {
    document.removeEventListener("click", onDocClick);
    document.body.style.overflow = "";
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
    <Teleport v-if="asSheet" :to="overlayContainer">
      <transition name="flare-sheet-fade">
        <div v-if="open" class="flare-sheet-scrim" @click="close">
          <transition name="flare-sheet-rise" appear>
            <div class="flare-sheet flare-tp__sheet" role="dialog" aria-modal="true" @click.stop>
              <div class="flare-sheet__grip" aria-hidden="true" />
              <div v-if="title || placeholder" class="flare-sheet__title">{{ title || placeholder }}</div>
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
            </div>
          </transition>
        </div>
      </transition>
    </Teleport>
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

/* Bottom sheet shell (shared with Select) */
.flare-sheet-scrim {
  position: fixed;
  inset: 0;
  z-index: 3000;
  display: flex;
  align-items: flex-end;
  justify-content: center;
  background: rgba(21, 18, 32, 0.44);
}
.flare-sheet {
  width: 100%;
  max-width: 640px;
  max-height: 82vh;
  display: flex;
  flex-direction: column;
  padding: 8px 8px calc(4px + env(safe-area-inset-bottom, 0px));
  background: var(--flare-color-bg-primary, #fff);
  border-radius: 20px 20px 0 0;
  box-shadow: var(--flare-shadow-lg, 0 -8px 32px rgba(21, 18, 32, 0.22));
}
.flare-sheet__grip { width: 36px; height: 4px; border-radius: 999px; background: var(--flare-color-border-primary, #e9e6f1); margin: 6px auto 8px; flex: 0 0 auto; }
.flare-sheet__title { padding: 4px 12px 6px; font-size: 13px; font-weight: 500; color: var(--flare-color-text-tertiary, #a7a2b4); text-align: center; }

.flare-sheet-fade-enter-active, .flare-sheet-fade-leave-active { transition: opacity 0.22s ease; }
.flare-sheet-fade-enter-from, .flare-sheet-fade-leave-to { opacity: 0; }
.flare-sheet-rise-enter-active { transition: transform 0.28s cubic-bezier(0.16, 1, 0.3, 1); }
.flare-sheet-rise-leave-active { transition: transform 0.2s ease; }
.flare-sheet-rise-enter-from, .flare-sheet-rise-leave-to { transform: translateY(100%); }
@media (prefers-reduced-motion: reduce) {
  .flare-sheet-rise-enter-active, .flare-sheet-rise-leave-active { transition: none; }
}
.flare-tp-pop-enter-active, .flare-tp-pop-leave-active { transition: opacity 0.14s ease, transform 0.14s ease; }
.flare-tp-pop-enter-from, .flare-tp-pop-leave-to { opacity: 0; transform: translateY(-4px); }
</style>
