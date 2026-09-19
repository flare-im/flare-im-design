<script setup lang="ts">
// One destination of FlareIMAppKit, kept mounted while another is active: hidden, out of the tab order and out
// of the accessibility tree, but laid out, so its scroll positions survive the switch. It counts the pages
// beyond its root that are showing inside it and reports the count to the shell. It is the page's main landmark
// unless a pane frame inside it takes that role for its content pane.
import { ref, watch } from "vue";
import { provideFlareDestination } from "../../composables/useFlareShell";

const props = defineProps<{ active: boolean }>();
const emit = defineEmits<{ (event: "depth", depth: number): void }>();
const depth = ref(0);
const mainClaims = ref(0);
provideFlareDestination(depth, mainClaims);
watch(depth, (value) => emit("depth", value), { immediate: true });
</script>

<template>
  <div
    class="flare-shell-destination"
    :class="{ 'is-active': props.active }"
    :role="mainClaims > 0 ? undefined : 'main'"
    :inert="!props.active || undefined"
  >
    <slot />
  </div>
</template>

<style scoped>
.flare-shell-destination { position: absolute; inset: 0; min-width: 0; min-height: 0; overflow: hidden; }
.flare-shell-destination:not(.is-active) { visibility: hidden; pointer-events: none; }
/* Hidden at once. The reduced-motion rule gives every property a 0.01ms transition, and a transition on the
   inherited visibility would leave the destination just switched away from on screen for a frame. */
.flare-shell-destination:not(.is-active),
.flare-shell-destination:not(.is-active) :deep(*) { transition: none !important; }
</style>
