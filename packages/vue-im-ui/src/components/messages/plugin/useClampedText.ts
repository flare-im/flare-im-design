import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch, type ComputedRef } from "vue";

/**
 * Text cut at `cap` lines with an expand key when it overflows: measured where there is layout, and known
 * without it when the text has more lines than the cap. Shared by the text and note blocks.
 */
export function useClampedText(cap: ComputedRef<number | undefined>, text: () => string) {
  const expanded = ref(false);
  const measured = ref(false);
  const el = ref<HTMLElement | null>(null);
  /** The line count to cut at right now: none once expanded. */
  const lines = computed(() => (cap.value && !expanded.value ? cap.value : undefined));
  const overflows = computed(() => {
    const max = cap.value;
    if (!max) return false;
    return measured.value || text().split("\n").length > max;
  });

  let observer: ResizeObserver | undefined;
  function measure(): void {
    const node = el.value;
    if (!node || expanded.value || !cap.value) return;
    measured.value = node.scrollHeight > node.clientHeight + 1;
  }
  onMounted(() => {
    measure();
    if (typeof ResizeObserver !== "undefined" && el.value) {
      observer = new ResizeObserver(measure);
      observer.observe(el.value);
    }
  });
  onBeforeUnmount(() => observer?.disconnect());
  watch(text, () => {
    expanded.value = false;
    measured.value = false;
    void nextTick(measure);
  });
  const toggle = () => { expanded.value = !expanded.value; };
  return { el, expanded, lines, overflows, toggle };
}
