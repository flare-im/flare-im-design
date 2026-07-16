<script setup lang="ts">
// Unified root-level config provider — app-wide default control size + density,
// plus live language (locale) and theme (light/dark) switching. Reads/switches
// through useFlareConfig() in any descendant. Wires the canonical i18n + theme
// systems so language/theme changes persist and re-render the whole subtree.
import { ref } from "vue";
import { useFlareI18nProvider, type FlareLocale } from "../../shared/i18n/useFlareI18n";
import { useFlareThemeProvider, type FlareThemeMode } from "../../design-system/theme/use-flare-theme";
import { provideFlareConfig, type FlareConfigApi, type FlareDensity } from "../../shared/useFlareConfig";
import type { FlareControlSize } from "../../shared/contracts";

const props = withDefaults(
  defineProps<{
    size?: FlareControlSize;
    density?: FlareDensity;
    /** Initial language. */
    locale?: FlareLocale;
    /** Initial theme mode. */
    theme?: FlareThemeMode;
  }>(),
  { size: "md", density: "default" },
);

const i18n = useFlareI18nProvider(props.locale);
const themeCtx = useFlareThemeProvider(props.theme);

const size = ref<FlareControlSize>(props.size);
const api: FlareConfigApi = {
  size,
  setSize: (s) => { size.value = s; },
  density: ref<FlareDensity>(props.density),
  locale: i18n.locale,
  setLocale: i18n.setLocale,
  themeMode: themeCtx.mode,
  isDark: themeCtx.isDark,
  setThemeMode: themeCtx.setMode,
  toggleTheme: () => themeCtx.setMode(themeCtx.isDark.value ? "light" : "dark"),
};
provideFlareConfig(api);
</script>

<template>
  <slot />
</template>
