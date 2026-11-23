import { computed, onBeforeUnmount, shallowRef, toValue, watch, type CSSProperties, type MaybeRefOrGetter } from "vue";

/** Body-level overlays follow the keyboard's visible rectangle; scoped previews keep their own geometry. */
export function useFlareVisibleViewport(enabled: MaybeRefOrGetter<boolean>) {
  const bounds = shallowRef<{ top: number; left: number; width: number; height: number }>();
  let release: (() => void) | undefined;
  watch(() => toValue(enabled), active => {
    release?.(); release = undefined; bounds.value = undefined;
    if (!active || typeof window === "undefined" || !window.visualViewport) return;
    const viewport = window.visualViewport;
    function sync() {
      // Pinch zoom belongs to the browser. Do not counteract zoom or pan a scaled page.
      const valid = Math.abs(viewport.scale - 1) < 0.01 && [viewport.height, viewport.width, viewport.offsetTop, viewport.offsetLeft].every(Number.isFinite) && viewport.height > 0 && viewport.width > 0;
      const changed = viewport.height < window.innerHeight - 1 || viewport.offsetTop > 1 || viewport.offsetLeft > 1;
      bounds.value = valid && changed ? { top: viewport.offsetTop, left: viewport.offsetLeft, width: viewport.width, height: viewport.height } : undefined;
    }
    viewport.addEventListener("resize", sync); viewport.addEventListener("scroll", sync); window.addEventListener("resize", sync);
    sync();
    release = () => { viewport.removeEventListener("resize", sync); viewport.removeEventListener("scroll", sync); window.removeEventListener("resize", sync); };
  }, { immediate: true });
  onBeforeUnmount(() => release?.());
  const style = computed<CSSProperties | undefined>(() => bounds.value ? {
    top: `${bounds.value.top}px`, left: `${bounds.value.left}px`, width: `${bounds.value.width}px`, height: `${bounds.value.height}px`, right: "auto", bottom: "auto",
    "--flare-visible-viewport-height": `${bounds.value.height}px`,
  } : undefined);
  return { style };
}
