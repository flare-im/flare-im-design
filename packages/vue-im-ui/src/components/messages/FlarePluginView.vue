<script setup lang="ts">
import type { FlarePluginViewModel } from "../../shared/contracts/plugin-ui";
import FlareButton from "../general/FlareButton.vue";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";
withDefaults(defineProps<{ view: FlarePluginViewModel; busy?: boolean; error?: string }>(), { busy: false });
const emit = defineEmits<{ action: [id: string] }>();
</script>
<template>
  <section class="flare-plugin-view" :aria-busy="busy">
    <strong class="flare-plugin-view__title">{{ view.title }}</strong>
    <template v-if="view.available">
      <dl v-if="view.fields.length" class="flare-plugin-view__fields">
        <div v-for="(field, index) in view.fields" :key="index"><dt>{{ field.label }}</dt><dd>{{ field.value }}</dd></div>
      </dl>
      <div v-if="view.actions.length" class="flare-plugin-view__actions">
        <FlareButton v-for="action in view.actions" :key="action.id" :label="action.label" variant="secondary" :disabled="busy" @click="emit('action', action.id)" />
      </div>
    </template>
    <FlareStatusBanner v-if="error" :text="error" tone="danger" />
  </section>
</template>
<style scoped>
.flare-plugin-view { display: grid; gap: var(--flare-size-spacing-md); max-width: 100%; min-width: 0; color: var(--flare-color-text-primary); overflow-wrap: anywhere; }
.flare-plugin-view__title { font-size: var(--flare-size-font-size-lg); }
.flare-plugin-view__fields { display: grid; gap: var(--flare-size-spacing-sm); margin: 0; }
.flare-plugin-view__fields > div { display: grid; grid-template-columns: minmax(4em, 1fr) minmax(0, 2fr); gap: var(--flare-size-spacing-md); }
dt { color: var(--flare-color-text-secondary); } dd { margin: 0; }
.flare-plugin-view__actions { display: flex; flex-wrap: wrap; gap: var(--flare-size-spacing-md); }
</style>
