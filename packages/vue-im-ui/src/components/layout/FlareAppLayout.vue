<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, useSlots, watch } from "vue";
import {
  resolveApplicationResponsiveMode,
  resolveNavigationWidth,
  resolvePaneMode,
  resolveWorkspacePresentation,
  type FlareLayoutChange,
  type FlareWorkspaceDetailPresentation,
  type FlareWorkspacePane,
  type FlareWorkspacePaneMode,
} from "../../shared/contracts/application";
import { flareLayout } from "../../design-system/theme/layout-tokens";
import {
  useFlareDestinationDepth,
  useFlareDestinationMainLandmark,
  useFlareShellResponsiveMode,
} from "../../composables/useFlareShell";

const props = withDefaults(defineProps<{
  activePane?: FlareWorkspacePane;
  hasDetail?: boolean;
  paneMode?: FlareWorkspacePaneMode;
  detailMode?: FlareWorkspaceDetailPresentation;
  primaryWidth?: number;
  detailWidth?: number;
  label?: string;
}>(), {
  activePane: "content",
  hasDetail: false,
  primaryWidth: flareLayout.primaryPaneDefaultWidth,
  detailWidth: flareLayout.detailPaneDefaultWidth,
  label: "",
});
const emit = defineEmits<{
  /** The presentation the layout actually uses once it knows its width; a host shows its back control for `singlePane`. */
  (event: "layoutChange", layout: FlareLayoutChange): void;
}>();
const slots = useSlots();
const root = ref<HTMLElement | null>(null);
const containerWidth = ref<number | undefined>(undefined);
const navigationWidth = ref<number | undefined>(undefined);
let observer: ResizeObserver | undefined;
// Measure the box the layout is given (its parent), not itself: an overflowing grid reports its own
// min-content width and would always claim to fit.
function measure(): void {
  const host = root.value?.parentElement ?? root.value;
  containerWidth.value = host?.clientWidth || undefined;
  // The navigation the host actually renders (a 72 px rail or a sidebar) decides what fits, not the
  // widest navigation the responsive mode allows.
  const navigation = root.value?.querySelector<HTMLElement>(":scope > .flare-app-layout__navigation");
  navigationWidth.value = navigation?.offsetWidth || undefined;
}
onMounted(() => {
  measure();
  if (typeof ResizeObserver !== "undefined" && root.value) {
    observer = new ResizeObserver(measure);
    observer.observe(root.value.parentElement ?? root.value);
  }
});
onBeforeUnmount(() => observer?.disconnect());

// Inside a shell the mode is the shell's (FR-095): it measured the box the whole app lives in. On its own the
// layout is its own shell and resolves the mode from the box it was given.
const shellMode = useFlareShellResponsiveMode();
// The content pane is the page's main landmark, beside complementary list and detail panes.
useFlareDestinationMainLandmark();
const responsiveMode = computed(() =>
  shellMode?.value
  ?? (containerWidth.value === undefined ? "desktop" : resolveApplicationResponsiveMode(containerWidth.value)));
// The navigation the host actually renders (measured once it is on screen) is what takes the room.
const paneMetrics = computed(() => ({
  primaryWidth: props.primaryWidth,
  detailWidth: props.detailWidth,
  navigationWidth: slots.navigation ? navigationWidth.value ?? resolveNavigationWidth(responsiveMode.value) : 0,
}));
const resolved = computed(() => resolveWorkspacePresentation(responsiveMode.value, props.hasDetail, { ...paneMetrics.value, width: containerWidth.value }));
// The most panes this box holds, by the one pane rule. A box not measured yet, or a phone, is not limited
// by width here.
const capacity = computed(() => {
  const width = containerWidth.value;
  if (width === undefined || responsiveMode.value === "mobile") return "triplePane";
  return resolvePaneMode(width, true, paneMetrics.value);
});
// A host may ask for an inline third pane without knowing the width; the layout still refuses to crush the
// chat and shows the detail as an overlay until the three panes fit. Tablet's grid is navigation, primary and
// content: there is no detail column, so a detail opens as an overlay there.
const triplePaneFits = computed(() => responsiveMode.value !== "tablet" && capacity.value === "triplePane");
// Below navigation + list + a usable chat, the layout shows one pane at a time instead of squeezing the chat,
// and keeps the navigation.
const dualPaneFits = computed(() => capacity.value !== "singlePane");
const effectivePaneMode = computed(() => {
  // A phone shows one pane at a time, whatever the host asked for.
  if (responsiveMode.value === "mobile") return "singlePane";
  const requested = props.paneMode ?? resolved.value.paneMode;
  if (requested !== "singlePane" && !dualPaneFits.value) return "singlePane";
  return requested === "triplePane" && !triplePaneFits.value ? "dualPane" : requested;
});
const effectiveDetailMode = computed(() => {
  const requested = props.detailMode ?? resolved.value.detail;
  if (effectivePaneMode.value === "singlePane" && props.paneMode !== "singlePane") return props.hasDetail ? "route" : "hidden";
  return requested === "inline" && !triplePaneFits.value ? "overlay" : requested;
});
watch([effectivePaneMode, effectiveDetailMode], ([paneMode, detailMode]) => emit("layoutChange", { paneMode, detailMode }), { immediate: true });
// One pane showing something other than the list is a page beyond the destination's root.
useFlareDestinationDepth(() => effectivePaneMode.value === "singlePane" && Boolean(slots.primary) && props.activePane !== "primary");
const style = computed(() => ({
  "--flare-app-primary-width": `${Math.max(0, props.primaryWidth)}px`,
  "--flare-app-detail-width": `${Math.max(0, props.detailWidth)}px`,
}));
</script>

