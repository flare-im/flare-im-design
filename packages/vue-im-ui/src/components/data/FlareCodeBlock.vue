<script setup lang="ts">
/**
 * A code block — text a person reads exactly and usually copies: a raw payload, an initialisation
 * snippet, a webhook body, an API key's usage line. Monospaced, kept as written (no reflow unless
 * `wrap`), scrolling inside its own bounded box, with a copy key that writes the whole text.
 *
 * It highlights nothing. A console shows a payload to be read and copied, not edited, and a
 * highlighter is a parser per language plus a palette per theme that the kit would have to keep at
 * 4.5:1 in every brand; `language` is only the label over the text. The host formats the text
 * (`JSON.stringify(value, null, 2)` for a payload) and decides what may be shown at all.
 */
import { computed } from "vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { flareIcons } from "../../shared/icons";

const props = withDefaults(
  defineProps<{
    /** The text, exactly as it should be read and copied. */
    code: string;
    /** What the text is (JSON, TypeScript, curl), shown over it. Labels only; nothing is highlighted. */
    language?: string;
    /** Accessible name of the scroll box. Default: `language`, else the kit's "Code". */
    label?: string;
    /** Draw the copy key. */
    copyable?: boolean;
    /** Wrap long lines instead of scrolling sideways (prose-like payloads). */
    wrap?: boolean;
    /** Height cap as a CSS length. Default `--flare-component-code-block-max-height`. */
    maxHeight?: string;
  }>(),
  { language: undefined, label: undefined, copyable: true, wrap: false, maxHeight: undefined },
);
const emit = defineEmits<{
  /** After the copy key: `copied` is false when the clipboard refused the text. */
  (e: "copy", copied: boolean): void;
}>();

const { t } = useFlareI18nOptional();
const name = computed(() => props.label || props.language || t("codeBlock.label"));
const hasHead = computed(() => Boolean(props.language) || props.copyable);
const boxStyle = computed(() => (props.maxHeight ? { maxHeight: props.maxHeight } : undefined));

function copy(): void {
  if (!props.code || typeof navigator === "undefined" || !navigator.clipboard?.writeText) {
    emit("copy", false);
    return;
  }
  navigator.clipboard.writeText(props.code).then(
    () => emit("copy", true),
    () => emit("copy", false),
  );
}
</script>

<template>
  <div class="flare-code-block" :class="{ 'is-wrapped': wrap }">
    <div v-if="hasHead" class="flare-code-block__head">
      <span class="flare-code-block__language">{{ language }}</span>
      <FlareIconButton
        v-if="copyable"
        class="flare-code-block__copy"
        :icon="flareIcons.copy"
        :ariaLabel="t('codeBlock.copy')"
        :disabled="!code"
        size="sm"
        shape="square"
        @click="copy"
      />
    </div>
    <!-- The box scrolls on its own, so a keyboard reaches it: it is a named, focusable region. -->
    <pre class="flare-code-block__box" role="region" tabindex="0" :aria-label="name" :style="boxStyle"><code class="flare-code-block__code">{{ code }}</code></pre>
  </div>
</template>

<style scoped>
.flare-code-block {
  display: flex;
  flex-direction: column;
  min-width: 0;
  overflow: hidden;
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-secondary);
}
.flare-code-block__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--flare-size-spacing-sm);
  min-height: var(--flare-size-layout-control-height-sm);
  padding-inline: var(--flare-size-spacing-md) var(--flare-size-spacing-xs);
  border-bottom: 1px solid var(--flare-color-border-secondary);
}
.flare-code-block__language {
  min-width: 0;
  overflow: hidden;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-text-caption-font-size);
  line-height: var(--flare-text-caption-line-height);
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-code-block__box {
  min-width: 0;
  max-height: var(--flare-component-code-block-max-height);
  margin: 0;
  padding: var(--flare-size-spacing-md);
  overflow: auto;
  overscroll-behavior: contain;
  color: var(--flare-color-text-primary);
  font-family: var(--flare-component-font-family-mono);
  font-size: var(--flare-size-font-size-sm);
  line-height: var(--flare-size-line-height-normal);
  tab-size: 2;
  white-space: pre;
}
.flare-code-block.is-wrapped .flare-code-block__box {
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}
.flare-code-block__code { font: inherit; }
.flare-code-block__box:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: -2px;
}
</style>
