// The keyboard side of a picker's anchored panel that a popover draws outside its trigger (teleported to the
// body, or into a Naive modal): focus goes into the panel when it opens, Tab and Shift+Tab stay inside it, and
// focus goes back to the trigger when the panel closes from inside (a pick, Cancel, Escape) — as
// FlareActionMenu does. Tab is handled here and not passed on, so a dialog's Tab trap (useModalSurface) never
// pulls focus out of an open panel.
import { onMounted, ref, watch, type Ref } from "vue";

const FOCUSABLE = 'button:not([disabled]), [href], input:not([disabled]), [tabindex]:not([tabindex="-1"])';

export function useFlareAnchoredPanel(
  panel: Ref<HTMLElement | null>,
  /** Whether the panel is shown (a reopened panel may still be the element that was leaving). */
  shown: () => boolean,
  trigger: () => HTMLElement | null | undefined,
  /** Where focus lands on open, the first that matches (the chosen day, else today); else the first control. */
  initial: readonly string[],
) {
  const reduceMotion = ref(false);
  onMounted(() => {
    reduceMotion.value = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches ?? false;
  });
  const controls = () => Array.from(panel.value?.querySelectorAll<HTMLElement>(FOCUSABLE) ?? []);
  watch(
    () => [panel.value, shown()] as const,
    ([element, isShown]) => {
      if (!element || !isShown) return;
      const first = initial.map((selector) => element.querySelector<HTMLElement>(selector)).find(Boolean);
      (first ?? controls()[0])?.focus({ preventScroll: true });
    },
    { flush: "post" },
  );
  function onKeydown(event: KeyboardEvent): void {
    if (event.key !== "Tab") return;
    const list = controls();
    if (!list.length) return;
    event.preventDefault();
    event.stopPropagation();
    const at = list.indexOf(document.activeElement as HTMLElement);
    const next = at < 0 ? (event.shiftKey ? list.length - 1 : 0) : (at + (event.shiftKey ? list.length - 1 : 1)) % list.length;
    list[next].focus({ preventScroll: true });
  }
  /** Back to the trigger when focus is in the open panel; a click elsewhere keeps its own focus. */
  function returnFocus(): void {
    const active = document.activeElement;
    if (panel.value && (active === document.body || (active && panel.value.contains(active))))
      trigger()?.focus({ preventScroll: true });
  }
  return { reduceMotion, onKeydown, returnFocus };
}
