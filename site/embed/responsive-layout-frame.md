---
layout: false
sidebar: false
aside: false
footer: false
pageClass: composer-embed-page
---

<ClientOnly>
  <FlareUiProvider layout-mode="auto">
    <ResponsiveLayoutFrame />
  </FlareUiProvider>
</ClientOnly>

<style>
html, body, #app { height: 100%; margin: 0; }
.composer-embed-page { height: 100%; }
.composer-embed-page .VPContent,
.composer-embed-page .vp-doc,
.composer-embed-page main { height: 100%; padding: 0 !important; margin: 0 !important; max-width: none !important; }
.composer-embed-page .vp-doc > div { height: 100%; }
</style>

<script setup>
import FlareUiProvider from "flare-core-vue-im-ui/design-system/provider/FlareUiProvider.vue";
</script>
