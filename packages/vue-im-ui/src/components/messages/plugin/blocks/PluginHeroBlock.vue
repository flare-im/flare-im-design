<script setup lang="ts">
import FlareButton from "../../../general/FlareButton.vue";
import {
  flarePluginHeroTone,
  type FlarePluginAction,
  type FlarePluginHeroBlock,
} from "../../../../shared/contracts/plugin-ui";

// A page's lead figure (vocabulary 2; with stats, sections and rows it replaces the account renderer's head): the
// label, the value PluginView already formatted, a subtitle, and up to three actions the block owns, run through the
// same pipeline as the view's actions. The tone tints the surface: neutral, positive, warning or the brand.
const props = defineProps<{ block: FlarePluginHeroBlock; busy?: boolean; busyActionId?: string }>();
const emit = defineEmits<{ action: [action: FlarePluginAction] }>();
const variantOf = (action: FlarePluginAction, index: number) =>
  action.style === "danger" ? "danger" : action.style === "primary" || index === 0 ? "primary" : "secondary";
function run(action: FlarePluginAction): void {
  if (!props.busy) emit("action", action);
}
</script>

<template>
  <section class="flare-plugin-hero" :class="`is-${flarePluginHeroTone(block.tone)}`" :data-hero-tone="flarePluginHeroTone(block.tone)">
    <p v-if="block.label" class="flare-plugin-hero__label">{{ block.label }}</p>
    <p class="flare-plugin-hero__value" :class="{ 'is-amount': block.amount }" data-hero-value="true">{{ block.value }}</p>
    <p v-if="block.subtitle" class="flare-plugin-hero__subtitle">{{ block.subtitle }}</p>
    <div v-if="block.actions?.length" class="flare-plugin-hero__actions">
      <FlareButton
        v-for="(action, index) in block.actions"
        :key="action.id"
        :label="action.label"
        :variant="variantOf(action, index)"
        size="sm"
        :loading="busyActionId === action.id"
        :disabled="busy"
        :data-action-id="action.id"
        @click="run(action)"
      />
    </div>
  </section>
</template>

<style scoped>
.flare-plugin-hero {
  display: grid;
  gap: var(--flare-size-spacing-xs);
  min-width: 0;
  padding: var(--flare-size-spacing-lg);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-plugin-hero-surface);
  color: var(--flare-color-text-primary);
}
.flare-plugin-hero.is-neutral { --flare-plugin-hero-surface: var(--flare-color-bg-secondary); --flare-plugin-hero-ink: var(--flare-color-text-primary); }
.flare-plugin-hero.is-positive { --flare-plugin-hero-surface: color-mix(in srgb, var(--flare-color-success) 8%, var(--flare-color-bg-primary)); --flare-plugin-hero-ink: var(--flare-color-success-text); }
.flare-plugin-hero.is-warning { --flare-plugin-hero-surface: color-mix(in srgb, var(--flare-color-warning) 8%, var(--flare-color-bg-primary)); --flare-plugin-hero-ink: var(--flare-color-warning-text); }
.flare-plugin-hero.is-brand { --flare-plugin-hero-surface: color-mix(in srgb, var(--flare-color-primary) 8%, var(--flare-color-bg-primary)); --flare-plugin-hero-ink: var(--flare-color-primary-text); }
.flare-plugin-hero p { margin: 0; overflow-wrap: anywhere; }
.flare-plugin-hero__label { font-size: var(--flare-size-font-size-md); color: var(--flare-color-text-secondary); }
.flare-plugin-hero__value {
  font-size: var(--flare-size-font-size-5xl);
  font-weight: var(--flare-size-font-weight-semibold);
  line-height: var(--flare-size-line-height-tight);
  font-variant-numeric: tabular-nums;
  color: var(--flare-plugin-hero-ink);
}
.flare-plugin-hero__subtitle { font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-secondary); }
.flare-plugin-hero__actions { display: flex; flex-wrap: wrap; gap: var(--flare-size-spacing-sm); padding-top: var(--flare-size-spacing-xs); }
@media (forced-colors: active) {
  .flare-plugin-hero { border: 1px solid CanvasText; }
}
</style>
