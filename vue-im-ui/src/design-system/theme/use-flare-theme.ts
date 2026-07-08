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
import { applyFlareTheme, isSystemDarkPreferred, watchPreferredColorScheme } from "./apply-flare-theme";
import { createNaiveThemeOverrides } from "./im-theme";

export type FlareThemeMode = "light" | "dark" | "system";
export type FlareThemeVariant = "default" | "compact" | "callDark" | "highContrast";

const MODE_STORAGE_KEY = "flare-web-theme-mode";
const VARIANT_STORAGE_KEY = "flare-web-theme-variant";

export type FlareThemeContext = {
  mode: Readonly<Ref<FlareThemeMode>>;
  variant: Readonly<Ref<FlareThemeVariant>>;
  isDark: Readonly<Ref<boolean>>;
  naiveThemeOverrides: Readonly<Ref<GlobalThemeOverrides>>;
  setMode: (mode: FlareThemeMode) => void;
  setVariant: (variant: FlareThemeVariant) => void;
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

function resolveDark(mode: FlareThemeMode): boolean {
  if (mode === "dark") return true;
  if (mode === "light") return false;
  return isSystemDarkPreferred();
}

export function useFlareThemeProvider(
  initialMode: FlareThemeMode = readStoredMode(),
  initialVariant: FlareThemeVariant = readStoredVariant(),
): FlareThemeContext {
  const mode = ref<FlareThemeMode>(initialMode);
  const variant = ref<FlareThemeVariant>(initialVariant);
  const isDark = computed(() => {
    if (variant.value === "callDark") return true;
    return resolveDark(mode.value);
  });
  const naiveThemeOverrides = computed(() => createNaiveThemeOverrides(isDark.value));

  function syncTheme(): void {
    applyFlareTheme(isDark.value, variant.value);
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

  watch([isDark, variant], syncTheme, { immediate: true });

  onMounted(() => {
    const stopMq = watchPreferredColorScheme(() => {
      if (mode.value === "system") syncTheme();
    });
    onUnmounted(stopMq);
  });

  const ctx: FlareThemeContext = {
    mode: readonly(mode),
    variant: readonly(variant),
    isDark: readonly(isDark),
    naiveThemeOverrides: readonly(naiveThemeOverrides),
    setMode,
    setVariant,
  };
  provide(flareThemeKey, ctx);
  return ctx;
}

export function useFlareTheme(): FlareThemeContext {
  const ctx = inject(flareThemeKey);
  return ctx ?? useFlareThemeProvider();
}
