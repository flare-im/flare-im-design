<script setup lang="ts">
// Reusable adaptive modal surface — the app-mode surface for Select, TimePicker,
// DatePicker, forms and secondary panels. It presents as a bottom sheet on phone
// form factors and as a centered dialog on pointer devices (`presentation="auto"`),
// or as a side drawer when asked. Teleports to the injected overlay container
// (defaults to "body"), dims with a scrim, and closes on scrim-click or Escape.
// Centralizes the modal contract so every presentation behaves the same:
//  - ref-counted body scroll-lock that saves/restores the prior overflow value
//  - focus moves into the sheet on open and is restored to the opener on close
//  - Tab is trapped within the sheet while open
// Callers pass the body via the default slot; the scrim/grip/title chrome +
// transitions live here so there is one place to fix behavior.
import { computed, getCurrentInstance, nextTick, ref, watch, onBeforeUnmount } from "vue";
import { useFlareOverlayContainer } from "../../shared/useOverlayContainer";
import { useFlarePlatformSafe } from "../../shared/platform/useFlarePlatform";
import { claimNativeBack } from "../../shared/platform/useFlareNativeBack";

/** How the surface appears: `auto` is a bottom sheet on phones and a dialog on pointer devices. */
export type FlareSheetPresentation = "auto" | "sheet" | "dialog" | "drawer";

const props = withDefaults(
  defineProps<{
    open: boolean;
    /** Prevent closing while an operation owns the draft. */
    dismissible?: boolean;
    /** Optional header: centered on a sheet, leading on a dialog or drawer. */
    title?: string;
    /** Cap the sheet or dialog height (e.g. "72vh"); a drawer is full height. */
    maxHeight?: string;
    presentation?: FlareSheetPresentation;
  }>(),
  { maxHeight: "72vh", dismissible: true, presentation: "auto" },
);
const platform = useFlarePlatformSafe();
const resolvedPresentation = computed<Exclude<FlareSheetPresentation, "auto">>(() => {
  if (props.presentation !== "auto") return props.presentation;
  return platform.capabilities.value.bottomSheet ? "sheet" : "dialog";
});
const surfaceTransition = computed(() => ({ sheet: "flare-sheet-rise", dialog: "flare-sheet-pop", drawer: "flare-sheet-slide" })[resolvedPresentation.value]);
const emit = defineEmits<{ (e: "close"): void }>();
const instance = getCurrentInstance();
// While open, the platform back closes the sheet like Escape does; while not dismissible it is held,
// not passed on. Claimed in the open watcher below: conversation rows keep a closed sheet each.
let releaseBack: (() => void) | undefined;
const overlayContainer = useFlareOverlayContainer();
const sheetEl = ref<HTMLElement | null>(null);
let opener: HTMLElement | null = null;
let holdsLock = false;
const sheetId = Symbol("sheet");

// --- ref-counted, restoring body scroll-lock (module-scoped across instances) ---
function lockScroll(): void {
  if (typeof document === "undefined" || holdsLock) return;
  if (lockCount === 0) {
    priorOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
  }
  openSheets.push(sheetId);
  lockCount += 1;
  holdsLock = true;
}
function unlockScroll(): void {
  if (typeof document === "undefined" || !holdsLock) return;
  holdsLock = false;
  const index = openSheets.indexOf(sheetId);
  if (index !== -1) openSheets.splice(index, 1);
  lockCount = Math.max(0, lockCount - 1);
  if (lockCount === 0) document.body.style.overflow = priorOverflow;
}

function focusables(): HTMLElement[] {
  if (!sheetEl.value) return [];
  return Array.from(
    sheetEl.value.querySelectorAll<HTMLElement>(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])',
    ),
  ).filter((el) => !el.hasAttribute("disabled"));
}

function onKeydown(e: KeyboardEvent): void {
  if (openSheets.at(-1) !== sheetId) return;
  if (e.key === "Escape") {
    e.preventDefault();
    if (props.dismissible) emit("close");
    return;
  }
  if (e.key === "Tab" && sheetEl.value) {
    const items = focusables();
    if (items.length === 0) {
      e.preventDefault();
      sheetEl.value.focus();
      return;
    }
    const first = items[0];
    const last = items[items.length - 1];
    const active = document.activeElement as HTMLElement | null;
    if (e.shiftKey && (active === first || !sheetEl.value.contains(active))) {
      e.preventDefault();
      last.focus();
    } else if (!e.shiftKey && active === last) {
      e.preventDefault();
      first.focus();
    }
  }
}

watch(
  () => props.open,
  (isOpen) => {
    if (typeof document === "undefined") return;
    releaseBack?.();
    releaseBack = undefined;
    if (isOpen) {
      if (instance?.vnode.props?.onClose) {
        releaseBack = claimNativeBack(platform, () => {
          if (props.dismissible) emit("close");
        });
      }
      opener = document.activeElement as HTMLElement | null;
      lockScroll();
      document.addEventListener("keydown", onKeydown);
      nextTick(() => (focusables()[0] ?? sheetEl.value)?.focus());
    } else {
      document.removeEventListener("keydown", onKeydown);
      unlockScroll();
      opener?.focus?.();
      opener = null;
    }
  },
  { immediate: true },
);

