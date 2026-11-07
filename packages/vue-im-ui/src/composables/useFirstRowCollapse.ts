import {
  Comment,
  Fragment,
  Text,
  onBeforeUnmount,
  onMounted,
  onUpdated,
  ref,
  type Ref,
  type VNode,
} from "vue";

/** Flatten the actual fields, never duplicate or unmount their inputs for measurement. */
export function flattenQueryFields(nodes: VNode[]): VNode[] {
  return nodes.flatMap((node) => {
    if (
      node.type === Comment ||
      (node.type === Text && !String(node.children ?? "").trim())
    )
      return [];
    if (node.type === Fragment && Array.isArray(node.children))
      return flattenQueryFields(node.children as VNode[]);
    return [node];
  });
}

/** Renderer-neutral: fold rows only after measuring the real field positions. */
export function useFirstRowCollapse(
  fields: Ref<HTMLElement | null>,
  expanded: Ref<boolean>,
  container = fields,
) {
  const firstRowCount = ref(Number.MAX_SAFE_INTEGER);
  const firstRowHeight = ref(0);
  const overflowing = ref(false);
  const width = ref(0);
  function measure() {
    width.value = container.value?.getBoundingClientRect().width ?? 0;
    const grid = fields.value;
    if (!grid) return;
    const cells = Array.from(grid.children) as HTMLElement[];
    if (!cells.length || !grid.getBoundingClientRect().width) {
      overflowing.value = false;
      return;
    }
    const bounds = cells.map((cell) => cell.getBoundingClientRect());
    const first = bounds.filter(
      (rect) => Math.abs(rect.top - bounds[0].top) <= 1,
    );
    firstRowCount.value = first.length;
    firstRowHeight.value = Math.ceil(
      Math.max(...first.map((rect) => rect.bottom)) - bounds[0].top,
    );
    overflowing.value = first.length < cells.length;
    if (
      !expanded.value &&
      cells
        .slice(first.length)
        .some((cell) => cell.contains(document.activeElement))
    )
      expanded.value = true;
  }
  let observer: ResizeObserver | undefined;
  onMounted(() => {
    measure();
    if (typeof ResizeObserver === "undefined") return;
    observer = new ResizeObserver(measure);
    if (fields.value) observer.observe(fields.value);
    if (container.value && container.value !== fields.value)
      observer.observe(container.value);
  });
  onUpdated(measure);
  onBeforeUnmount(() => observer?.disconnect());
  return { firstRowCount, firstRowHeight, overflowing, width };
}
