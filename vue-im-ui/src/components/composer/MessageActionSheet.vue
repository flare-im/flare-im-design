<script setup lang="ts">
/**
 * Message feature sheet — a grid of attachment / feature actions. The host either
 * passes its own `actions` (unified `id` table shared with the native kits) or
 * keeps the built-in default set. Each tap emits `action(action)`; the legacy
 * `build(op)` event is still dispatched alongside with the pre-1.1 operation
 * name (`file` → `create_file`, `link` → `create_link_card`, ...).
 */
import { computed } from "vue";
import FlareGlyph from "../general/FlareGlyph.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { composerActionLegacyOp, type FlareComposerAction, type FlareComposerActionId } from "../../shared/contracts/composer";

const props = withDefaults(
  defineProps<{
    /** Replaces the built-in default set when provided. */
    actions?: FlareComposerAction[];
  }>(),
  { actions: undefined },
);

const emit = defineEmits<{
  (event: "action", action: FlareComposerAction): void;
  /** @deprecated Use `action`. Still dispatched with the legacy `create_*` op name. */
  (event: "build", op: string): void;
}>();

const { t } = useFlareI18n();

/** Default tile order + label key + semantic icon for the unified action table. */
const DEFAULT_ACTIONS: ReadonlyArray<{ id: FlareComposerActionId; labelKey: string; icon: string }> = [
  { id: "image", labelKey: "composer.image", icon: "image" },
  { id: "camera", labelKey: "composer.camera", icon: "camera" },
  { id: "video", labelKey: "composer.video", icon: "video" },
  { id: "file", labelKey: "composer.file", icon: "folder" },
  { id: "location", labelKey: "composer.location", icon: "location" },
  { id: "card", labelKey: "composer.card", icon: "person" },
  { id: "vote", labelKey: "composer.vote", icon: "poll" },
  { id: "task", labelKey: "composer.task", icon: "check" },
  { id: "schedule", labelKey: "composer.schedule", icon: "calendar" },
  { id: "link", labelKey: "composer.link", icon: "link" },
  { id: "announcement", labelKey: "business.announcement", icon: "announcement" },
  { id: "notification", labelKey: "composer.notification", icon: "notification" },
  { id: "miniProgram", labelKey: "business.miniProgram", icon: "link" },
  { id: "translate", labelKey: "composer.translation", icon: "language" },
];

const defaultActions = computed<FlareComposerAction[]>(() =>
  DEFAULT_ACTIONS.map(({ id, labelKey, icon }) => ({ id, label: t(labelKey), icon })),
);
const items = computed<FlareComposerAction[]>(() => props.actions ?? defaultActions.value);

function select(action: FlareComposerAction): void {
  emit("action", action);
  emit("build", composerActionLegacyOp(action.id));
}
</script>

<template>
  <div class="message-action-sheet" role="group" :aria-label="t('composer.features')">
    <button
      v-for="action in items"
      :key="action.id"
      type="button"
      class="message-action"
      :data-action-id="action.id"
      @click="select(action)"
    >
      <span class="message-action__icon">
        <FlareGlyph :icon="action.icon || 'add'" :size="20" />
      </span>
      <span>{{ action.label }}</span>
      <small v-if="action.hint">{{ action.hint }}</small>
    </button>
  </div>
</template>
