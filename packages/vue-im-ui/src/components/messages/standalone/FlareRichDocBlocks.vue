<script setup lang="ts">
import type { FlareRichBlock } from "../../../utils/richDoc";
import FlareRichDocRuns from "./FlareRichDocRuns.vue";

/** The blocks of a rich-text body; a quote and a list item draw theirs through this same component. */
defineProps<{ blocks: readonly FlareRichBlock[]; self: boolean }>();
</script>

<template>
  <template v-for="(block, index) in blocks" :key="index">
    <p v-if="block.kind === 'paragraph'" class="fm-rich__paragraph">
      <FlareRichDocRuns :runs="block.runs" :self="self" />
    </p>
    <p v-else-if="block.kind === 'heading'" class="fm-rich__heading" :class="`is-level-${block.level}`">
      <FlareRichDocRuns :runs="block.runs" :self="self" />
    </p>
    <blockquote v-else-if="block.kind === 'quote'" class="fm-rich__quote">
      <FlareRichDocBlocks :blocks="block.blocks" :self="self" />
    </blockquote>
    <pre v-else-if="block.kind === 'code'" class="fm-rich__code-block" :data-language="block.language"><code>{{ block.text }}</code></pre>
    <component :is="block.ordered ? 'ol' : 'ul'" v-else-if="block.kind === 'list'" class="fm-rich__list">
      <li v-for="(item, itemIndex) in block.items" :key="itemIndex" class="fm-rich__item">
        <FlareRichDocBlocks :blocks="item" :self="self" />
      </li>
    </component>
    <hr v-else-if="block.kind === 'divider'" class="fm-rich__divider" />
  </template>
</template>

<style scoped>
.fm-rich__paragraph,
.fm-rich__heading {
  margin: 0;
  white-space: pre-wrap;
}
.fm-rich__paragraph + *,
.fm-rich__heading + *,
.fm-rich__quote + *,
.fm-rich__code-block + *,
.fm-rich__list + *,
.fm-rich__divider + * {
  margin-top: 0.42em;
}
.fm-rich__heading {
  font-weight: 700;
  line-height: 1.28;
}
.fm-rich__heading.is-level-1 { font-size: 1.18em; }
.fm-rich__heading.is-level-2 { font-size: 1.12em; }
.fm-rich__heading.is-level-3,
.fm-rich__heading.is-level-4,
.fm-rich__heading.is-level-5,
.fm-rich__heading.is-level-6 { font-size: 1.04em; }
.fm-rich__quote {
  margin-inline: 0;
  padding: var(--flare-size-spacing-2xs) var(--flare-size-spacing-sm);
  border-left: 3px solid color-mix(in srgb, currentColor 42%, transparent);
  border-radius: var(--flare-size-radius-xs);
  background: color-mix(in srgb, currentColor 8%, transparent);
  color: color-mix(in srgb, currentColor 82%, transparent);
}
.fm-rich__code-block {
  max-width: 100%;
  margin: 0;
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-sm);
  overflow-x: auto;
  border-radius: var(--flare-size-radius-sm);
  background: color-mix(in srgb, currentColor 8%, transparent);
  font-family: var(--flare-component-font-family-mono);
  font-size: 0.92em;
  line-height: 1.45;
  white-space: pre;
}
.fm-rich__list {
  margin: 0;
  padding-inline-start: 1.3em;
}
.fm-rich__item + .fm-rich__item { margin-top: 0.2em; }
.fm-rich__divider {
  height: 0;
  margin-inline: 0;
  border: 0;
  border-top: 1px solid color-mix(in srgb, currentColor 18%, transparent);
}
</style>
