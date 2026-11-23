<script setup lang="ts">
import { getCurrentInstance } from "vue";
import MomentCommentRow from "./MomentCommentRow.vue";
import type { FlareMomentComment } from "../../shared/contracts";
withDefaults(defineProps<{ comments: FlareMomentComment[]; appearance?: "inline" | "detail"; maxLines?: number; focusCommentId?: string }>(), { appearance: "inline" });
const emit = defineEmits<{ select: [comment: FlareMomentComment]; selectAuthor: [id: string] }>();
const instance = getCurrentInstance();
const canSelect = () => Boolean(instance?.vnode.props?.onSelect);
const canSelectAuthor = () => Boolean(instance?.vnode.props?.onSelectAuthor);
</script>
<template>
 <ul v-if="comments.length" class="flare-comment-thread" :class="`flare-comment-thread--${appearance}`">
  <MomentCommentRow v-for="comment in comments" :key="comment.id" :comment="comment" :appearance="appearance" :max-lines="maxLines ?? (appearance === 'detail' ? 5 : 3)" :focused="comment.id === focusCommentId" :selectable="canSelect()" :author-selectable="canSelectAuthor()" @select="emit('select', $event)" @select-author="emit('selectAuthor', $event)" />
 </ul>
</template>
<style scoped>
.flare-comment-thread { list-style: none; margin: 0; padding: 0; min-width: 0; }
</style>
