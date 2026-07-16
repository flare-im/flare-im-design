// Global UI config — one root-level provider for app-wide defaults AND live
// switching of language + theme. Set it via <FlareConfigProvider :size :locale
// :theme>; read/switch with useFlareConfig(): size/density defaults plus
// locale+setLocale and themeMode/isDark+setThemeMode/toggleTheme. Falls back to
// safe no-ops with no provider so every component works standalone.
import { inject, provide, ref, type InjectionKey, type Ref } from "vue";
import type { FlareControlSize } from "./contracts";
import type { FlareLocale } from "./i18n/useFlareI18n";
import type { FlareThemeMode } from "../design-system/theme/use-flare-theme";

export type FlareDensity = "compact" | "default";

/** The unified config surface returned by useFlareConfig(). */
export interface FlareConfigApi {
  /** Default size for sized controls (Button / IconButton / Select …). */
  size: Ref<FlareControlSize>;
  setSize: (size: FlareControlSize) => void;
  /** Reserved for spacing density presets. */
  density: Ref<FlareDensity>;
  /** Current language, and a switcher. */
  locale: Ref<FlareLocale>;
  setLocale: (locale: FlareLocale) => void;
  /** Theme mode ("light" | "dark" | "system"), whether currently dark, switchers. */
  themeMode: Ref<FlareThemeMode>;
  isDark: Ref<boolean>;
  setThemeMode: (mode: FlareThemeMode) => void;
  /** Flip between light and dark. */
  toggleTheme: () => void;
}

const FLARE_CONFIG_KEY: InjectionKey<FlareConfigApi> = Symbol("flare-config");

function defaultApi(): FlareConfigApi {
  return {
    size: ref<FlareControlSize>("md"),
    setSize: () => {},
    density: ref<FlareDensity>("default"),
    locale: ref<FlareLocale>("zh-CN"),
    setLocale: () => {},
    themeMode: ref<FlareThemeMode>("system"),
    isDark: ref(false),
    setThemeMode: () => {},
    toggleTheme: () => {},
  };
}

/** Provide the unified config (usually via FlareConfigProvider). */
export function provideFlareConfig(api: FlareConfigApi): void {
  provide(FLARE_CONFIG_KEY, api);
}

/** Read the config + language/theme switchers; safe no-op defaults with no provider. */
export function useFlareConfig(): FlareConfigApi {
  return inject(FLARE_CONFIG_KEY, defaultApi());
}
