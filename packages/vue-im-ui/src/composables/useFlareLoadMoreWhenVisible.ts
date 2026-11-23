import { getCurrentScope, onScopeDispose, toValue, watch, type Ref } from "vue";

export interface FlareLoadMoreWhenVisibleOptions {
  /**
   * How far past the visible area the target still counts as visible, as a CSS margin. The default `400px` asks for
   * the next page 400px before the reader reaches the end, the way Flutter lists do.
   */
  rootMargin?: string;
  /**
   * While false nothing is observed (a page is loading, there is no next page). Turning it on again observes afresh,
   * so a target still within reach after a page arrived asks for the next one at once.
   */
  enabled?: Ref<boolean> | (() => boolean);
  /**
   * The scroll container the margin applies to. Left out, the nearest scrolling ancestor of the target is used, and
   * the viewport when there is none.
   */
  root?: Ref<HTMLElement | null | undefined> | (() => HTMLElement | null | undefined);
}

/** The default reach: the next page is asked for 400px before the end. */
export const FLARE_LOAD_MORE_ROOT_MARGIN = "400px";

function scrollingAncestor(target: HTMLElement): HTMLElement | null {
  if (typeof getComputedStyle !== "function") return null;
  const documentElement = target.ownerDocument?.documentElement;
  for (let node = target.parentElement; node && node !== documentElement && node !== target.ownerDocument?.body; node = node.parentElement) {
    const overflow = getComputedStyle(node).overflowY;
    if (overflow === "auto" || overflow === "scroll" || overflow === "overlay") return node;
  }
  return null;
}

/**
 * Calls `onVisible` when `target` (a sentinel after the last row, a list's footer) comes within `rootMargin` of the
 * visible area, through an `IntersectionObserver`, and stops observing when the calling scope ends. It replaces
 * Flutter's "load the next page 400px before the end". Without `IntersectionObserver` (SSR, tests) it does nothing.
 * The host decides what a visible target means; the composable asks for nothing itself.
 */
export function useFlareLoadMoreWhenVisible(
  target: Ref<HTMLElement | null | undefined>,
  onVisible: () => void,
  options: FlareLoadMoreWhenVisibleOptions = {},
): void {
  if (typeof IntersectionObserver === "undefined") return;
  let observer: IntersectionObserver | null = null;
  const enabled = () => (options.enabled === undefined ? true : Boolean(toValue(options.enabled)));

  function disconnect(): void {
    observer?.disconnect();
    observer = null;
  }

  const stop = watch(
    () => [target.value, enabled(), options.root === undefined ? undefined : toValue(options.root)] as const,
    ([element, on, root]) => {
      disconnect();
      if (!element || !on) return;
      observer = new IntersectionObserver(
        (entries) => {
          if (!enabled()) return;
          if (entries.some((entry) => entry.isIntersecting)) onVisible();
        },
        { root: root ?? scrollingAncestor(element), rootMargin: options.rootMargin ?? FLARE_LOAD_MORE_ROOT_MARGIN },
      );
      observer.observe(element);
    },
    { immediate: true, flush: "post" },
  );

  if (getCurrentScope()) {
    onScopeDispose(() => {
      stop();
      disconnect();
    });
  }
}
