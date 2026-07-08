<script setup>
// A text message body — linkifies bare URLs. Standalone, composable.
const props = defineProps({ text: { type: String, default: "" }, self: Boolean });
const html = () =>
  props.text
    .replace(/&/g, "&amp;").replace(/</g, "&lt;")
    .replace(/\b((?:https?:\/\/)?[a-z0-9.-]+\.[a-z]{2,}(?:\/\S*)?)/gi, '<a href="#">$1</a>');
</script>
<template>
  <div class="bubble" :class="{ self }" v-html="html()" />
</template>
<style scoped>
.bubble { display: inline-block; padding: 9px 14px; border-radius: 16px 16px 16px 4px; background: var(--flare-color-bg-primary); border: 1px solid var(--flare-color-border-secondary); box-shadow: 0 2px 10px rgba(0,0,0,.05); color: var(--flare-color-text-primary); font-size: 15px; line-height: 1.45; }
.bubble.self { background: var(--flare-color-bubble-self); border-color: transparent; color: #fff; border-radius: 16px 16px 4px 16px; }
.bubble :deep(a) { color: var(--flare-color-link); }
.bubble.self :deep(a) { color: #fff; text-decoration: underline; }
</style>
