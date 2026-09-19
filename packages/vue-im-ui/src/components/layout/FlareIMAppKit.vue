<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from "vue";
import {
  resolveApplicationResponsiveMode,
  type FlareApplicationResponsiveMode,
  type FlareIMAppConfiguration,
  type FlareNavigationIntent,
} from "../../shared/contracts/application";
import { provideFlareShell } from "../../composables/useFlareShell";
import FlareAdaptiveNavigation from "./FlareAdaptiveNavigation.vue";
import FlareShellDestination from "./FlareShellDestination.vue";

// The application shell (FR-095). It measures its own box — not the window — for the responsive mode and hands
// that mode down, draws the navigation the mode calls for, and renders one destination per navigation item
// through the `destination` slot. A destination arranges its own panes (AppLayout, WorkspaceFrame,
// ConversationWorkspace), keeps what it had when the person comes back to it, and hides the phone navigation
// while it shows a page beyond its root.
const props = withDefaults(defineProps<{
  configuration: FlareIMAppConfiguration;
  activeNavigationId: string;
  label?: string;
}>(), {
  label: "",
});

const emit = defineEmits<{
  (event: "navigate", id: string): void;
  (event: "intent", intent: FlareNavigationIntent): void;
}>();

defineSlots<{
  /** One destination: rendered once for every navigation item the person has opened, and kept. */
  destination(props: { id: string; active: boolean; emitIntent: (intent: FlareNavigationIntent) => void }): unknown;
  appBar?(): unknown;
  overlay?(): unknown;
  floating?(): unknown;
  command?(): unknown;
}>();

const root = ref<HTMLElement | null>(null);
const width = ref<number>();
let observer: ResizeObserver | undefined;
function measure(): void {
  width.value = root.value?.clientWidth || undefined;
}
onMounted(() => {
  measure();
  if (typeof ResizeObserver !== "undefined" && root.value) {
    observer = new ResizeObserver(measure);
    observer.observe(root.value);
  }
});
onBeforeUnmount(() => observer?.disconnect());

const responsiveMode = computed<FlareApplicationResponsiveMode | undefined>(() =>
  width.value === undefined ? undefined : resolveApplicationResponsiveMode(width.value));
provideFlareShell(responsiveMode);
const mobile = computed(() => responsiveMode.value === "mobile");

// Every destination opened so far stays mounted; one whose navigation item is gone is dropped.
const visited = ref<string[]>([]);
const knownIds = computed(() => new Set(props.configuration.navigation.flatMap((group) => group.items.map((item) => item.id))));
watch([() => props.activeNavigationId, knownIds], ([id, known]) => {
  const kept = visited.value.filter((entry) => entry === id || known.has(entry));
  visited.value = kept.includes(id) ? kept : [...kept, id];
}, { immediate: true });

// Pages beyond the root, per destination. The phone navigation steps aside while the active one has any.
const depths = ref<Record<string, number>>({});
function onDepth(id: string, depth: number): void {
  if ((depths.value[id] ?? 0) !== depth) depths.value = { ...depths.value, [id]: depth };
}
const navigationHidden = computed(() => mobile.value && (depths.value[props.activeNavigationId] ?? 0) > 0);
const emitIntent = (intent: FlareNavigationIntent) => emit("intent", intent);
</script>

<template>
  <section
    ref="root"
    class="flare-im-app-kit"
    :data-responsive-mode="responsiveMode"
    :data-navigation-hidden="navigationHidden || undefined"
    :aria-label="label || undefined"
  >
    <header v-if="mobile && $slots.appBar" class="flare-im-app-kit__app-bar"><slot name="appBar" /></header>
    <div v-if="responsiveMode && !mobile" class="flare-im-app-kit__rail">
      <FlareAdaptiveNavigation
        :groups="configuration.navigation"
        :active-id="activeNavigationId"
        :responsive-mode="responsiveMode"
        presentation="rail"
        :label="label"
        @navigate="emit('navigate', $event)"
      />
    </div>
    <div class="flare-im-app-kit__destinations">
      <FlareShellDestination
        v-for="id in visited"
        :key="id"
        :data-destination="id"
        :active="id === activeNavigationId"
        @depth="onDepth(id, $event)"
      >
        <slot name="destination" :id="id" :active="id === activeNavigationId" :emit-intent="emitIntent" />
      </FlareShellDestination>
    </div>
    <FlareAdaptiveNavigation
      v-if="mobile && !navigationHidden"
      class="flare-im-app-kit__bottom"
      :groups="configuration.navigation"
      :active-id="activeNavigationId"
      responsive-mode="mobile"
      presentation="bottom"
      :label="label"
      @navigate="emit('navigate', $event)"
    />
    <div class="flare-im-app-kit__overlay"><slot name="overlay" /></div>
    <div class="flare-im-app-kit__floating"><slot name="floating" /></div>
    <div class="flare-im-app-kit__command"><slot name="command" /></div>
  </section>
</template>

<style scoped>
/* One stable grid for every mode, so a destination never moves to another parent (and never remounts) when the
   window crosses a breakpoint. */
.flare-im-app-kit {
  position: relative;
  display: grid;
  width: 100%;
  height: 100%;
  min-width: 0;
  min-height: 0;
  overflow: hidden;
  grid-template-columns: minmax(0, 1fr);
  grid-template-rows: auto minmax(0, 1fr) auto;
  grid-template-areas: "bar" "destinations" "bottom";
  color: var(--flare-color-text-primary);
  background: var(--flare-color-bg-primary);
}
.flare-im-app-kit:not([data-responsive-mode="mobile"]) {
  grid-template-columns: auto minmax(0, 1fr);
  grid-template-rows: minmax(0, 1fr);
  grid-template-areas: "rail destinations";
}
.flare-im-app-kit__app-bar { grid-area: bar; padding-top: env(safe-area-inset-top); border-bottom: 1px solid var(--flare-color-border-primary); }
.flare-im-app-kit__rail { grid-area: rail; min-height: 0; }
.flare-im-app-kit__destinations { grid-area: destinations; position: relative; min-width: 0; min-height: 0; overflow: hidden; }
.flare-im-app-kit__bottom { grid-area: bottom; }
/* The overlay region covers the shell (global search, full-pane pickers); it lets pointer events through
   wherever it has no content. */
.flare-im-app-kit__overlay { position: absolute; inset: 0; z-index: var(--flare-z-index-overlay); pointer-events: none; }
.flare-im-app-kit__overlay > * { pointer-events: auto; }
.flare-im-app-kit__floating,
.flare-im-app-kit__command { display: contents; }
</style>
