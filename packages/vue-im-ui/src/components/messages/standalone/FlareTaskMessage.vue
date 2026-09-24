<script setup lang="ts">
import { getCurrentInstance } from "vue";
import MsgIcon from "./MsgIcon.vue";
// Presentational — emits `toggle` when the checkbox is tapped; the host flips the
// task's done state. Without a `toggle` listener the box is a read-only state
// indicator. `embedded` drops the card chrome when the body sits inside a
// message-card surface (how the timeline dispatcher renders it).
withDefaults(defineProps<{ title?: string; meta?: string; done?: boolean; embedded?: boolean }>(), {
  title: "task",
  meta: "",
  done: false,
  embedded: false,
});
const emit = defineEmits<{ (e: "toggle"): void }>();
const instance = getCurrentInstance();
const canToggle = () => Boolean(instance?.vnode.props?.onToggle);
</script>
<template>
  <div class="fm-task" :class="{ 'fm-task--embedded': embedded }">
    <component
      :is="canToggle() ? 'button' : 'span'"
      :type="canToggle() ? 'button' : undefined"
      class="box"
      :class="{ done }"
      role="checkbox"
      :aria-checked="done"
      :aria-disabled="canToggle() ? undefined : 'true'"
      :aria-label="title"
      @click="canToggle() && emit('toggle')"
    >
      <MsgIcon v-if="done" name="check" :size="13" />
    </component>
    <span class="meta"><b :class="{ done }">{{ title }}</b><small v-if="meta">{{ meta }}</small></span>
  </div>
</template>
<style scoped>
.fm-task { display: inline-flex; align-items: center; gap: var(--flare-size-spacing-2sm); min-width: 220px; padding: 9px var(--flare-size-spacing-2md); border-radius: 16px 16px 16px 4px; background: var(--flare-color-bg-primary); border: 1px solid var(--flare-color-border-secondary); box-shadow: var(--flare-component-bubble-shadow); }
.box { padding: 0; width: 20px; height: 20px; border-radius: var(--flare-size-radius-sm); flex: none; display: grid; place-items: center; border: 1.5px solid var(--flare-color-border-primary); background: none; color: #fff; }
button.box { position: relative; cursor: pointer; }
/* The 20px box keeps its size in the layout; its target reaches the touch-target size around it. */
button.box::after { content: ""; position: absolute; inset: calc((20px - var(--flare-size-layout-touch-target)) / 2); }
button.box:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.fm-task--embedded { min-width: 0; padding: 0; border: 0; border-radius: 0; color: inherit; background: transparent; box-shadow: none; }
.box.done { background: var(--flare-color-primary); border-color: var(--flare-color-primary); }
.meta { flex: 1; display: flex; flex-direction: column; }
.meta b { font-size: var(--flare-size-font-size-lg); font-weight: 500; color: var(--flare-color-text-primary); }
.meta b.done { text-decoration: line-through; color: var(--flare-color-text-tertiary); }
.meta small { font-size: var(--flare-size-font-size-xs); color: var(--flare-color-text-tertiary); }
</style>
