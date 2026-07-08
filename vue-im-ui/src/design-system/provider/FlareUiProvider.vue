<script setup lang="ts">
import { NConfigProvider, NDialogProvider, NMessageProvider } from "naive-ui";
import type { FlareLayoutMode } from "../../shared/contracts/layout";
import { useFlareThemeProvider, type FlareThemeMode } from "../theme/use-flare-theme";
import { useFlareI18nProvider, type FlareLocale } from "../../shared/i18n/useFlareI18n";
import { useFlareAdaptiveProvider } from "../../composables/useAdaptiveMode";
import { useViewportProvider } from "../../composables/useViewport";
import { useFlareMediaProvider } from "../../composables/useMediaResolver";
import type { FlareMediaResolver } from "../../shared/contracts/media";

const props = withDefaults(
  defineProps<{
    themeMode?: FlareThemeMode;
    locale?: FlareLocale;
    layoutMode?: FlareLayoutMode;
    mediaResolver?: FlareMediaResolver;
  }>(),
  {
    themeMode: undefined,
    locale: undefined,
    layoutMode: "auto",
    mediaResolver: undefined,
  },
);

const { naiveThemeOverrides } = useFlareThemeProvider(props.themeMode);
const { naiveLocale, naiveDateLocale } = useFlareI18nProvider(props.locale);
useFlareAdaptiveProvider(props.layoutMode);
useViewportProvider();
useFlareMediaProvider(props.mediaResolver);
</script>

<template>
  <n-config-provider :locale="naiveLocale" :date-locale="naiveDateLocale" :theme-overrides="naiveThemeOverrides">
    <n-message-provider>
      <n-dialog-provider>
        <slot />
      </n-dialog-provider>
    </n-message-provider>
  </n-config-provider>
</template>
