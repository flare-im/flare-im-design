<script setup lang="ts">
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareMomentComment } from "../../shared/contracts";

defineProps<{ comments: FlareMomentComment[] }>();
const emit = defineEmits<{
  (e: "select", comment: FlareMomentComment): void;
  (e: "selectAuthor", id: string): void;
}>();

const { t } = useFlareI18n();
</script>

<template>
  <ul v-if="comments.length" class="flare-comment-thread">
    <li v-for="c in comments" :key="c.id" class="flare-comment" @click="emit('select', c)">
      <span class="flare-comment__name" @click.stop="emit('selectAuthor', c.author.id)">{{ c.author.name }}</span>
      <template v-if="c.replyToName">
        <span class="flare-comment__reply"> {{ t("moment.replyTo") }} </span>
        <span class="flare-comment__name">{{ c.replyToName }}</span>
      </template>
      <span class="flare-comment__sep">：</span>
      <span class="flare-comment__text">{{ c.text }}</span>
    </li>
  </ul>
</template>

<style scoped>
.flare-comment-thread {
  list-style: none;
  margin: 0;
  padding: 0;
}
.flare-comment {
  padding: 3px 0;
  font-size: 13px;
  line-height: 1.5;
  color: var(--flare-color-text-primary, #15131c);
  cursor: pointer;
  word-break: break-word;
}
.flare-comment:hover { background: color-mix(in srgb, var(--flare-color-primary, #7c3aed) 5%, transparent); }
.flare-comment__name {
  color: var(--flare-color-primary, #7c3aed);
  font-weight: 500;
}
.flare-comment__reply { color: var(--flare-color-text-tertiary, #a7a2b4); }
.flare-comment__sep { color: var(--flare-color-text-tertiary, #a7a2b4); }
.flare-comment__text { color: var(--flare-color-text-primary, #15131c); }
</style>
