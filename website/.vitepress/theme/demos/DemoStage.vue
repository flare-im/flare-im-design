<script setup>
// Shared wrapper for demos that render REAL kit components: renders client-only (the kit's
// naive-ui based components touch `document` during setup, which SSR can't provide) and mounts
// the kit's i18n/theme/media/adaptive providers so the components resolve their context.
import { computed, inject } from "vue";
import { useData, useRoute } from "vitepress";
import { FlareUiProvider } from "@flare-im/vue-ui/components";
import { previewContextKey } from "./preview-context";

const preview = inject(previewContextKey, null);
const route = useRoute();
const { isDark } = useData();
const locale = computed(() => (route.path.startsWith("/en") ? "en-US" : "zh-CN"));
const layoutMode = computed(() => {
  if (!preview) return "auto";
  if (preview.viewport.value === "mobile") return "h5";
  if (preview.viewport.value === "tablet") return "ipad";
  return "pc";
});
</script>

<template>
  <ClientOnly>
    <FlareUiProvider :layout-mode="layoutMode" :locale="locale" :theme-mode="isDark ? 'dark' : 'light'">
      <slot />
    </FlareUiProvider>
  </ClientOnly>
</template>
