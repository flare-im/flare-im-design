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
