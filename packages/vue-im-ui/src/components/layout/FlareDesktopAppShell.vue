<script setup lang="ts">
import { computed } from "vue";
import { provideFlareShell } from "../../composables/useFlareShell";
import { flareLayout } from "../../design-system/theme/layout-tokens";
import type {
  FlareApplicationResponsiveMode,
  FlareDesktopShellCommand,
  FlareLayoutChange,
  FlareNavigationGroup,
  FlareWorkspaceDetailPresentation,
  FlareWorkspacePaneMode,
} from "../../shared/contracts/application";
import FlareAdaptiveNavigation from "./FlareAdaptiveNavigation.vue";
import FlareAppLayout from "./FlareAppLayout.vue";

const props = withDefaults(defineProps<{
  navigation: readonly FlareNavigationGroup[];
  activeNavigationId: string;
  responsiveMode?: "desktop" | "wideDesktop";
  paneMode?: FlareWorkspacePaneMode;
  detailMode?: FlareWorkspaceDetailPresentation;
  hasDetail?: boolean;
  primaryWidth?: number;
  detailWidth?: number;
  label?: string;
}>(), {
  responsiveMode: "desktop",
  paneMode: "dualPane",
  detailMode: "hidden",
  hasDetail: false,
  primaryWidth: flareLayout.primaryPaneDefaultWidth,
  detailWidth: flareLayout.detailPaneDefaultWidth,
  label: "",
});

const emit = defineEmits<{
  (event: "navigate", id: string): void;
  (event: "command", command: FlareDesktopShellCommand): void;
  /** Forwarded from the layout: the presentation actually in use. See FlareAppLayout. */
  (event: "layoutChange", layout: FlareLayoutChange): void;
}>();
const mode = computed(() => props.responsiveMode as FlareApplicationResponsiveMode);
// A desktop shell is told its presentation rather than measuring for it; the layout inside reads it from here.
provideFlareShell(mode);

function onKeydown(event: KeyboardEvent): void {
  const primary = event.metaKey || event.ctrlKey;
  const key = event.key.toLowerCase();
  const command = key === "escape" ? "closeOverlay"
    : primary && key === "k" ? "openCommandPalette"
    : primary && key === "f" ? "openSearch"
    : primary && key === "n" ? "newConversation"
    : primary && event.shiftKey && key === "d" ? "toggleDetails"
    : primary && key === "," ? "openSettings"
    : event.altKey && key === "/" ? "moreActions"
    : undefined;
  if (!command) return;
  event.preventDefault();
  emit("command", command);
}
</script>

<template>
  <FlareAppLayout
    :pane-mode="paneMode"
    :detail-mode="detailMode"
    :has-detail="hasDetail"
    :primary-width="primaryWidth"
    :detail-width="detailWidth"
    :label="label"
    @layout-change="emit('layoutChange', $event)"
    tabindex="-1"
    @keydown="onKeydown"
  >
    <template #navigation>
      <FlareAdaptiveNavigation :groups="navigation" :active-id="activeNavigationId" :responsive-mode="mode" :label="label" @navigate="emit('navigate', $event)" />
    </template>
    <template #primary><slot name="primary" /></template>
    <template #content><slot /></template>
    <template #detail><slot name="detail" /></template>
    <template #overlay><slot name="overlay" /></template>
    <template #floating><slot name="floating" /></template>
    <template #command><slot name="command" /></template>
  </FlareAppLayout>
</template>
