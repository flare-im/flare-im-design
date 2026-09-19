<script setup lang="ts">
import { onBeforeUnmount, ref, watch } from "vue";
import { darkTheme, NConfigProvider, NDialogProvider, NMessageProvider } from "naive-ui";
import type { FlareLayoutMode } from "../../shared/contracts/layout";
import { useFlareThemeProvider, type FlareThemeMode } from "../theme/use-flare-theme";
import type { FlareBrandTheme } from "../theme/im-theme";
import { useFlareI18nProvider, type FlareLocale } from "../../shared/i18n/useFlareI18n";
import { useFlareAdaptiveProvider } from "../../composables/useAdaptiveMode";
import { useViewportProvider } from "../../composables/useViewport";
import { useFlareMediaProvider } from "../../composables/useMediaResolver";
import type { FlareMediaResolver } from "../../shared/contracts/media";
import { useFlarePlatformProvider, type FlarePlatformOptions } from "../../shared/platform/useFlarePlatform";
import { provideFlareConfig, type FlareConfigApi } from "../../shared/useFlareConfig";
import { provideFlareOverlayContainer, type FlareOverlayTarget } from "../../shared/useOverlayContainer";
import type { FlareControlSize } from "../../shared/contracts";
import { provideFlareFeedback } from "../../composables/useFlareFeedback";
import FlareDangerConfirm from "../../components/scenes/FlareDangerConfirm.vue";
import FlareToast from "../../components/general/FlareToast.vue";
import { setFlareAssetBaseUrl } from "../../shared/assets";

const props = withDefaults(
  defineProps<{
    themeMode?: FlareThemeMode;
    brandTheme?: FlareBrandTheme;
    locale?: FlareLocale;
    layoutMode?: FlareLayoutMode;
    mediaResolver?: FlareMediaResolver;
    /** Platform contract of the host (kind / adapter / capability overrides); defaults to the web adapter. */
    platform?: FlarePlatformOptions;
    /** Default size for sized controls (Button / IconButton / Select …); read through useFlareConfig(). */
    size?: FlareControlSize;
    /** Teleport target for adaptive sheets; defaults to "body". Scope overlays to a container. */
    overlayContainer?: FlareOverlayTarget;
    /** Base URL of the emoji and sticker resources; defaults to "/flare-im-ui-assets". Set it for sub-path or CDN deploys. */
    assetBaseUrl?: string;
  }>(),
  {
    themeMode: undefined,
    locale: undefined,
    layoutMode: "auto",
    mediaResolver: undefined,
    platform: undefined,
    size: "md",
    overlayContainer: undefined,
    assetBaseUrl: undefined,
  },
);

const theme = useFlareThemeProvider(props.themeMode, undefined, props.brandTheme);
const { isDark, naiveThemeOverrides } = theme;
const i18n = useFlareI18nProvider(props.locale);
const { naiveLocale, naiveDateLocale } = i18n;
const adaptive = useFlareAdaptiveProvider(props.layoutMode);
watch(() => props.layoutMode, (layoutMode) => adaptive.setLayoutMode(layoutMode));
watch(() => props.themeMode, (mode) => { if (mode) theme.setMode(mode); });
// A host that binds its own language to `locale` switches every kit string when it changes; without
// this the provider kept the language it was created with and only `setLocale` could move it.
watch(() => props.locale, (locale) => { if (locale) i18n.setLocale(locale); });
watch(() => props.brandTheme, (brand) => { if (brand) theme.setBrand(brand); });
useViewportProvider();
useFlareMediaProvider(props.mediaResolver);
useFlarePlatformProvider({ ...props.platform, adaptive });
provideFlareOverlayContainer(() => props.overlayContainer);
setFlareAssetBaseUrl(props.assetBaseUrl);
watch(() => props.assetBaseUrl, (url) => setFlareAssetBaseUrl(url));

// The one root config surface: size defaults plus live language and
// theme switching for every descendant (useFlareConfig()).
const size = ref<FlareControlSize>(props.size);
watch(() => props.size, (value) => (size.value = value));
const config: FlareConfigApi = {
  size,
  setSize: (value) => { size.value = value; },
  locale: i18n.locale,
  setLocale: i18n.setLocale,
  themeMode: theme.mode,
  isDark,
  setThemeMode: theme.setMode,
  toggleTheme: () => theme.setMode(isDark.value ? "light" : "dark"),
};
provideFlareConfig(config);

// Confirmations and toasts are presented here, once, for every descendant
// (useFlareConfirm / useFlareToast), so hosts never build their own overlay or timers.
const feedback = provideFlareFeedback();
const { confirmRequest, toasts } = feedback;
onBeforeUnmount(() => feedback.dispose());
</script>

<template>
  <n-config-provider :theme="isDark ? darkTheme : null" :locale="naiveLocale" :date-locale="naiveDateLocale" :theme-overrides="naiveThemeOverrides">
    <n-message-provider>
      <n-dialog-provider>
        <slot />
        <FlareDangerConfirm
          v-if="confirmRequest"
          open
          :title="confirmRequest.options.title"
          :description="confirmRequest.options.description"
          :target="confirmRequest.options.target ?? ''"
          :confirm-text="confirmRequest.options.confirmText"
          :cancel-text="confirmRequest.options.cancelText"
          :busy="confirmRequest.busy"
          :error="confirmRequest.error || undefined"
          @confirm="feedback.accept"
          @cancel="feedback.cancel"
        />
        <div v-if="toasts.length" class="flare-ui-provider__toasts">
          <FlareToast
            v-for="entry in toasts"
            :key="entry.id"
            :message="entry.message"
            :tone="entry.tone"
            :action-label="entry.actionLabel"
            @action="feedback.runToastAction(entry.id)"
          />
        </div>
      </n-dialog-provider>
    </n-message-provider>
  </n-config-provider>
</template>

<style scoped>
.flare-ui-provider__toasts {
  position: fixed;
  z-index: var(--flare-z-index-toast);
  top: calc(env(safe-area-inset-top) + var(--flare-size-spacing-lg));
  left: 50%;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  width: max-content;
  max-width: calc(100vw - 2 * var(--flare-size-spacing-lg));
  transform: translateX(-50%);
  pointer-events: none;
}
.flare-ui-provider__toasts > * {
  pointer-events: auto;
}
</style>
