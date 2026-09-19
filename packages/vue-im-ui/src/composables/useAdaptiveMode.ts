import {
  computed,
  inject,
  onMounted,
  onUnmounted,
  provide,
  readonly,
  ref,
  type InjectionKey,
  type Ref,
} from "vue";
import type { FlareApplicationResponsiveMode } from "../shared/contracts/application";
import type { FlareLayoutMode, FlareViewportKind } from "../shared/contracts/layout";
import {
  FLARE_BREAKPOINT_DESKTOP_MIN,
  FLARE_BREAKPOINT_H5_MAX,
  FLARE_BREAKPOINT_IPAD_MAX,
} from "../shared/contracts/layout";

export type FlareAdaptiveContext = {
  width: Readonly<Ref<number>>;
  viewportKind: Readonly<Ref<FlareViewportKind>>;
  layoutMode: Readonly<Ref<FlareLayoutMode>>;
  isPc: Readonly<Ref<boolean>>;
  isIpad: Readonly<Ref<boolean>>;
  isH5: Readonly<Ref<boolean>>;
  setLayoutMode: (mode: FlareLayoutMode) => void;
};

const adaptiveKey: InjectionKey<FlareAdaptiveContext> = Symbol("flare-adaptive");

function readWidth(): number {
  if (typeof window === "undefined") return FLARE_BREAKPOINT_DESKTOP_MIN;
  // Guard against a 0 innerWidth at first paint (iframe / pre-layout) which would
  // wrongly classify as the smallest breakpoint until a resize fires.
  return window.innerWidth || document.documentElement?.clientWidth || FLARE_BREAKPOINT_DESKTOP_MIN;
}

function resolveViewportKind(width: number): FlareViewportKind {
  if (width >= FLARE_BREAKPOINT_DESKTOP_MIN) return "pc";
  if (width > FLARE_BREAKPOINT_H5_MAX) return "ipad";
  return "h5";
}

function resolveEffectiveKind(mode: FlareLayoutMode, width: number): FlareViewportKind {
  if (mode === "pc") return "pc";
  if (mode === "ipad") return "ipad";
  if (mode === "h5") return "h5";
  return resolveViewportKind(width);
}

export function useFlareAdaptiveProvider(initialMode: FlareLayoutMode = "auto"): FlareAdaptiveContext {
  const width = ref(readWidth());
  const layoutMode = ref<FlareLayoutMode>(initialMode);
  const viewportKind = computed(() => resolveEffectiveKind(layoutMode.value, width.value));
  const isPc = computed(() => viewportKind.value === "pc");
  const isIpad = computed(() => viewportKind.value === "ipad");
  const isH5 = computed(() => viewportKind.value === "h5");

  function sync(): void {
    width.value = readWidth();
    if (typeof document !== "undefined") {
      document.documentElement.dataset.flareViewport = viewportKind.value;
      document.documentElement.style.setProperty("--flare-viewport-width", `${width.value}px`);
    }
  }

  function setLayoutMode(mode: FlareLayoutMode): void {
    layoutMode.value = mode;
    sync();
  }

  onMounted(() => {
    sync();
    window.addEventListener("resize", sync, { passive: true });
    window.addEventListener("orientationchange", sync);
  });

  onUnmounted(() => {
    window.removeEventListener("resize", sync);
    window.removeEventListener("orientationchange", sync);
  });

  const ctx: FlareAdaptiveContext = {
    width: readonly(width),
    viewportKind: readonly(viewportKind),
    layoutMode: readonly(layoutMode),
    isPc: readonly(isPc),
    isIpad: readonly(isIpad),
    isH5: readonly(isH5),
    setLayoutMode,
  };
  provide(adaptiveKey, ctx);
  return ctx;
}

export function useFlareAdaptive(): FlareAdaptiveContext {
  const ctx = inject(adaptiveKey);
  if (!ctx) {
    throw new Error("useFlareAdaptive() requires useFlareAdaptiveProvider()");
  }
  return ctx;
}

/**
 * Graceful adaptive accessor for standalone components (Select, sheets…) that
 * must render sensibly with no provider. Falls back to a static "pc" context so
 * a component used bare defaults to the desktop presentation. Inside an
 * application shell the answer is the shell's (see `provideFlareShellAdaptive`).
 */
export function useFlareAdaptiveSafe(): FlareAdaptiveContext {
  return inject(adaptiveKey, null) ?? staticDesktopContext();
}

function staticDesktopContext(): FlareAdaptiveContext {
  const width = readonly(ref(FLARE_BREAKPOINT_DESKTOP_MIN));
  const viewportKind = readonly(ref<FlareViewportKind>("pc"));
  return {
    width,
    viewportKind,
    layoutMode: readonly(ref<FlareLayoutMode>("auto")),
    isPc: readonly(ref(true)),
    isIpad: readonly(ref(false)),
    isH5: readonly(ref(false)),
    setLayoutMode: () => {},
  };
}

/** The form factor a shell's measured mode stands for: the breakpoints are the same two (600 and 900). */
function flareViewportKindForShellMode(mode: FlareApplicationResponsiveMode): FlareViewportKind {
  if (mode === "mobile") return "h5";
  if (mode === "tablet") return "ipad";
  return "pc";
}

/**
 * Called by an application shell (FR-139): everything inside it asks "is this a phone" of the shell's own box, not of
 * the window. The kind is the host's explicit `layoutMode` when it set one, else the shell's measured mode, else — until
 * the shell has measured — what the context above says (the window, or the desktop default without a provider).
 * `width` stays the window's, and `setLayoutMode` still sets the host's mode.
 *
 * Internal: provided through `provideFlareShell`, not exported from the package.
 */
export function provideFlareShellAdaptive(
  responsiveMode: Readonly<Ref<FlareApplicationResponsiveMode | undefined>>,
): FlareAdaptiveContext {
  const outer = inject(adaptiveKey, null) ?? staticDesktopContext();
  const viewportKind = computed<FlareViewportKind>(() => {
    const explicit = outer.layoutMode.value;
    if (explicit !== "auto") return explicit;
    const mode = responsiveMode.value;
    return mode === undefined ? outer.viewportKind.value : flareViewportKindForShellMode(mode);
  });
  const ctx: FlareAdaptiveContext = {
    width: outer.width,
    viewportKind: readonly(viewportKind),
    layoutMode: outer.layoutMode,
    isPc: readonly(computed(() => viewportKind.value === "pc")),
    isIpad: readonly(computed(() => viewportKind.value === "ipad")),
    isH5: readonly(computed(() => viewportKind.value === "h5")),
    setLayoutMode: outer.setLayoutMode,
  };
  provide(adaptiveKey, ctx);
  return ctx;
}
