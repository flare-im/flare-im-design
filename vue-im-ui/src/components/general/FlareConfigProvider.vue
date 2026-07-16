<script setup lang="ts">
// Root-level config provider — sets app-wide defaults (control size, density)
// that sized components inherit unless overridden per-instance.
import { provideFlareConfig } from "../../shared/useFlareConfig";
import type { FlareDensity } from "../../shared/useFlareConfig";
import type { FlareControlSize } from "../../shared/contracts";

const props = withDefaults(
  defineProps<{ size?: FlareControlSize; density?: FlareDensity }>(),
  { size: "md", density: "default" },
);
provideFlareConfig({ size: props.size, density: props.density });
</script>

<template>
  <slot />
</template>
