<script setup lang="ts">
import { ref } from "vue";
import { NIcon } from "naive-ui";
import { LanguageOutline, ChevronDownOutline } from "../../shared/icon-glyphs";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    /** The translated result shown prominently. */
    translated: string;
    /** The source text — revealed via the toggle. */
    original?: string;
    /** Attribution, e.g. "DeepL" / "Google". */
    provider?: string;
    /** Loading state while the translation is in flight. */
    pending?: boolean;
  }>(),
  { pending: false },
);
const { t } = useFlareI18n();
const showOriginal = ref(false);
</script>

<template>
  <div class="flare-translation" :class="{ 'is-pending': pending }">
    <p v-if="pending" class="flare-translation__pending">
      <n-icon :size="14" :component="LanguageOutline" class="is-spin" />{{ t("translation.translating") }}
    </p>
    <template v-else>
      <p class="flare-translation__text">{{ translated }}</p>
      <div class="flare-translation__footer">
        <span class="flare-translation__by">
          <n-icon :size="12" :component="LanguageOutline" />
          {{ provider ? t("translation.byProvider", { provider }) : t("translation.by") }}
        </span>
        <button
          v-if="original"
          type="button"
          class="flare-translation__toggle"
          @click="showOriginal = !showOriginal"
        >
          {{ showOriginal ? t("translation.hideOriginal") : t("translation.showOriginal") }}
          <n-icon :size="12" :component="ChevronDownOutline" :class="{ 'is-up': showOriginal }" />
        </button>
      </div>
      <p v-if="original && showOriginal" class="flare-translation__original">{{ original }}</p>
    </template>
  </div>
</template>

<style scoped>
.flare-translation {
  border-left: 2px solid color-mix(in srgb, var(--flare-color-primary, #7c3aed) 40%, transparent);
  padding: 6px 0 2px 10px;
  margin-top: 4px;
}
.flare-translation__text {
  margin: 0;
  font-size: 14px;
  line-height: 1.5;
  color: var(--flare-color-text-primary, #15131c);
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}
.flare-translation__footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  margin-top: 5px;
}
.flare-translation__by {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  color: var(--flare-color-text-tertiary, #a7a2b4);
}
.flare-translation__toggle {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  border: none;
  background: transparent;
  color: var(--flare-color-primary, #7c3aed);
  font-size: 11px;
  cursor: pointer;
  padding: 0;
}
.flare-translation__toggle .is-up { transform: rotate(180deg); }
.flare-translation__original {
  margin: 6px 0 0;
  padding-top: 6px;
  border-top: 1px dashed var(--flare-color-border-primary, #e9e6f1);
  font-size: 13px;
  line-height: 1.5;
  color: var(--flare-color-text-secondary, #6b6780);
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}
.flare-translation__pending {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  margin: 0;
  font-size: 13px;
  color: var(--flare-color-text-tertiary, #a7a2b4);
}
.is-spin { animation: flare-translation-spin 0.9s linear infinite; }
@media (prefers-reduced-motion: reduce) {
  .is-spin { animation: none; }
}
@keyframes flare-translation-spin {
  to { transform: rotate(360deg); }
}
</style>
