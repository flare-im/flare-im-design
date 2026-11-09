<script setup lang="ts">
/**
 * Lays real form items out in up to `columns` equal columns. Columns drop to one as the
 * container narrows below `minColumnWidth` each, so a wide modal and a phone share one draft.
 * A child marked `data-flare-span="full"` takes the whole row (long text, notes, hints).
 * Pure layout: no labels, validation or values of its own.
 */
import { computed } from "vue";

const props = withDefaults(
  defineProps<{
    columns?: 1 | 2 | 3;
    minColumnWidth?: string;
  }>(),
  { columns: 2, minColumnWidth: "240px" },
);
const style = computed(() => ({
  "--flare-admin-form-grid-columns": String(props.columns),
  "--flare-admin-form-grid-min": props.minColumnWidth,
}));
</script>

<template>
  <div class="flare-admin-form-grid" :style="style">
    <slot />
  </div>
</template>

<style scoped>
.flare-admin-form-grid {
  --flare-admin-form-grid-gap: var(--flare-size-spacing-md);
  display: grid;
  /* At most N columns, each at least the minimum, never wider than the container. */
  grid-template-columns: repeat(
    auto-fill,
    minmax(
      min(
        100%,
        max(
          var(--flare-admin-form-grid-min),
          calc(
            (100% - (var(--flare-admin-form-grid-columns) - 1) *
                  var(--flare-admin-form-grid-gap)) /
              var(--flare-admin-form-grid-columns)
          )
        )
      ),
      1fr
    )
  );
  column-gap: var(--flare-admin-form-grid-gap);
  /* Items without feedback still keep a breathing line between rows. */
  row-gap: var(--flare-size-spacing-sm);
  align-items: start;
  min-width: 0;
  width: 100%;
}
.flare-admin-form-grid > :deep(*) {
  min-width: 0;
}
.flare-admin-form-grid > :deep([data-flare-span="full"]) {
  grid-column: 1 / -1;
}
</style>
