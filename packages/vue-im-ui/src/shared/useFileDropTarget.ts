import { computed, ref } from "vue";

/** DOM interaction only: selection policy and transfer stay with the host. */
export function useFileDropTarget(enabled: () => boolean, onFiles: (files: File[]) => void) {
  const depth = ref(0);
  const dragging = computed(() => enabled() && depth.value > 0);
  const hasFiles = (event: DragEvent) => Array.from(event.dataTransfer?.types ?? []).includes("Files");
  function enter(event: DragEvent) {
    if (!hasFiles(event)) return;
    event.preventDefault(); event.stopPropagation(); depth.value++;
  }
  function over(event: DragEvent) {
    if (!hasFiles(event)) return;
    event.preventDefault(); event.stopPropagation();
    if (event.dataTransfer) event.dataTransfer.dropEffect = enabled() ? "copy" : "none";
  }
  function leave(event: DragEvent) {
    if (hasFiles(event)) { event.stopPropagation(); depth.value = Math.max(0, depth.value - 1); }
  }
  function dropped(event: DragEvent) {
    const files = Array.from(event.dataTransfer?.files ?? []);
    depth.value = 0;
    if (!files.length && !hasFiles(event)) return;
    event.preventDefault(); event.stopPropagation();
    if (enabled() && files.length) onFiles(files);
  }
  return { dragging, enter, over, leave, dropped };
}
