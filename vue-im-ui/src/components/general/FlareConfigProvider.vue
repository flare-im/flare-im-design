<script setup lang="ts">
// Unified root-level config provider — app-wide default control size + density,
// plus live language (locale) and theme (light/dark) switching. Reads/switches
// through useFlareConfig() in any descendant. Wires the canonical i18n + theme
// systems so language/theme changes persist and re-render the whole subtree.
import { ref, watch } from "vue";
import { useFlareI18nProvider, type FlareLocale } from "../../shared/i18n/useFlareI18n";
import { useFlareThemeProvider, type FlareThemeMode } from "../../design-system/theme/use-flare-theme";
import { useFlareAdaptiveProvider } from "../../composables/useAdaptiveMode";
import { provideFlareConfig, type FlareConfigApi, type FlareDensity } from "../../shared/useFlareConfig";
import { provideFlareOverlayContainer, type FlareOverlayTarget } from "../../shared/useOverlayContainer";
import type { FlareControlSize } from "../../shared/contracts";
import type { FlareLayoutMode } from "../../shared/contracts/layout";

const props = withDefaults(
  defineProps<{
    size?: FlareControlSize;
    density?: FlareDensity;
    /** Initial language. */
    locale?: FlareLocale;
    /** Initial theme mode. */
    theme?: FlareThemeMode;
    /** Adaptive layout mode; "auto" tracks viewport width. Drives Select's dropdown-vs-sheet. */
    layoutMode?: FlareLayoutMode;
    /** Teleport target for adaptive sheets; defaults to "body". Scope overlays to a container. */
    overlayContainer?: FlareOverlayTarget;
  }>(),
  { size: "md", density: "default", layoutMode: "auto" },
);

const i18n = useFlareI18nProvider(props.locale);
const themeCtx = useFlareThemeProvider(props.theme);
const adaptiveCtx = useFlareAdaptiveProvider(props.layoutMode);
provideFlareOverlayContainer(() => props.overlayContainer);

const size = ref<FlareControlSize>(props.size);
const density = ref<FlareDensity>(props.density);
// Keep the provided config reactive when the host rebinds these props.
watch(() => props.size, (v) => (size.value = v));
watch(() => props.density, (v) => (density.value = v));
watch(() => props.layoutMode, (v) => adaptiveCtx.setLayoutMode(v));

const api: FlareConfigApi = {
  size,
  setSize: (s) => { size.value = s; },
  density,
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
