<script setup lang="ts">
import { computed } from "vue";

/**
 * Scopes a Flare theme to its subtree by applying design-token overrides as
 * inline CSS variables. Pass an override map (keys are the `--flare-color-`
 * suffix, e.g. `bubble-self`, or full `--flare-*` names). Compose it with
 * `deriveFlareTheme` / `flarePresets` from `@flare-im/tokens/theme`.
 */
const props = defineProps<{ theme?: Record<string, string> }>();

const style = computed<Record<string, string>>(() => {
  const s: Record<string, string> = {};
  if (props.theme) {
    for (const [k, v] of Object.entries(props.theme)) {
      s[k.startsWith("--") ? k : `--flare-color-${k}`] = v;
    }
  }
  return s;
});
</script>

<template>
  <div class="flare-theme-provider" :style="style">
    <slot />
  </div>
</template>

<style scoped>
.flare-theme-provider { display: contents; }
</style>
