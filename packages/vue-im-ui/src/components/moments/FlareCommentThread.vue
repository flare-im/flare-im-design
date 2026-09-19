<script setup lang="ts">
import { getCurrentInstance } from "vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareMomentComment } from "../../shared/contracts";

defineProps<{ comments: FlareMomentComment[] }>();
const emit = defineEmits<{
  (e: "select", comment: FlareMomentComment): void;
  (e: "selectAuthor", id: string): void;
}>();

const { t } = useFlareI18n();
const instance = getCurrentInstance();
// A comment is a button only when the host replies to it; its author name opens the author only when
// the host handles that, as a pointer shortcut inside the row (a button cannot hold another button).
const canSelect = (): boolean => Boolean(instance?.vnode.props?.onSelect);
const canSelectAuthor = (): boolean => Boolean(instance?.vnode.props?.onSelectAuthor);

function onRowClick(event: MouseEvent, comment: FlareMomentComment): void {
  if (canSelectAuthor() && (event.target as HTMLElement | null)?.closest(".flare-comment__name--author")) {
    emit("selectAuthor", comment.author.id);
    return;
  }
  emit("select", comment);
}
</script>

<template>
  <ul v-if="comments.length" class="flare-comment-thread">
    <li v-for="c in comments" :key="c.id" class="flare-comment">
      <component
        :is="canSelect() ? 'button' : 'div'"
        :type="canSelect() ? 'button' : undefined"
        class="flare-comment__row"
        :class="{ 'is-interactive': canSelect() }"
        :aria-label="canSelect() ? t('moment.replyToComment', { name: c.author.name, text: c.text }) : undefined"
        @click="canSelect() && onRowClick($event, c)"
      >
        <span class="flare-comment__name flare-comment__name--author" :class="{ 'is-interactive': canSelect() && canSelectAuthor() }">{{ c.author.name }}</span>
        <template v-if="c.replyToName">
          <span class="flare-comment__reply"> {{ t("moment.replyTo") }} </span>
          <span class="flare-comment__name">{{ c.replyToName }}</span>
        </template>
        <span class="flare-comment__sep">：</span>
        <span class="flare-comment__text">{{ c.text }}</span>
      </component>
    </li>
  </ul>
</template>

<style scoped>
.flare-comment-thread {
  list-style: none;
  margin: 0;
  padding: 0;
}
.flare-comment__row {
  display: block;
  width: 100%;
  padding: 3px 0;
  border: 0;
  background: none;
  font: inherit;
  font-size: 13px;
  line-height: 1.5;
  text-align: start;
  color: var(--flare-color-text-primary);
  word-break: break-word;
}
.flare-comment__row.is-interactive { cursor: pointer; }
.flare-comment__row.is-interactive:hover { background: color-mix(in srgb, var(--flare-color-primary) 5%, transparent); }
.flare-comment__row:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 1px; }
.flare-comment__name {
  color: var(--flare-color-primary-text);
  font-weight: 500;
}
.flare-comment__name.is-interactive:hover { text-decoration: underline; }
.flare-comment__reply { color: var(--flare-color-text-tertiary); }
.flare-comment__sep { color: var(--flare-color-text-tertiary); }
.flare-comment__text { color: var(--flare-color-text-primary); }
</style>
