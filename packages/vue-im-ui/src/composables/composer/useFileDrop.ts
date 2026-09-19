import { computed, ref, type ComputedRef, type Ref } from "vue";

export interface UseFileDropOptions {
  enabled: () => boolean;
  /** Drops are accepted only while this is true (not read-only, not blocked). */
  accepts: () => boolean;
  onFiles: (files: File[]) => void;
}

export interface FileDropHandlers {
  active: ComputedRef<boolean>;
  depth: Ref<number>;
  reset(): void;
  onDragEnter(event: DragEvent): void;
  onDragLeave(): void;
  onDragOver(event: DragEvent): void;
  onDrop(event: DragEvent): void;
}

function isFileDrag(event: DragEvent): boolean {
  return Boolean(event.dataTransfer?.types.includes("Files"));
}

/** Depth-counted drag tracking so nested children never flicker the drop hint. */
export function useFileDrop(options: UseFileDropOptions): FileDropHandlers {
  const depth = ref(0);
  const active = computed(() => options.enabled() && options.accepts() && depth.value > 0);
  return {
    active,
    depth,
    reset() { depth.value = 0; },
    onDragEnter(event) {
      if (!options.enabled() || !isFileDrag(event)) return;
      event.preventDefault();
      depth.value += 1;
    },
    onDragLeave() { depth.value = Math.max(0, depth.value - 1); },
    onDragOver(event) {
      if (!options.enabled() || !isFileDrag(event)) return;
      event.preventDefault();
      if (event.dataTransfer) event.dataTransfer.dropEffect = options.accepts() ? "copy" : "none";
    },
    onDrop(event) {
      depth.value = 0;
      if (!options.enabled() || !isFileDrag(event)) return;
      event.preventDefault();
      const files = Array.from(event.dataTransfer?.files ?? []);
      if (options.accepts() && files.length) options.onFiles(files);
    },
  };
}
