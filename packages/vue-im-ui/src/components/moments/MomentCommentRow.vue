<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref, useId, watch } from "vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareMomentComment } from "../../shared/contracts";
const props = defineProps<{ comment: FlareMomentComment; appearance: "inline" | "detail"; maxLines: number; selectable: boolean; authorSelectable: boolean; focused?: boolean }>();
const emit = defineEmits<{ select: [comment: FlareMomentComment]; selectAuthor: [id: string] }>();
const { t } = useFlareI18n();
const contentId = `flare-comment-${useId()}`;
const content = ref<HTMLElement>();
const body = ref<HTMLElement>();
const root = ref<HTMLElement>();
const expanded = ref(false);
const measured = ref(false);
const limit = computed(() => Math.max(0, Math.floor(props.maxLines)));
const overflows = computed(() => limit.value > 0 && (measured.value || props.comment.text.split("\n").length > limit.value));
const clamp = computed(() => limit.value > 0 && !expanded.value ? { '-webkit-line-clamp': String(limit.value) } : undefined);
let observer: ResizeObserver | undefined;
function measure() {
 const node = props.appearance === "detail" ? body.value : content.value;
 if (node && !expanded.value) measured.value = node.scrollHeight > node.clientHeight + 1;
}
function observe() {
 observer?.disconnect();
 const node = props.appearance === "detail" ? body.value : content.value;
 if (node && typeof ResizeObserver !== "undefined") { observer = new ResizeObserver(measure); observer.observe(node); }
 measure();
}
onMounted(observe);
onBeforeUnmount(() => observer?.disconnect());
watch([() => props.comment.text, () => props.appearance, () => props.maxLines], () => { expanded.value = Boolean(props.focused); measured.value = false; void nextTick(observe); });
watch(() => props.focused, async focused => {
 if (!focused) return;
 expanded.value = true;
 await nextTick();
 const node = root.value;
 if (!node?.isConnected || !props.focused) return;
 // Only the nearest scrolling surface moves. scrollIntoView could also move the inbox behind a modal.
 for (let parent = node.parentElement; parent; parent = parent?.parentElement ?? null) {
  if (!/(auto|scroll)/.test(getComputedStyle(parent).overflowY)) continue;
  const row = node.getBoundingClientRect(), bounds = parent.getBoundingClientRect();
  const gutter = Math.min(8, parent.clientHeight / 4);
  const inset = Math.max(gutter, (parent.clientHeight - row.height) / 2);
  parent.scrollTop = Math.max(0, parent.scrollTop + row.top - bounds.top - parent.clientTop - inset);
  break;
 }
 node.focus({ preventScroll: true });
}, { immediate: true, flush: "post" });
function toggle() { expanded.value = !expanded.value; if (!expanded.value) void nextTick(measure); }
function onRowClick(event: MouseEvent) {
 if (!props.selectable) return;
 if (props.authorSelectable && (event.target as HTMLElement | null)?.closest(".flare-comment__name--author")) emit("selectAuthor", props.comment.author.id);
 else emit("select", props.comment);
}
</script>
<template>
 <li ref="root" class="flare-comment" :class="{ 'flare-comment--detail': appearance === 'detail', 'is-targeted': focused }" :data-comment-id="comment.id" :aria-current="focused ? 'true' : undefined" :tabindex="focused ? -1 : undefined">
  <span v-if="focused" class="flare-comment__located">{{ t('moment.locatedComment') }}</span>
  <component :is="selectable ? 'button' : 'div'" :type="selectable ? 'button' : undefined" class="flare-comment__row" :class="{ 'is-interactive': selectable }" :aria-label="selectable ? t('moment.replyToComment', { name: comment.author.name, text: comment.text }) : undefined" @click="onRowClick">
   <span ref="content" :id="appearance === 'inline' ? contentId : undefined" class="flare-comment__content" :class="{ 'is-clamped': appearance === 'inline' && clamp }" :style="appearance === 'inline' ? clamp : undefined">
    <span class="flare-comment__relation">
     <span class="flare-comment__name flare-comment__name--author" :class="{ 'is-interactive': selectable && authorSelectable }">{{ comment.author.name }}</span>
     <template v-if="comment.replyToName"><span class="flare-comment__reply"> {{ t('moment.replyTo') }} </span><span class="flare-comment__name">{{ comment.replyToName }}</span></template>
     <span v-if="appearance === 'inline'" class="flare-comment__sep">：</span>
    </span>
    <span ref="body" :id="appearance === 'detail' ? contentId : undefined" class="flare-comment__text" :class="{ 'is-clamped': appearance === 'detail' && clamp }" :style="appearance === 'detail' ? clamp : undefined">{{ comment.text }}</span>
   </span>
  </component>
  <button v-if="overflows" class="flare-comment__expand" type="button" :aria-expanded="expanded" :aria-controls="contentId" @click="toggle">{{ t(expanded ? 'pluginView.collapse' : 'pluginView.expand') }}</button>
 </li>
</template>
<style scoped>
.flare-comment { min-width: 0; }
.flare-comment.is-targeted { background: var(--flare-color-bg-selected); box-shadow: inset 2px 0 var(--flare-color-border-selected); padding-inline: var(--flare-size-spacing-sm); }
.flare-comment.is-targeted:focus { outline: none; }
.flare-comment.is-targeted:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
.flare-comment__located { display: block; color: var(--flare-color-primary-text); font-size: var(--flare-size-font-size-sm); line-height: 1.5; }
.flare-comment__row { display: block; width: 100%; padding: var(--flare-size-spacing-3xs) 0; border: 0; background: none; font: inherit; font-size: var(--flare-size-font-size-md); line-height: 1.5; text-align: start; color: var(--flare-color-text-primary); overflow-wrap: anywhere; }
.flare-comment__content { display: block; }
.flare-comment__content.is-clamped, .flare-comment--detail .flare-comment__text.is-clamped { display: -webkit-box; -webkit-box-orient: vertical; overflow: hidden; }
.flare-comment__row.is-interactive { cursor: pointer; }
@media (hover: hover) { .flare-comment__row.is-interactive:hover { background: var(--flare-color-bg-hover); } .flare-comment__name.is-interactive:hover { text-decoration: underline; } }
.flare-comment__row:focus-visible, .flare-comment__expand:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 1px; }
.flare-comment__name { color: var(--flare-color-primary-text); font-weight: var(--flare-size-font-weight-medium); }
.flare-comment__reply { margin-inline: var(--flare-size-spacing-3xs); color: var(--flare-color-text-tertiary); }
.flare-comment__sep { color: var(--flare-color-text-tertiary); }
.flare-comment__text { white-space: pre-wrap; color: var(--flare-color-text-primary); }
.flare-comment__expand { display: flex; align-items: center; min-height: var(--flare-size-layout-touch-target-min); border: 0; padding: 0 var(--flare-size-spacing-xs); background: none; font: inherit; font-size: var(--flare-size-font-size-md); color: var(--flare-color-primary-text); cursor: pointer; }
.flare-comment--detail { padding-block: var(--flare-size-spacing-sm); }
.flare-comment--detail + .flare-comment--detail { border-top: 1px solid var(--flare-color-border-secondary); }
.flare-comment--detail .flare-comment__row { font-size: var(--flare-size-font-size-lg); }
.flare-comment--detail .flare-comment__relation { display: block; margin-bottom: var(--flare-size-spacing-xs); }
.flare-comment--detail .flare-comment__text { display: block; }
</style>
