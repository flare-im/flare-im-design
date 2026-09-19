import {
  computed,
  inject,
  onMounted,
  onUnmounted,
  provide,
  readonly,
  ref,
  shallowReadonly,
  shallowRef,
  type InjectionKey,
  type Ref,
} from "vue";
import type { FlareAdaptiveContext } from "../../composables/useAdaptiveMode";
import {
  FLARE_DEFAULT_PLATFORM_CAPABILITIES,
  type FlarePlatformAdapter,
  type FlarePlatformCapabilities,
  type FlarePlatformKind,
} from "./contract";
import { createWebPlatformAdapter, detectWebCapabilities } from "./web-adapter";

export interface FlarePlatformContext {
  kind: Readonly<Ref<FlarePlatformKind>>;
  capabilities: Readonly<Ref<FlarePlatformCapabilities>>;
  adapter: Readonly<Ref<FlarePlatformAdapter>>;
}

export interface FlarePlatformOptions {
  /** Host identity, informational only (components never branch on it). */
  kind?: FlarePlatformKind;
  /** Host-implemented native operations; defaults to the web adapter. */
  adapter?: FlarePlatformAdapter;
  /** Explicit capability overrides on top of what the web can detect. */
  capabilities?: Partial<FlarePlatformCapabilities>;
  /** The adaptive context of the same provider, for `bottomSheet` (phone form factor). */
  adaptive?: FlareAdaptiveContext;
}

const platformKey: InjectionKey<FlarePlatformContext> = Symbol("flare-platform");

/** The host's explicit capability overrides of each provided context, so a shell can re-derive `bottomSheet` under them. */
const hostOverrides = new WeakMap<FlarePlatformContext, Readonly<Ref<Partial<FlarePlatformCapabilities>>>>();

const POINTER_QUERIES = ["(pointer: fine)", "(pointer: coarse)", "(any-pointer: fine)", "(hover: hover)"];

/**
 * Provide the platform contract for a subtree. Pointer / hover capabilities are
 * detected once and re-detected when the matching media queries change; the
 * host's `capabilities` win over detection; `bottomSheet` follows the adaptive
 * viewport kind (h5) unless overridden.
 */
export function useFlarePlatformProvider(options: FlarePlatformOptions = {}): FlarePlatformContext {
  const adapter = shallowRef<FlarePlatformAdapter>(options.adapter ?? createWebPlatformAdapter());
  const kind = ref<FlarePlatformKind>(options.kind ?? "web");
  const detected = ref(detectWebCapabilities(adapter.value));
  const overrides = ref<Partial<FlarePlatformCapabilities>>({ ...options.capabilities });

  function sync(): void {
    detected.value = detectWebCapabilities(adapter.value);
  }

  onMounted(() => {
    if (typeof window === "undefined" || typeof window.matchMedia !== "function") return;
    const lists = POINTER_QUERIES.map((query) => window.matchMedia(query));
    lists.forEach((list) => list.addEventListener?.("change", sync));
    sync();
    onUnmounted(() => lists.forEach((list) => list.removeEventListener?.("change", sync)));
  });

  const capabilities = computed<FlarePlatformCapabilities>(() => ({
    ...FLARE_DEFAULT_PLATFORM_CAPABILITIES,
    ...detected.value,
    bottomSheet: options.adaptive ? options.adaptive.isH5.value : false,
    ...overrides.value,
  }));

  const ctx: FlarePlatformContext = {
    kind: readonly(kind),
    capabilities,
    adapter: shallowReadonly(adapter),
  };
  hostOverrides.set(ctx, overrides);
  provide(platformKey, ctx);
  return ctx;
}

/**
 * Called by an application shell (FR-139): inside it `bottomSheet` follows the shell's adaptive context — a phone-sized
 * shell box presents sheets, whatever the window — unless the host set `bottomSheet` explicitly. Everything else is
 * the context above (or the standalone fallback).
 *
 * Internal: provided through `provideFlareShell`, not exported from the package.
 */
export function provideFlareShellPlatform(adaptive: FlareAdaptiveContext): FlarePlatformContext {
  const outer = useFlarePlatformSafe();
  const overrides = hostOverrides.get(outer);
  const ctx: FlarePlatformContext = {
    kind: outer.kind,
    adapter: outer.adapter,
    capabilities: computed<FlarePlatformCapabilities>(() => ({
      ...outer.capabilities.value,
      bottomSheet: adaptive.isH5.value,
      ...overrides?.value,
    })),
  };
  if (overrides) hostOverrides.set(ctx, overrides);
  provide(platformKey, ctx);
  return ctx;
}

export function useFlarePlatform(): FlarePlatformContext {
  const ctx = inject(platformKey);
  if (!ctx) throw new Error("useFlarePlatform() requires useFlarePlatformProvider() (FlareUiProvider) in an ancestor component.");
  return ctx;
}

let fallbackContext: FlarePlatformContext | null = null;

/**
 * Graceful accessor for standalone components: the provider's context when
 * present, otherwise a static one detected once from the browser.
 */
export function useFlarePlatformSafe(): FlarePlatformContext {
  const ctx = inject(platformKey, null);
  if (ctx) return ctx;
  if (!fallbackContext) {
    const adapter = createWebPlatformAdapter();
    fallbackContext = {
      kind: readonly(ref<FlarePlatformKind>("web")),
      capabilities: readonly(ref<FlarePlatformCapabilities>({ ...FLARE_DEFAULT_PLATFORM_CAPABILITIES, ...detectWebCapabilities(adapter), bottomSheet: false })),
      adapter: shallowReadonly(shallowRef(adapter)),
    };
  }
  return fallbackContext;
}
