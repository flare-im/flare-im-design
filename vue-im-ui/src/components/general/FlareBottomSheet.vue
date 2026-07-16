<script setup lang="ts">
// Reusable adaptive bottom sheet — the app-mode surface for Select, TimePicker,
// DatePicker, and any future picker. Teleports to the injected overlay container
// (defaults to "body"), dims with a scrim, slides up, and closes on scrim-click
// or Escape. Centralizes the modal contract so every sheet behaves the same:
//  - ref-counted body scroll-lock that saves/restores the prior overflow value
//  - focus moves into the sheet on open and is restored to the opener on close
//  - Tab is trapped within the sheet while open
// Callers pass the body via the default slot; the scrim/grip/title chrome +
// transitions live here so there is one place to fix behavior.
import { nextTick, ref, watch, onBeforeUnmount } from "vue";
import { useFlareOverlayContainer } from "../../shared/useOverlayContainer";

const props = withDefaults(
  defineProps<{
    open: boolean;
    /** Optional centered header. */
    title?: string;
    /** Cap the sheet height (e.g. "72vh"). */
    maxHeight?: string;
  }>(),
  { maxHeight: "72vh" },
);
const emit = defineEmits<{ (e: "close"): void }>();
const overlayContainer = useFlareOverlayContainer();
const sheetEl = ref<HTMLElement | null>(null);
let opener: HTMLElement | null = null;
let holdsLock = false;

// --- ref-counted, restoring body scroll-lock (module-scoped across instances) ---
function lockScroll(): void {
  if (typeof document === "undefined" || holdsLock) return;
  if (lockCount === 0) {
    priorOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
  }
  lockCount += 1;
  holdsLock = true;
}
function unlockScroll(): void {
  if (typeof document === "undefined" || !holdsLock) return;
  holdsLock = false;
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
  if (e.key === "Escape") {
    emit("close");
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
    if (isOpen) {
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
);

onBeforeUnmount(() => {
  if (typeof document === "undefined") return;
  document.removeEventListener("keydown", onKeydown);
  unlockScroll();
});
</script>

<script lang="ts">
// Shared across all sheet instances so nested/stacked sheets restore correctly.
let lockCount = 0;
let priorOverflow = "";
</script>

<template>
  <Teleport :to="overlayContainer">
    <transition name="flare-sheet-fade">
      <div v-if="open" class="flare-sheet-scrim" @click="emit('close')">
        <transition name="flare-sheet-rise" appear>
          <div
            ref="sheetEl"
            class="flare-sheet"
            :style="{ maxHeight }"
            role="dialog"
            aria-modal="true"
            tabindex="-1"
            @click.stop
          >
            <div class="flare-sheet__grip" aria-hidden="true" />
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
  width: 100%;
  max-width: 640px;
  display: flex;
  flex-direction: column;
  padding: 8px 8px calc(8px + env(safe-area-inset-bottom, 0px));
  background: var(--flare-color-bg-primary, #fff);
  border-radius: 20px 20px 0 0;
  box-shadow: var(--flare-shadow-lg, 0 -8px 32px rgba(21, 18, 32, 0.22));
  outline: none;
}
.flare-sheet__grip { width: 36px; height: 4px; border-radius: 999px; background: var(--flare-color-border-primary, #e9e6f1); margin: 6px auto 8px; flex: 0 0 auto; }
.flare-sheet__title { padding: 4px 12px 8px; font-size: 13px; font-weight: 500; color: var(--flare-color-text-tertiary, #a7a2b4); text-align: center; }

.flare-sheet-fade-enter-active, .flare-sheet-fade-leave-active { transition: opacity 0.22s ease; }
.flare-sheet-fade-enter-from, .flare-sheet-fade-leave-to { opacity: 0; }
.flare-sheet-rise-enter-active { transition: transform 0.28s cubic-bezier(0.16, 1, 0.3, 1); }
.flare-sheet-rise-leave-active { transition: transform 0.2s ease; }
.flare-sheet-rise-enter-from, .flare-sheet-rise-leave-to { transform: translateY(100%); }
@media (prefers-reduced-motion: reduce) {
  .flare-sheet-rise-enter-active, .flare-sheet-rise-leave-active { transition: none; }
}
</style>