<template>
  <section
    ref="root"
    class="flare-app-layout"
    :class="{ 'has-navigation': Boolean(slots.navigation) }"
    :data-responsive-mode="responsiveMode"
    :data-pane-mode="effectivePaneMode"
    :data-detail-mode="effectiveDetailMode"
    :aria-label="label || undefined"
    :style="style"
  >
    <div v-if="$slots.navigation" class="flare-app-layout__navigation"><slot name="navigation" /></div>

    <template v-if="effectivePaneMode === 'singlePane'">
      <aside v-if="activePane === 'primary'" class="flare-app-layout__single"><slot name="primary" /></aside>
      <aside v-else-if="activePane === 'detail' && hasDetail" class="flare-app-layout__single"><slot name="detail" /></aside>
      <main v-else class="flare-app-layout__single"><slot name="content" /></main>
    </template>
    <template v-else>
      <aside class="flare-app-layout__primary"><slot name="primary" /></aside>
      <main class="flare-app-layout__content"><slot name="content" /></main>
      <aside v-if="hasDetail && effectiveDetailMode === 'inline' && effectivePaneMode === 'triplePane'" class="flare-app-layout__detail"><slot name="detail" /></aside>
    </template>

    <aside v-if="hasDetail && effectiveDetailMode === 'overlay'" class="flare-app-layout__detail-overlay"><slot name="detail" /></aside>
    <div class="flare-app-layout__overlay"><slot name="overlay" /></div>
    <div class="flare-app-layout__floating"><slot name="floating" /></div>
    <div class="flare-app-layout__command"><slot name="command" /></div>
  </section>
</template>

<style scoped>
.flare-app-layout {
  position: relative;
  display: grid;
  width: 100%;
  height: 100%;
  min-width: 0;
  min-height: 0;
  overflow: hidden;
  grid-template-columns: minmax(0, 1fr);
  grid-template-areas: "content";
  color: var(--flare-color-text-primary);
  background: var(--flare-color-bg-primary);
}
.flare-app-layout__navigation { grid-area: navigation; min-width: 0; min-height: 0; }
.flare-app-layout__primary { grid-area: primary; min-width: 0; min-height: 0; overflow: hidden; border-inline-end: 1px solid var(--flare-color-border-primary); }
.flare-app-layout__content,
.flare-app-layout__single { grid-area: content; min-width: 0; min-height: 0; overflow: hidden; }
.flare-app-layout__detail { grid-area: detail; min-width: 0; min-height: 0; overflow: hidden; border-inline-start: 1px solid var(--flare-color-border-primary); }
.flare-app-layout[data-pane-mode="dualPane"] { grid-template-columns: var(--flare-app-primary-width) minmax(0, 1fr); grid-template-areas: "primary content"; }
.flare-app-layout[data-pane-mode="triplePane"] { grid-template-columns: var(--flare-app-primary-width) minmax(var(--flare-size-layout-chat-min-width), 1fr) var(--flare-app-detail-width); grid-template-areas: "primary content detail"; }
.flare-app-layout.has-navigation[data-responsive-mode="tablet"] { grid-template-columns: auto var(--flare-app-primary-width) minmax(0, 1fr); grid-template-areas: "navigation primary content"; }
.flare-app-layout.has-navigation[data-responsive-mode="desktop"][data-pane-mode="dualPane"],
.flare-app-layout.has-navigation[data-responsive-mode="wideDesktop"][data-pane-mode="dualPane"] { grid-template-columns: auto var(--flare-app-primary-width) minmax(0, 1fr); grid-template-areas: "navigation primary content"; }
.flare-app-layout.has-navigation[data-responsive-mode="desktop"][data-pane-mode="triplePane"],
.flare-app-layout.has-navigation[data-responsive-mode="wideDesktop"][data-pane-mode="triplePane"] { grid-template-columns: minmax(var(--flare-size-layout-navigation-rail-width), auto) var(--flare-app-primary-width) minmax(var(--flare-size-layout-chat-min-width), 1fr) var(--flare-app-detail-width); grid-template-areas: "navigation primary content detail"; }
.flare-app-layout.has-navigation[data-pane-mode="singlePane"] { grid-template-columns: auto minmax(0, 1fr); grid-template-areas: "navigation content"; }
.flare-app-layout__detail-overlay {
  position: absolute;
  inset-block: 0;
  inset-inline-end: 0;
  z-index: var(--flare-z-index-overlay);
  width: min(var(--flare-size-layout-detail-pane-max-width), calc(100% - var(--flare-size-layout-navigation-rail-width)));
  max-width: 92%;
  overflow: auto;
  background: var(--flare-color-bg-primary);
  border-inline-start: 1px solid var(--flare-color-border-primary);
  box-shadow: var(--flare-shadow-lg);
}
/* The overlay region covers the workspace (global search, full-pane pickers); it never
   joins the pane grid, and it lets pointer events through wherever it has no content. */
.flare-app-layout__overlay { position: absolute; inset: 0; z-index: var(--flare-z-index-overlay); pointer-events: none; }
.flare-app-layout__overlay > * { pointer-events: auto; }
.flare-app-layout__floating,
.flare-app-layout__command { display: contents; }
@media (prefers-reduced-motion: reduce) {
  .flare-app-layout * { scroll-behavior: auto !important; }
}
</style>
