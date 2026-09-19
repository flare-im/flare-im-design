<script setup lang="ts">
import { computed, ref, type Component } from "vue";
import { NIcon } from "naive-ui";
import {
  CodeSlashOutline, CodeWorkingOutline, ImageOutline, LinkOutline, ListOutline,
  ReaderOutline, RemoveOutline, ReorderThreeOutline,
} from "../../shared/icon-glyphs";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { MarkdownShortcutKey } from "../../composables/composer/useMarkdownShortcuts";
import type { RichHeadingLevel, RichMarkdownFormatState } from "./ComposerRichMarkdownInput.vue";

type FormatAction = { key: MarkdownShortcutKey; title: string; icon?: Component; glyph?: string };

// Rich-text toolbar of the composer: one compact text-style select plus the
// inline / block / insert groups. It only reports intents; the composer applies
// them to whichever editor is active.
const props = defineProps<{ state: RichMarkdownFormatState; disabled?: boolean }>();
const emit = defineEmits<{ (event: "apply", key: MarkdownShortcutKey): void; (event: "heading", level: RichHeadingLevel | null): void }>();
const { t } = useFlareI18n();

const groups = computed<ReadonlyArray<ReadonlyArray<FormatAction>>>(() => [
  [
    { key: "bold", glyph: "B", title: t("composer.formatBold") },
    { key: "strike", glyph: "S", title: t("composer.formatStrike") },
    { key: "italic", glyph: "I", title: t("composer.formatItalic") },
    { key: "underline", glyph: "U", title: t("composer.formatUnderline") },
  ],
  [
    { key: "ordered", icon: ReorderThreeOutline, title: t("composer.formatOrdered") },
    { key: "bullet", icon: ListOutline, title: t("composer.formatBullet") },
    { key: "quote", icon: ReaderOutline, title: t("composer.formatQuote") },
  ],
  [
    { key: "link", icon: LinkOutline, title: t("composer.formatLink") },
    { key: "image", icon: ImageOutline, title: t("composer.formatImage") },
    { key: "code", icon: CodeSlashOutline, title: t("composer.formatCode") },
    { key: "codeBlock", icon: CodeWorkingOutline, title: t("composer.formatCodeBlock") },
    { key: "divider", icon: RemoveOutline, title: t("composer.formatDivider") },
  ],
]);
const headingOptions = computed<ReadonlyArray<{ level: RichHeadingLevel | null; label: string; description: string }>>(() => [
  { level: null, label: "P", description: t("composer.paragraph") },
  ...([1, 2, 3, 4, 5, 6] as RichHeadingLevel[]).map((level) => ({ level, label: `H${level}`, description: t("composer.heading", { level }) })),
]);
const activeHeadingDescription = computed(() =>
  headingOptions.value.find((option) => option.level === props.state.headingLevel)?.description,
);
function isActive(key: MarkdownShortcutKey): boolean {
  return key === "bold" || key === "strike" || key === "italic" || key === "underline" || key === "code"
    ? props.state.inline[key]
    : false;
}
// pointerdown applies the format before the editor loses focus; the following click is then a no-op.
const pointerActive = ref(false);
function fromPointer(key: MarkdownShortcutKey): void {
  if (props.disabled) return;
  pointerActive.value = true;
  emit("apply", key);
}
function fromClick(key: MarkdownShortcutKey): void {
  if (pointerActive.value) { pointerActive.value = false; return; }
  if (!props.disabled) emit("apply", key);
}
function onHeadingChange(event: Event): void {
  const value = Number((event.target as HTMLSelectElement).value);
  emit("heading", value >= 1 && value <= 6 ? (value as RichHeadingLevel) : null);
}
</script>

