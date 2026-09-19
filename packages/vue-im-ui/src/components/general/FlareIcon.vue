<script setup lang="ts">
import { computed } from "vue";
import { NIcon } from "naive-ui";
import { flareIcons, type FlareIconName } from "../../shared/icons";

const props = withDefaults(
  defineProps<{
    /** A canonical Flare icon name (see the gallery). */
    name: FlareIconName;
    size?: number;
    /**
     * The icon's own accessible name. Leave it unset for the common case — an
     * icon inside an already-labelled control — and the icon is hidden from
     * assistive technology instead of being announced as an unnamed image.
     */
    ariaLabel?: string;
  }>(),
  { size: 20, ariaLabel: undefined },
);
const glyph = computed(() => flareIcons[props.name]);
const decorative = computed(() => !props.ariaLabel);
</script>

<template>
  <!-- A stable class so hosts style the icon without reaching for the icon runtime's own class name. -->
  <n-icon
    class="flare-icon"
    :size="size"
    :component="glyph"
    :aria-hidden="decorative ? 'true' : undefined"
    :aria-label="ariaLabel"
  />
</template>
