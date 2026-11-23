<script setup lang="ts">
// A round key in a call's top bar (§3.1: minimize, expand / collapse): a touch-target disc on the stage's control fill
// with a 24 icon; controlHover under a hovering pointer and while pressed.
import type { Component } from "vue";
import { NIcon } from "naive-ui";

defineProps<{ icon: Component; label: string }>();
</script>

<template>
  <button type="button" class="flare-call-bar-key" :aria-label="label" :title="label">
    <n-icon aria-hidden="true" size="var(--flare-size-icon-size-lg)" :component="icon" />
  </button>
</template>

<style scoped>
.flare-call-bar-key {
  display: grid;
  place-items: center;
  flex: none;
  width: var(--flare-size-layout-touch-target);
  height: var(--flare-size-layout-touch-target);
  padding: 0;
  border: 0;
  border-radius: var(--flare-size-radius-full);
  color: var(--flare-color-call-on-stage);
  background: var(--flare-color-call-control);
  cursor: pointer;
  transition: background var(--flare-transition-fast);
}
@media (hover: hover) {
  .flare-call-bar-key:hover { background: var(--flare-color-call-control-hover); }
}
.flare-call-bar-key:active { background: var(--flare-color-call-control-hover); }
.flare-call-bar-key:focus-visible {
  outline: var(--flare-size-component-focus-ring-width) solid var(--flare-color-border-selected);
  outline-offset: var(--flare-size-component-focus-ring-offset);
}
</style>
