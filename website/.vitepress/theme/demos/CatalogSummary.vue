<script setup>
import catalog from "../../../../spec/component-catalog.json";
import spec from "../../../../spec/components.json";
</script>

<template>
  <div class="catalog-summary" aria-label="Flare UI catalog summary">
    <span><strong>{{ catalog.counts.total }}</strong> public contracts</span>
    <span><strong>{{ spec.categories.length }}</strong> categories</span>
    <span><strong>4</strong> native platforms</span>
    <span><strong>1</strong> token source</span>
  </div>
</template>

<style scoped>
.catalog-summary { display: flex; flex-wrap: wrap; gap: 8px 28px; margin: 0 0 40px; padding: 14px 0; border-block: 1px solid var(--vp-c-divider); color: var(--vp-c-text-2); font-size: 13px; }
.catalog-summary strong { color: var(--vp-c-text-1); font-size: 16px; font-variant-numeric: tabular-nums; }
</style>
