<script setup>
// Shared wrapper for demos that render REAL kit components: renders client-only (the kit's
// naive-ui based components touch `document` during setup, which SSR can't provide) and mounts
// the kit's i18n/theme/media/adaptive providers so the components resolve their context.
import FlareUiProvider from "@flare-im/vue-ui/design-system/provider/FlareUiProvider.vue";
</script>

<template>
  <ClientOnly>
    <FlareUiProvider layout-mode="auto">
      <slot />
    </FlareUiProvider>
  </ClientOnly>
</template>
