<script setup lang="ts">
import { computed } from "vue";
import { NIcon } from "naive-ui";
import { ReturnUpBackOutline } from "../../shared/icon-glyphs";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

// The quoted reply at the top of a card shell (spec/message-surface-vectors.json rules.cardShell): one line with the
// quoted summary, a button when a tap reaches the quoted message. Inside the shell, so a card never falls back into a
// bubble because it replies to something.
const props = defineProps<{ preview: string; locate?: () => void }>();
const { t } = useFlareI18nOptional();
const text = computed(() => props.preview.trim() || t("preview.message"));
</script>

<template>
  <button v-if="locate" type="button" class="message-card-quote is-clickable" data-card-quote="true" @click.stop="locate()">
    <n-icon aria-hidden="true" :component="ReturnUpBackOutline" />
    <span class="message-card-quote__text">{{ text }}</span>
  </button>
  <div v-else class="message-card-quote" data-card-quote="true">
    <n-icon aria-hidden="true" :component="ReturnUpBackOutline" />
    <span class="message-card-quote__text">{{ text }}</span>
  </div>
</template>

<style scoped>
.message-card-quote {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
  width: 100%;
  min-width: 0;
  box-sizing: border-box;
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-sm);
  border: 0;
  border-inline-start: 3px solid var(--flare-color-border-selected);
  border-radius: 0 var(--flare-size-radius-sm) var(--flare-size-radius-sm) 0;
  background: var(--flare-color-bg-tertiary);
  color: var(--flare-color-text-secondary);
  font: inherit;
  font-size: var(--flare-size-font-size-sm);
  text-align: start;
}
.message-card-quote.is-clickable { cursor: pointer; }
.message-card-quote:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.message-card-quote__text { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
</style>
