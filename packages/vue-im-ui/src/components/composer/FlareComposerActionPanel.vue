<script setup lang="ts">
import { computed, type Component } from "vue";
import FlareGlyph from "../general/FlareGlyph.vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import {
  resolveComposerActions,
  type FlareComposerAction,
  type FlareComposerActionId,
  type FlareComposerCapabilities,
} from "../../shared/contracts/composer";
/** `icon` is a semantic glyph name (shared with the native kits) or, for Vue hosts, any icon component. */
export type FlareComposerActionItem = FlareComposerAction<string | Component> & { tone?: string };

/**
 * The composer's attachment / feature grid (下方功能区). The host either passes
 * its own `actions` (unified `id` table shared with the native kits) or keeps
 * the built-in default set, whose labels come from the strings provider. Each
 * tap emits `action(action)`. A composable part: reveal it under the input, or
 * present it in a sheet — this is the one grid; the message long-press sheet is
 * MessageActionSheet.
 */
const props = withDefaults(
  defineProps<{ actions?: FlareComposerActionItem[]; capabilities?: FlareComposerCapabilities; columns?: number }>(),
  { actions: undefined, capabilities: undefined, columns: 4 },
);
const emit = defineEmits<{ (e: "action", action: FlareComposerActionItem): void }>();
const { t } = useFlareI18nOptional();

/** The kit glyph of each unified action id; an action without its own icon shows it. */
const ACTION_ID_ICONS: Readonly<Record<FlareComposerActionId, string>> = {
  image: "image", camera: "camera", voice: "mic", video: "video", file: "file", location: "location",
  contact: "person", card: "person", poll: "poll", vote: "poll", task: "check", event: "calendar",
  schedule: "calendar", link: "link", announcement: "announcement", notification: "notification",
  miniApp: "mini-app", miniProgram: "mini-app", translate: "translate",
};
/** Default tile order + label key for the unified action table. */
const DEFAULT_ACTIONS: ReadonlyArray<{ id: FlareComposerActionId; labelKey: string }> = [
  { id: "image", labelKey: "composer.image" },
  { id: "video", labelKey: "composer.video" },
  { id: "file", labelKey: "composer.file" },
  { id: "voice", labelKey: "composer.voice" },
  { id: "location", labelKey: "composer.location" },
  { id: "contact", labelKey: "composer.card" },
];
const defaults = computed<FlareComposerActionItem[]>(() =>
  DEFAULT_ACTIONS.map(({ id, labelKey }) => ({ id, label: t(labelKey), icon: ACTION_ID_ICONS[id] })),
);
function glyphFor(action: FlareComposerActionItem): string {
  return (typeof action.icon === "string" && action.icon) || ACTION_ID_ICONS[action.id as FlareComposerActionId] || "add";
}
const resolvedActions = computed<FlareComposerActionItem[]>(() => resolveComposerActions<string | Component>({
  defaults: defaults.value,
  actions: props.actions,
  capabilities: props.capabilities,
}));

function select(action: FlareComposerActionItem): void {
  if (action.enabled === false) return;
  emit("action", action);
}
</script>

<template>
  <div
    class="flare-action-panel"
    role="group"
    :aria-label="t('composer.features')"
    :style="{ gridTemplateColumns: `repeat(${columns}, 1fr)` }"
  >
    <button
      v-for="a in resolvedActions"
      :key="a.id"
      type="button"
      class="flare-action-panel__tile"
      :data-action-id="a.id"
      :data-tone="a.tone || undefined"
      :disabled="a.enabled === false"
      :title="a.disabledReason || a.label"
      :aria-label="a.accessibilityLabel || a.label"
      @click="select(a)"
    >
      <span class="flare-action-panel__ico">
        <component :is="a.icon" v-if="a.icon && typeof a.icon !== 'string'" />
        <FlareGlyph v-else :icon="glyphFor(a)" :size="24" />
      </span>
      <span class="flare-action-panel__label">{{ a.label }}</span>
      <span v-if="a.badge" class="flare-action-panel__badge">{{ a.badge }}</span>
      <small v-if="a.hint" class="flare-action-panel__hint">{{ a.hint }}</small>
    </button>
  </div>
</template>

<style scoped>
.flare-action-panel {
  display: grid;
  gap: 16px;
  padding: 16px;
  background: var(--flare-color-bg-primary);
}
.flare-action-panel__tile {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  border: none;
  background: none;
  cursor: pointer;
}
.flare-action-panel__tile:disabled { opacity: var(--flare-opacity-disabled); cursor: not-allowed; }
.flare-action-panel__ico {
  width: 52px;
  height: 52px;
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-secondary);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: var(--flare-size-font-size-5xl);
}
.flare-action-panel__label {
  font-size: 12px;
  color: var(--flare-color-text-secondary);
}
.flare-action-panel__ico :deep(svg) { width: 24px; height: 24px; }
.flare-action-panel__badge,
.flare-action-panel__hint { color: var(--flare-color-text-tertiary); font-size: var(--flare-size-font-size-xs); }
.flare-action-panel__tile:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
</style>
