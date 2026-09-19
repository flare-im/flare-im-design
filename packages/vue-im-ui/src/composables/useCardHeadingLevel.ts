import { nextTick, watch, type Ref } from "vue";

/**
 * naive-ui's card header renders `role="heading"` with no `aria-level`, on both the header and its main
 * element. A heading role without a level is an invalid ARIA node — axe reports it as critical — and the
 * attribute cannot be passed through `NModal preset="card"`, so the kit sets it once the dialog is on
 * screen. Nothing else about the markup is touched.
 *
 * The defect was invisible until Round 6 taught the accessibility sweep to open a dialog before scanning
 * it; before that it only ever saw the button that opens this one.
 */
export function useCardHeadingLevel(open: Ref<boolean>, scopeClass: string, level = 2): void {
  watch(
    open,
    async (isOpen) => {
      if (!isOpen || typeof document === "undefined") return;
      await nextTick();
      for (const el of document.querySelectorAll<HTMLElement>(`.${scopeClass} [role="heading"]`)) {
        if (!el.getAttribute("aria-level")) el.setAttribute("aria-level", String(level));
      }
    },
    { immediate: true },
  );
}
