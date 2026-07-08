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

/** 与 web-app `app.css` / `responsive.css` 中 `@media (min-width: 900px)` 保持一致 */
export const BREAKPOINT_DESKTOP_PX = 900;
export const BREAKPOINT_TABLET_PX = 600;

export type ViewportMode = "mobile" | "tablet" | "desktop";

export type ViewportContext = {
  width: Readonly<Ref<number>>;
  mode: Readonly<Ref<ViewportMode>>;
  isDesktop: Readonly<Ref<boolean>>;
  isMobile: Readonly<Ref<boolean>>;
  isTablet: Readonly<Ref<boolean>>;
};

const viewportKey: InjectionKey<ViewportContext> = Symbol("flare-viewport");

function readWidth(): number {
  if (typeof window === "undefined") return BREAKPOINT_DESKTOP_PX;
  return window.innerWidth;
}

function resolveMode(width: number): ViewportMode {
  if (width >= BREAKPOINT_DESKTOP_PX) return "desktop";
  if (width >= BREAKPOINT_TABLET_PX) return "tablet";
  return "mobile";
}

function applyDocumentViewport(mode: ViewportMode, width: number): void {
  if (typeof document === "undefined") return;
  const root = document.documentElement;
  root.dataset.viewport = mode;
  root.style.setProperty("--viewport-width", `${width}px`);
}

export function useViewportProvider(): ViewportContext {
  const width = ref(readWidth());
  const mode = computed(() => resolveMode(width.value));
  const isDesktop = computed(() => mode.value === "desktop");
  const isMobile = computed(() => mode.value === "mobile");
  const isTablet = computed(() => mode.value === "tablet");

  function sync(): void {
    width.value = readWidth();
    applyDocumentViewport(mode.value, width.value);
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

  applyDocumentViewport(mode.value, width.value);

  const ctx: ViewportContext = {
    width: readonly(width),
    mode: readonly(mode),
    isDesktop: readonly(isDesktop),
    isMobile: readonly(isMobile),
    isTablet: readonly(isTablet),
  };
  provide(viewportKey, ctx);
  return ctx;
}

export function useViewport(): ViewportContext {
  const ctx = inject(viewportKey);
  if (!ctx) {
    throw new Error("useViewport() 需要在 App 根组件调用 useViewportProvider()");
  }
  return ctx;
}
