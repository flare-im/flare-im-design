<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from "vue";
import { NIcon } from "naive-ui";
import { ChevronBackOutline } from "../../shared/icon-glyphs";
import { flareLayout, paneCount } from "../../design-system/theme/layout-policy";

type Pane = "list" | "chat" | "detail";
const props = withDefaults(
  defineProps<{
    hasDetail?: boolean;
    listWidth?: number;
    detailWidth?: number;
    textScale?: number;
    backLabel?: string;
    activePane?: Pane;
    /**
     * Suppress the phone back-bar. Set this when the chat/detail slot renders its
     * own header with a back control (e.g. FlareChatHeader `back`), so the app
     * shows ONE header instead of a redundant "‹ Back" bar stacked above it.
     */
    hideMobileBar?: boolean;
  }>(),
  { hasDetail: false, activePane: "list", hideMobileBar: false, listWidth: flareLayout.leftPanel, detailWidth: flareLayout.rightPanel, textScale: 1, backLabel: "Back" },
);
const emit = defineEmits<{ (e: "paneChange", pane: Pane): void }>();

const root = ref<HTMLElement>();
const width = ref(0);
let observer: ResizeObserver | undefined;
onMounted(() => {
  if (!root.value) return;
  width.value = root.value.clientWidth;
  observer = new ResizeObserver(entries => { width.value = entries[0].contentRect.width; });
  observer.observe(root.value);
});
onUnmounted(() => observer?.disconnect());
const panes = computed(() => paneCount(width.value, props.hasDetail, props.textScale, props.listWidth, props.detailWidth));
const columns = computed(() => ({ '--list-width': `${Math.max(0, props.listWidth)}px`, '--detail-width': `${Math.max(0, props.detailWidth)}px` }));
</script>

<template>
  <div ref="root" class="flare-rl" :class="{ 'flare-rl--single': panes === 1 }" :style="columns">
    <template v-if="panes > 1">
      <div class="flare-rl__list"><slot name="list" /></div>
      <div class="flare-rl__chat">
        <slot v-if="panes === 2 && activePane === 'detail' && hasDetail" name="detail" />
        <slot v-else name="chat" />
      </div>
      <div v-if="panes === 3" class="flare-rl__detail"><slot name="detail" /></div>
    </template>
    <slot v-else-if="activePane === 'list'" name="list" />
    <template v-else>
      <div v-if="!hideMobileBar" class="flare-rl__bar">
        <button class="flare-rl__back" type="button" @click="emit('paneChange', activePane === 'detail' ? 'chat' : 'list')">
          <n-icon :size="18" :component="ChevronBackOutline" /><span>{{ backLabel }}</span>
        </button>
      </div>
      <div class="flare-rl__chat">
        <slot v-if="activePane === 'detail' && hasDetail" name="detail" />
        <slot v-else name="chat" />
      </div>
    </template>
  </div>
</template>

<style scoped>
.flare-rl { display: flex; width: 100%; height: 100%; }
.flare-rl--single { flex-direction: column; }
.flare-rl__list { width: var(--list-width); flex: none; border-inline-end: 1px solid var(--flare-color-border-primary); overflow: hidden; }
.flare-rl__chat { flex: 1; min-width: 0; min-height: 0; }
.flare-rl__detail { width: var(--detail-width); flex: none; border-inline-start: 1px solid var(--flare-color-border-primary); overflow: hidden; }
.flare-rl--single .flare-rl__list { width: 100%; border: none; }
.flare-rl__bar { border-bottom: 1px solid var(--flare-color-border-primary); }
.flare-rl__back {
  display: inline-flex; align-items: center; gap: 4px;
  min-width: 48px; min-height: 48px; border: none; background: none; padding: 10px 14px;
  color: var(--flare-color-primary); font-size: 14px; cursor: pointer;
}
.flare-rl__back:focus-visible { outline: 2px solid var(--flare-color-primary); outline-offset: -2px; }
</style>
