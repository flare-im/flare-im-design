<script setup lang="ts">
import { computed } from "vue";
// Presentational — linkifies bare URLs and emits `linkClick` with the href so the
// host can open it. `selectable` allows copying.
const props = withDefaults(
  defineProps<{ text?: string; self?: boolean; selectable?: boolean }>(),
  { selectable: false },
);
const emit = defineEmits<{ (e: "linkClick", href: string): void }>();
const html = computed(() =>
  (props.text ?? "")
    .replace(/&/g, "&amp;").replace(/</g, "&lt;")
    .replace(/\b((?:https?:\/\/)?[a-z0-9.-]+\.[a-z]{2,}(?:\/\S*)?)/gi, '<a href="#" data-href="$1">$1</a>'));
function onClick(e: MouseEvent) {
  const a = (e.target as HTMLElement)?.closest("a[data-href]") as HTMLElement | null;
  if (a) {
    e.preventDefault();
    emit("linkClick", a.dataset.href || "");
  }
}
</script>
<template>
  <div class="fm-text" :class="{ 'is-self': self, selectable }" v-html="html" @click="onClick" />
</template>
<style scoped>
.fm-text { display: inline-block; padding: 9px 14px; border-radius: 16px 16px 16px 4px; background: var(--im-bg-surface, #fff); border: 1px solid var(--im-border-subtle, #eef0f4); box-shadow: var(--im-bubble-shadow, 0 2px 10px rgba(0,0,0,.05)); color: var(--im-text-primary, #111318); font-size: 15px; line-height: 1.45; user-select: none; }
.fm-text.selectable { user-select: text; }
.fm-text.is-self { background: var(--im-bubble-sent, #7c3aed); border-color: transparent; color: #fff; border-radius: 16px 16px 4px 16px; }
.fm-text :deep(a) { color: var(--im-bubble-link, #7c3aed); }
.fm-text.is-self :deep(a) { color: #fff; text-decoration: underline; }
</style>
