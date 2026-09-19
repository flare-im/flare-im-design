import {
  computed,
  inject,
  onMounted,
  onUnmounted,
  provide,
  readonly,
  ref,
  watch,
  type InjectionKey,
  type Ref,
} from "vue";
import type { GlobalThemeOverrides } from "naive-ui";
import {
  applyFlareColorScheme,
  isSystemDarkPreferred,
  watchPreferredColorScheme,
  type FlareBrandTheme,
} from "./apply-flare-theme";
import { createNaiveThemeOverrides } from "./im-theme";

export type FlareThemeMode = "light" | "dark" | "system";

/**
 * Whether to draw dark, from the person's choice and the platform's own setting
 * (`spec/theme-mode-vectors.json`, the same rule on four kits): `light` and `dark` are the person
 * overriding the system, `system` follows it.
 */
export function flareThemeIsDark(mode: FlareThemeMode, systemDark: boolean): boolean {
  return mode === "system" ? systemDark : mode === "dark";
}
export type FlareThemeVariant = "default" | "compact" | "callDark" | "highContrast";

const MODE_STORAGE_KEY = "flare-web-theme-mode";
const VARIANT_STORAGE_KEY = "flare-web-theme-variant";
const BRAND_STORAGE_KEY = "flare-web-brand-theme";

export type FlareThemeContext = {
  mode: Readonly<Ref<FlareThemeMode>>;
  variant: Readonly<Ref<FlareThemeVariant>>;
  brand: Readonly<Ref<FlareBrandTheme>>;
  isDark: Readonly<Ref<boolean>>;
  naiveThemeOverrides: Readonly<Ref<GlobalThemeOverrides>>;
  setMode: (mode: FlareThemeMode) => void;
  setVariant: (variant: FlareThemeVariant) => void;
  setBrand: (brand: FlareBrandTheme) => void;
};

const flareThemeKey: InjectionKey<FlareThemeContext> = Symbol("flare-theme");

function readStoredMode(): FlareThemeMode {
  if (typeof localStorage === "undefined") return "system";
  const raw = localStorage.getItem(MODE_STORAGE_KEY);
  if (raw === "light" || raw === "dark" || raw === "system") return raw;
  return "system";
}

function readStoredVariant(): FlareThemeVariant {
  if (typeof localStorage === "undefined") return "default";
  const raw = localStorage.getItem(VARIANT_STORAGE_KEY);
  if (raw === "default" || raw === "compact" || raw === "callDark" || raw === "highContrast") return raw;
  return "default";
}

function readStoredBrand(): FlareBrandTheme {
  if (typeof localStorage === "undefined") return "violet";
  const raw = localStorage.getItem(BRAND_STORAGE_KEY);
  return ["violet", "ocean", "forest", "sunset", "rose", "graphite"].includes(raw ?? "")
    ? raw as FlareBrandTheme
    : "violet";
}

export function useFlareThemeProvider(
  initialMode: FlareThemeMode = readStoredMode(),
  initialVariant: FlareThemeVariant = readStoredVariant(),
  initialBrand: FlareBrandTheme = readStoredBrand(),
): FlareThemeContext {
  const mode = ref<FlareThemeMode>(initialMode);
  const variant = ref<FlareThemeVariant>(initialVariant);
  const brand = ref<FlareBrandTheme>(initialBrand);
  const systemDark = ref(isSystemDarkPreferred());
  const isDark = computed(() => {
    // The call variant is a Vue-only surface that is dark whatever the person chose.
    if (variant.value === "callDark") return true;
    return flareThemeIsDark(mode.value, systemDark.value);
  });
  const naiveThemeOverrides = computed(() =>
    createNaiveThemeOverrides(isDark.value ? "dark" : "light", brand.value),
  );

  function syncTheme(): void {
    applyFlareColorScheme(brand.value, isDark.value, variant.value);
  }

  function setMode(next: FlareThemeMode): void {
    mode.value = next;
    if (typeof localStorage !== "undefined") {
      localStorage.setItem(MODE_STORAGE_KEY, next);
    }
    syncTheme();
  }

  function setVariant(next: FlareThemeVariant): void {
    variant.value = next;
    if (typeof localStorage !== "undefined") {
      localStorage.setItem(VARIANT_STORAGE_KEY, next);
    }
    syncTheme();
  }

  function setBrand(next: FlareBrandTheme): void {
    brand.value = next;
    if (typeof next === "string" && typeof localStorage !== "undefined") {
      localStorage.setItem(BRAND_STORAGE_KEY, next);
    }
    syncTheme();
  }

  watch([isDark, variant, brand], syncTheme, { immediate: true });

  let stopMq: (() => void) | undefined;
  onMounted(() => {
    stopMq = watchPreferredColorScheme((dark) => {
      systemDark.value = dark;
    });
  });
  onUnmounted(() => stopMq?.());

  const ctx: FlareThemeContext = {
    mode: readonly(mode),
    variant: readonly(variant),
    brand: readonly(brand),
    isDark: readonly(isDark),
    naiveThemeOverrides: readonly(naiveThemeOverrides),
    setMode,
    setVariant,
    setBrand,
  };
  provide(flareThemeKey, ctx);
  return ctx;
}

export function useFlareTheme(): FlareThemeContext {
  const ctx = inject(flareThemeKey);
  return ctx ?? useFlareThemeProvider();
}