<template>
  <div class="composer-format-strip" role="group" :aria-label="t('composer.formatToolbar')" @mousedown.stop>
    <div class="composer-format-group composer-format-group--heading" role="group" :aria-label="t('composer.headingLevel')">
      <label class="composer-format-heading-control">
        <select
          class="composer-heading-select"
          :class="{ 'is-active': state.headingLevel !== null }"
          :value="String(state.headingLevel ?? '')"
          :aria-label="t('composer.headingLevel')"
          :title="activeHeadingDescription"
          :disabled="disabled"
          @change="onHeadingChange"
        >
          <option v-for="option in headingOptions" :key="String(option.level ?? 'paragraph')" :value="String(option.level ?? '')" :aria-label="option.description" :title="option.description">
            {{ option.label }}
          </option>
        </select>
      </label>
    </div>
    <div v-for="(group, groupIndex) in groups" :key="`format-group-${groupIndex}`" class="composer-format-group" role="group">
      <button
        v-for="action in group"
        :key="action.key"
        type="button"
        class="composer-format-button"
        :class="[`composer-format-button--${action.key}`, { 'is-active': isActive(action.key) }]"
        :title="action.title"
        :aria-label="action.title"
        :aria-pressed="isActive(action.key)"
        :disabled="disabled"
        @pointerdown.prevent.stop="fromPointer(action.key)"
        @click.prevent.stop="fromClick(action.key)"
        @keydown.enter.prevent.stop="emit('apply', action.key)"
        @keydown.space.prevent.stop="emit('apply', action.key)"
      >
        <n-icon aria-hidden="true" v-if="action.icon" :size="14" :component="action.icon" />
        <span v-else class="composer-format-glyph" :class="`composer-format-glyph--${action.key}`" aria-hidden="true">{{ action.glyph }}</span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.composer-format-strip {
  position: relative;
  display: flex;
  grid-column: 1 / -1;
  flex-wrap: nowrap;
  align-items: center;
  min-width: 0;
  width: 100%;
  height: 34px;
  min-height: 34px;
  gap: 2px;
  padding: 2px 10px 3px;
  overflow-x: auto;
  overflow-y: hidden;
  border: 0;
  border-radius: 0;
  background: transparent;
  box-shadow: none;
  scrollbar-width: none;
}
.composer-format-strip::-webkit-scrollbar { display: none; }
.composer-format-group { display: flex; align-items: center; flex: 0 0 auto; gap: 1px; padding: 0 var(--flare-size-spacing-xs); border: 0; }
.composer-format-group + .composer-format-group { border-inline-start: 1px solid var(--studio-divider, var(--flare-color-border-secondary)); }
.composer-format-button,
.composer-heading-select {
  height: 28px;
  border: 0;
  border-radius: var(--flare-size-radius-sm, 6px);
  color: var(--flare-color-text-secondary);
  background: transparent;
  box-shadow: none;
  cursor: pointer;
}
.composer-format-button { display: grid; place-items: center; flex: 0 0 28px; width: 28px; min-width: 28px; padding: 0; font-size: var(--flare-size-font-size-sm); }
.composer-heading-select { width: 56px; min-width: 56px; padding: 0 var(--flare-size-spacing-sm) 0 var(--flare-size-spacing-2xs); font: 600 12px/1 var(--flare-component-font-family); }
.composer-format-button:hover,
.composer-format-button.is-active,
.composer-heading-select:hover,
.composer-heading-select.is-active { color: var(--studio-accent, var(--flare-color-primary-text)); background: var(--flare-color-bg-hover); }
.composer-format-button:disabled,
.composer-heading-select:disabled { opacity: var(--flare-opacity-disabled, 0.5); cursor: default; }
.composer-format-button:focus-visible,
.composer-heading-select:focus-visible { outline: 2px solid var(--studio-focus, var(--flare-color-border-selected)); outline-offset: -2px; }
@media (pointer: coarse) {
  .composer-format-strip { height: 44px; min-height: 44px; }
  .composer-format-button { width: 44px; min-width: 44px; height: 44px; }
}
</style>
