<script setup lang="ts">
/** Borderless groups for detail panes and editors. Collapsing never unmounts a draft. */
import { useId } from "vue";
withDefaults(defineProps<{
  title: string;
  description?: string;
  collapsible?: boolean;
}>(), { collapsible: false });
const open = defineModel<boolean>("open", { default: false });
const headingId = useId();
function toggled(event: Event) {
  if (event.target === event.currentTarget && event.target instanceof HTMLDetailsElement)
    open.value = event.target.open;
}
</script>

<template>
  <component
    :is="collapsible ? 'details' : 'section'"
    class="flare-admin-section"
    :class="{ 'flare-admin-section--collapsible': collapsible }"
    :aria-labelledby="headingId"
    :open="collapsible ? open : undefined"
    @toggle="toggled"
  >
    <component :is="collapsible ? 'summary' : 'header'" class="flare-admin-section__header">
      <h3 :id="headingId" class="flare-admin-section__title">{{ title }}</h3>
    </component>
    <div class="flare-admin-section__body">
      <p v-if="description" class="flare-admin-section__description">{{ description }}</p>
      <slot />
    </div>
  </component>
</template>

<style scoped>
.flare-admin-section { min-width: 0; }
.flare-admin-section__header { margin-block-end: var(--flare-size-spacing-md); }
.flare-admin-section__title {
  display: inline;
  margin: 0;
  font-size: var(--flare-size-font-size-md);
  font-weight: var(--flare-size-font-weight-semibold);
  color: var(--flare-color-text-primary);
}
.flare-admin-section__body { min-width: 0; }
.flare-admin-section__description {
  margin: 0 0 var(--flare-size-spacing-md);
  font-size: var(--flare-text-caption-font-size);
  line-height: var(--flare-size-line-height-relaxed);
  color: var(--flare-color-text-secondary);
  overflow-wrap: anywhere;
}
.flare-admin-section--collapsible > summary {
  cursor: pointer;
  padding-block: var(--flare-size-spacing-sm);
  margin-block-end: 0;
  color: var(--flare-color-text-secondary);
}
.flare-admin-section--collapsible[open] > summary { margin-block-end: var(--flare-size-spacing-sm); }
.flare-admin-section--collapsible > summary:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: 2px;
  border-radius: var(--flare-size-radius-sm);
}
</style>
