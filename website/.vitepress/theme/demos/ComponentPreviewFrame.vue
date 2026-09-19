<script setup>
import { onBeforeUnmount, onMounted } from "vue";
import { useData } from "vitepress";
import ComponentPreview from "./ComponentPreview.vue";
import catalog from "../../../../spec/component-catalog.json";
const { isDark } = useData();
const query = new URLSearchParams(typeof location === "undefined" ? "" : location.search);
const name = query.get("name");
const entry = catalog.components.find((item) => item.name === name);
const viewport = entry?.previewViewports.includes(query.get("viewport")) ? query.get("viewport") : "desktop";
function receiveTheme(event) {
  if (event.origin !== location.origin || event.source !== parent || event.data?.type !== "flare-preview-theme") return;
  isDark.value = event.data.dark === true;
  const scale = Number(event.data.contentScale);
  const height = Number(event.data.contentHeight);
  if (scale > 0 && scale <= 1 && height >= 300 && height <= 2000) {
    // Preserve readable control sizes while keeping real desktop media queries.
    document.documentElement.style.zoom = String(1 / scale);
    document.documentElement.style.setProperty("--component-preview-height", `${height}px`);
  }
}
onMounted(() => {
  window.addEventListener("message", receiveTheme);
  parent.postMessage({ type: "flare-preview-ready" }, location.origin);
});
onBeforeUnmount(() => {
  window.removeEventListener("message", receiveTheme);
  document.documentElement.style.removeProperty("zoom");
  document.documentElement.style.removeProperty("--component-preview-height");
});
</script>
<template>
  <ComponentPreview v-if="entry" :name="entry.name" :initial-viewport="viewport" embedded />
  <p v-else role="alert">Unknown component preview</p>
</template>
