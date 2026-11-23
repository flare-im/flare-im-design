import { getCurrentInstance, inject, provide, type InjectionKey, type Ref } from "vue";

/** What a FlareCallSurface window lends the call view inside it (docs/plugin-experience.md §3.1). */
interface CallWindow {
  /** A floating window (PC, tablet), not a phone's full screen: only it expands. */
  windowed: () => boolean;
  expanded: Ref<boolean>;
  minimize: () => void;
  /** The window's host listens to its minimize. */
  listensMinimize: () => boolean;
}
const callWindowKey: InjectionKey<CallWindow> = Symbol("flareCallWindow");

/** FlareCallSurface: lend the window to the call view inside it. */
export function provideCallWindow(surface: CallWindow): void {
  provide(callWindowKey, surface);
}

/**
 * A call view's top-bar keys (§3.1): minimize, drawn while the view's host or its window's host listens (pressing it
 * emits on both), and, in a floating window, expand / collapse in the same row. Listeners are read at render.
 */
export function useCallWindow(emitMinimize: () => void) {
  const surface = inject(callWindowKey, null);
  const instance = getCurrentInstance();
  return {
    canMinimize: () => Boolean(instance?.vnode.props?.onMinimize) || Boolean(surface?.listensMinimize()),
    minimize: () => {
      emitMinimize();
      surface?.minimize();
    },
    expandable: () => Boolean(surface?.windowed()),
    expanded: () => Boolean(surface?.expanded.value),
    toggleExpanded: () => {
      if (surface) surface.expanded.value = !surface.expanded.value;
    },
  };
}
