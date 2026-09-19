<script setup lang="ts">
import { ref, computed, getCurrentInstance, onMounted, onUnmounted, watch } from "vue";
import { NIcon } from "naive-ui";
import { ChevronBackOutline } from "../../shared/icon-glyphs";
import { flareLayout } from "../../design-system/theme/layout-tokens";
import { resolvePaneMode, type FlareLayoutChange } from "../../shared/contracts/application";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { useFlareNativeBack } from "../../shared/platform/useFlareNativeBack";
import { useFlareDestinationDepth } from "../../composables/useFlareShell";

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
  { hasDetail: false, activePane: "list", hideMobileBar: false, listWidth: flareLayout.primaryPaneDefaultWidth, detailWidth: flareLayout.detailPaneDefaultWidth, textScale: 1},
);
const { t } = useFlareI18n();
const strings = computed(() => ({
  backLabel: props.backLabel ?? t("responsiveLayout.back"),
}));
const emit = defineEmits<{
  (e: "paneChange", pane: Pane): void;
  /** The panes in use once the layout knows its width, in the same words AppLayout reports: `singlePane` means the chat or detail replaced the list and the host owns the way back. */
  (e: "layoutChange", layout: FlareLayoutChange): void;
}>();

const root = ref<HTMLElement>();
const width = ref<number>();
let observer: ResizeObserver | undefined;
onMounted(() => {
  if (!root.value) return;
  width.value = root.value.clientWidth;
  observer = new ResizeObserver(entries => { width.value = entries[0].contentRect.width; });
  observer.observe(root.value);
});
onUnmounted(() => observer?.disconnect());
// The one pane rule (FR-110): the list beside a usable chat, the detail beside both when it fits too.
const paneMode = computed(() => resolvePaneMode(width.value ?? 0, props.hasDetail, {
  textScale: props.textScale, primaryWidth: props.listWidth, detailWidth: props.detailWidth,
}));
// A detail that is not beside the chat takes a pane's place when the host opens it.
const detailMode = computed(() => paneMode.value === "triplePane" ? "inline" : props.hasDetail ? "route" : "hidden");
watch([paneMode, detailMode, () => width.value !== undefined], ([mode, detail, measured]) => {
  if (measured) emit("layoutChange", { paneMode: mode, detailMode: detail });
}, { immediate: true });
function goBack(): void {
  emit('paneChange', props.activePane === 'detail' ? 'chat' : 'list');
}
const instance = getCurrentInstance();
// The platform back does what the phone back-bar does.
useFlareNativeBack(
  () => paneMode.value === 'singlePane' && props.activePane !== 'list' && !props.hideMobileBar && Boolean(instance?.vnode.props?.onPaneChange),
  goBack,
);
// The chat or the detail in the list's place is a page beyond the destination's root.
useFlareDestinationDepth(() => width.value !== undefined && paneMode.value === "singlePane" && props.activePane !== "list");
const columns = computed(() => ({ '--list-width': `${Math.max(0, props.listWidth)}px`, '--detail-width': `${Math.max(0, props.detailWidth)}px` }));
</script>

<template>
  <div ref="root" class="flare-rl" :class="{ 'flare-rl--single': paneMode === 'singlePane' }" :data-pane-mode="paneMode" :style="columns">
    <template v-if="paneMode !== 'singlePane'">
      <div class="flare-rl__list"><slot name="list" /></div>
      <div class="flare-rl__chat">
        <slot v-if="paneMode === 'dualPane' && activePane === 'detail' && hasDetail" name="detail" />
        <slot v-else name="chat" />
      </div>
      <div v-if="paneMode === 'triplePane'" class="flare-rl__detail"><slot name="detail" /></div>
    </template>
    <slot v-else-if="activePane === 'list'" name="list" />
    <template v-else>
      <div v-if="!hideMobileBar" class="flare-rl__bar">
        <button class="flare-rl__back" type="button" @click="goBack">
          <n-icon aria-hidden="true" :size="18" :component="ChevronBackOutline" /><span>{{ strings.backLabel }}</span>
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
/* The separator is drawn inside the column it bounds, so a column is exactly its width (the pane rule counts no separators). */
.flare-rl__list { width: var(--list-width); flex: none; box-sizing: border-box; border-inline-end: 1px solid var(--flare-color-border-primary); overflow: hidden; }
.flare-rl__chat { flex: 1; min-width: 0; min-height: 0; }
.flare-rl__detail { width: var(--detail-width); flex: none; box-sizing: border-box; border-inline-start: 1px solid var(--flare-color-border-primary); overflow: hidden; }
.flare-rl--single .flare-rl__list { width: 100%; border: none; }
.flare-rl__bar { border-bottom: 1px solid var(--flare-color-border-primary); }
.flare-rl__back {
  display: inline-flex; align-items: center; gap: 4px;
  min-width: 48px; min-height: 48px; border: none; background: none; padding: 10px 14px;
  color: var(--flare-color-primary-text); font-size: 14px; cursor: pointer;
}
.flare-rl__back:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
</style>
