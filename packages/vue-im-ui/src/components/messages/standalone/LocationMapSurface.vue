<script setup lang="ts">
import { ref, watch } from "vue";

// The map area of a location card and of the picker: the static map when there is one, otherwise —
// and when the picture fails — a drawn map texture with a centre pin, never an empty box. The static
// map carries its own centre marker (the geo proxy draws it), so the pin is only drawn on the texture.
// `attribution` is the map data's credit (OpenStreetMap's ODbL line): a small line in the bottom-right
// corner of the picture, clear of the centre, and only over the picture — the drawn texture is not map data.
const props = defineProps<{ src?: string; loading?: boolean; attribution?: string }>();
const emit = defineEmits<{ (e: "error"): void }>();

const failed = ref(false);
watch(() => props.src, () => { failed.value = false; });
function onError(): void {
  failed.value = true;
  emit("error");
}
</script>

<template>
  <div class="flare-location-map" :class="{ 'is-loading': loading }">
    <img v-if="src && !failed" class="flare-location-map__image" :src="src" alt="" draggable="false" @error="onError" />
    <small v-if="src && !failed && attribution" class="flare-location-map__attribution" data-map-attribution="true">{{ attribution }}</small>
    <div v-else class="flare-location-map__texture" data-placeholder="true">
      <svg class="flare-location-map__pin" width="28" height="36" viewBox="0 0 28 36" aria-hidden="true">
        <ellipse class="flare-location-map__pin-shadow" cx="14" cy="33.5" rx="5" ry="1.8" />
        <path class="flare-location-map__pin-body" d="M14 32s10-9.1 10-17.2A10 10 0 0 0 4 14.8C4 22.9 14 32 14 32z" />
        <circle class="flare-location-map__pin-dot" cx="14" cy="14.6" r="3.6" />
      </svg>
    </div>
    <slot />
  </div>
</template>

<style scoped>
.flare-location-map {
  position: relative;
  overflow: hidden;
  background: var(--flare-color-bg-tertiary);
}
.flare-location-map__image {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}
/* The data credit: small, in the corner, never over the centre marker. */
.flare-location-map__attribution {
  position: absolute;
  right: 0;
  bottom: 0;
  z-index: 1;
  max-width: 60%;
  padding: 0 var(--flare-size-spacing-xs);
  border-top-left-radius: var(--flare-size-radius-xs);
  overflow: hidden;
  font-size: var(--flare-size-font-size-2xs);
  line-height: var(--flare-size-line-height-snug);
  color: var(--flare-color-text-secondary);
  background: color-mix(in srgb, var(--flare-color-bg-primary) 72%, transparent);
  white-space: nowrap;
  text-overflow: ellipsis;
  pointer-events: none;
}
/* Streets on a light block grid, in the surface colours of the theme. */
.flare-location-map__texture {
  position: absolute;
  inset: 0;
  display: grid;
  place-items: center;
  background-color: var(--flare-color-bg-tertiary);
  background-image:
    linear-gradient(28deg, transparent 47%, var(--flare-color-bg-primary) 47%, var(--flare-color-bg-primary) 53%, transparent 53%),
    linear-gradient(118deg, transparent 63%, var(--flare-color-bg-primary) 63%, var(--flare-color-bg-primary) 66%, transparent 66%),
    linear-gradient(var(--flare-color-border-secondary) 1px, transparent 1px),
    linear-gradient(90deg, var(--flare-color-border-secondary) 1px, transparent 1px);
  background-size: 100% 100%, 100% 100%, 24px 24px, 24px 24px;
  background-position: center;
}
/* The pin's tip (y 32 of 36) sits on the centre of the box. */
.flare-location-map__pin {
  transform: translateY(-14px);
}
.flare-location-map__pin-shadow { fill: color-mix(in srgb, var(--flare-color-text-primary) 18%, transparent); }
.flare-location-map__pin-body { fill: var(--flare-color-primary); stroke: var(--flare-color-bg-primary); stroke-width: 1.5; }
.flare-location-map__pin-dot { fill: var(--flare-color-bg-primary); }
.flare-location-map.is-loading .flare-location-map__texture { animation: flare-location-map-pulse 1.2s ease-in-out infinite; }
@keyframes flare-location-map-pulse {
  50% { opacity: 0.6; }
}
@media (prefers-reduced-motion: reduce) {
  .flare-location-map.is-loading .flare-location-map__texture { animation: none; }
}
</style>
