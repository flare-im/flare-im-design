<script setup lang="ts">
/** Presentation only. Hosts retain permission checks, busy state and confirmation ownership. */
import { NConfigProvider, type GlobalThemeOverrides } from "naive-ui";
withDefaults(defineProps<{ label?: string; justify?: "start" | "end" }>(), {
  justify: "start",
});
// Native text buttons use the Kit's accessible semantic text roles, not Naive's
// bright filled-warning swatch. Inherits live light/dark tokens without owning a theme.
const actionTheme: GlobalThemeOverrides = {
  Button: {
    textColorTextWarning: "var(--flare-color-warning-text)",
    textColorTextHoverWarning: "var(--flare-color-warning-text)",
    textColorTextPressedWarning: "var(--flare-color-warning-text)",
    textColorTextFocusWarning: "var(--flare-color-warning-text)",
    textColorTextError: "var(--flare-color-error-text)",
    textColorTextHoverError: "var(--flare-color-error-text)",
    textColorTextPressedError: "var(--flare-color-error-text)",
    textColorTextFocusError: "var(--flare-color-error-text)",
  },
};
</script>

<template>
  <div
    class="flare-admin-actions"
    :class="{ 'flare-admin-actions--end': justify === 'end' }"
    :role="label ? 'group' : undefined"
    :aria-label="label"
  >
    <NConfigProvider abstract :theme-overrides="actionTheme"
      ><slot
    /></NConfigProvider>
  </div>
</template>

<style scoped>
.flare-admin-actions {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  column-gap: var(--flare-size-spacing-sm);
  row-gap: var(--flare-size-spacing-xs);
  min-width: 0;
}
.flare-admin-actions :deep(.n-button) {
  flex-shrink: 0;
  min-height: var(--flare-size-layout-control-height-sm);
}
.flare-admin-actions--end {
  justify-content: flex-end;
}
</style>