onBeforeUnmount(() => {
  releaseBack?.();
  if (typeof document === "undefined") return;
  document.removeEventListener("keydown", onKeydown);
  unlockScroll();
});
</script>

<script lang="ts">
// Shared across all sheet instances so nested/stacked sheets restore correctly.
const openSheets: symbol[] = [];
let lockCount = 0;
let priorOverflow = "";
</script>

<template>
  <Teleport :to="overlayContainer">
    <transition name="flare-sheet-fade">
      <div v-if="open" class="flare-sheet-scrim" :class="`flare-sheet-scrim--${resolvedPresentation}`" @click="dismissible && emit('close')">
        <transition :name="surfaceTransition" appear>
          <div
            ref="sheetEl"
            class="flare-sheet"
            :class="`flare-sheet--${resolvedPresentation}`"
            :style="resolvedPresentation === 'drawer' ? undefined : { maxHeight }"
            role="dialog"
            :aria-label="title"
            aria-modal="true"
            tabindex="-1"
            :data-flare-presentation="resolvedPresentation"
            @click.stop
          >
            <div v-if="resolvedPresentation === 'sheet'" class="flare-sheet__grip" aria-hidden="true" />
            <div v-if="title" class="flare-sheet__title">{{ title }}</div>
            <slot />
          </div>
        </transition>
      </div>
    </transition>
  </Teleport>
</template>

<style scoped>
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
  box-sizing: border-box;
  min-width: 0;
  width: 100%;
  max-width: 640px;
  display: flex;
  flex-direction: column;
  padding: 8px 8px calc(8px + env(safe-area-inset-bottom, 0px));
  background: var(--flare-color-bg-primary);
  border-radius: 20px 20px 0 0;
  box-shadow: var(--flare-shadow-lg);
  outline: none;
}
.flare-sheet__grip { width: 36px; height: 4px; border-radius: 999px; background: var(--flare-color-border-primary); margin: 6px auto 8px; flex: 0 0 auto; }
.flare-sheet__title { padding: 4px 12px 8px; font-size: 13px; font-weight: 500; color: var(--flare-color-text-tertiary); text-align: center; }

/* Dialog: centered on pointer devices, all corners rounded, no grip. */
.flare-sheet-scrim--dialog { align-items: center; padding: var(--flare-size-spacing-xl); box-sizing: border-box; }
.flare-sheet--dialog { max-width: var(--flare-component-sheet-dialog-width); padding: var(--flare-size-spacing-sm); border-radius: var(--flare-size-radius-xl); }

/* Drawer: full height at the inline end, for longer secondary panels. */
.flare-sheet-scrim--drawer { align-items: stretch; justify-content: flex-end; }
.flare-sheet--drawer { max-width: 420px; height: 100%; padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-sm) calc(var(--flare-size-spacing-sm) + env(safe-area-inset-bottom, 0px)); border-radius: 0; border-start-start-radius: var(--flare-size-radius-xl); border-end-start-radius: var(--flare-size-radius-xl); overflow-y: auto; }

.flare-sheet--dialog .flare-sheet__title,
.flare-sheet--drawer .flare-sheet__title { padding: var(--flare-size-spacing-md) var(--flare-size-spacing-lg) var(--flare-size-spacing-xs); font-size: var(--flare-size-font-size-lg); font-weight: 600; color: var(--flare-color-text-primary); text-align: start; }

.flare-sheet-fade-enter-active, .flare-sheet-fade-leave-active { transition: opacity 0.22s ease; }
.flare-sheet-fade-enter-from, .flare-sheet-fade-leave-to { opacity: 0; }
.flare-sheet-rise-enter-active { transition: transform 0.28s cubic-bezier(0.16, 1, 0.3, 1); }
.flare-sheet-rise-leave-active { transition: transform 0.2s ease; }
.flare-sheet-rise-enter-from, .flare-sheet-rise-leave-to { transform: translateY(100%); }
.flare-sheet-pop-enter-active, .flare-sheet-pop-leave-active { transition: opacity var(--flare-transition-normal), transform var(--flare-transition-normal); }
.flare-sheet-pop-enter-from, .flare-sheet-pop-leave-to { opacity: 0; transform: scale(0.96); }
.flare-sheet-slide-enter-active, .flare-sheet-slide-leave-active { transition: transform var(--flare-transition-normal); }
.flare-sheet-slide-enter-from, .flare-sheet-slide-leave-to { transform: translateX(100%); }
:dir(rtl) .flare-sheet-slide-enter-from, :dir(rtl) .flare-sheet-slide-leave-to { transform: translateX(-100%); }
@media (prefers-reduced-motion: reduce) {
  .flare-sheet-rise-enter-active, .flare-sheet-rise-leave-active,
  .flare-sheet-pop-enter-active, .flare-sheet-pop-leave-active,
  .flare-sheet-slide-enter-active, .flare-sheet-slide-leave-active { transition: none; }
}
</style>
