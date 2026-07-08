import { onBeforeUnmount, toValue, watch, type MaybeRefOrGetter, type Ref } from "vue";

export function useLongPress(
  target: Ref<HTMLElement | null | undefined>,
  options: {
    enabled: MaybeRefOrGetter<boolean>;
    delayMs?: MaybeRefOrGetter<number>;
    onLongPress: (event: TouchEvent) => void;
  },
): void {
  const delayMs = () => toValue(options.delayMs) ?? 500;
  let timer: number | undefined;
  let activeTouchId: number | undefined;

  function clearTimer(): void {
    if (timer !== undefined) {
      window.clearTimeout(timer);
      timer = undefined;
    }
  }

  function onTouchStart(event: TouchEvent): void {
    if (!toValue(options.enabled)) return;
    if (event.touches.length !== 1) return;
    clearTimer();
    const touch = event.touches[0];
    if (!touch) return;
    activeTouchId = touch.identifier;
    timer = window.setTimeout(() => {
      timer = undefined;
      options.onLongPress(event);
    }, delayMs());
  }

  function onTouchEnd(event: TouchEvent): void {
    if (activeTouchId === undefined) {
      clearTimer();
      return;
    }
    const ended = Array.from(event.changedTouches).some((t) => t.identifier === activeTouchId);
    if (ended) {
      activeTouchId = undefined;
      clearTimer();
    }
  }

  function onTouchMove(): void {
    clearTimer();
    activeTouchId = undefined;
  }

  function bind(el: HTMLElement): void {
    el.addEventListener("touchstart", onTouchStart, { passive: true });
    el.addEventListener("touchend", onTouchEnd, { passive: true });
    el.addEventListener("touchcancel", onTouchEnd, { passive: true });
    el.addEventListener("touchmove", onTouchMove, { passive: true });
  }

  function unbind(el: HTMLElement): void {
    el.removeEventListener("touchstart", onTouchStart);
    el.removeEventListener("touchend", onTouchEnd);
    el.removeEventListener("touchcancel", onTouchEnd);
    el.removeEventListener("touchmove", onTouchMove);
  }

  let boundEl: HTMLElement | null = null;

  watch(
    () => target.value,
    (el) => {
      if (boundEl) {
        unbind(boundEl);
        boundEl = null;
      }
      clearTimer();
      if (!el) return;
      boundEl = el;
      bind(el);
    },
    { immediate: true },
  );

  onBeforeUnmount(() => {
    clearTimer();
    if (boundEl) unbind(boundEl);
  });
}
