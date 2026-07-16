// Global UI config — app-level defaults injected once at the root and read by
// components (currently: default control size + density). Set it via
// <FlareConfigProvider :size="..."> (or provideFlareConfig in a setup); read it
// with useFlareConfig(). Defaults keep every component working with no provider.
import { inject, provide, readonly, ref, type InjectionKey, type Ref } from "vue";
import type { FlareControlSize } from "./contracts";

export type FlareDensity = "compact" | "default";

export interface FlareConfig {
  /** Default size for sized controls (Button / IconButton / Select …). */
  size: FlareControlSize;
  /** Reserved for spacing density presets. */
  density: FlareDensity;
}

const DEFAULT_CONFIG: FlareConfig = { size: "md", density: "default" };
const FLARE_CONFIG_KEY: InjectionKey<Readonly<Ref<FlareConfig>>> = Symbol("flare-config");

/** Provide app-level defaults (call in a root setup, or use FlareConfigProvider). */
export function provideFlareConfig(config: Partial<FlareConfig> = {}): void {
  provide(FLARE_CONFIG_KEY, readonly(ref({ ...DEFAULT_CONFIG, ...config })));
}

/** Read the current config; falls back to sensible defaults with no provider. */
export function useFlareConfig(): Readonly<Ref<FlareConfig>> {
  return inject(FLARE_CONFIG_KEY, readonly(ref(DEFAULT_CONFIG)));
}
