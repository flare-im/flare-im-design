<script setup lang="ts">
import { ref } from "vue";
import { NIcon } from "naive-ui";
import { flareIcons } from "../../shared/icons";
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
      <n-icon aria-hidden="true" :size="14" :component="flareIcons.translate" class="is-spin" />{{ t("translation.translating") }}
    </p>
    <template v-else>
      <p class="flare-translation__text">{{ translated }}</p>
      <div class="flare-translation__footer">
        <span class="flare-translation__by">
          <n-icon aria-hidden="true" :size="12" :component="flareIcons.translate" />
          {{ provider ? t("translation.byProvider", { provider }) : t("translation.by") }}
        </span>
        <button
          v-if="original"
          type="button"
          class="flare-translation__toggle"
          @click="showOriginal = !showOriginal"
        >
          {{ showOriginal ? t("translation.hideOriginal") : t("translation.showOriginal") }}
          <n-icon aria-hidden="true" :size="12" :component="flareIcons['chevron-down']" :class="{ 'is-up': showOriginal }" />
        </button>
      </div>
      <p v-if="original && showOriginal" class="flare-translation__original">{{ original }}</p>
    </template>
  </div>
</template>

<style scoped>
.flare-translation {
  border-left: 2px solid color-mix(in srgb, var(--flare-color-primary) 40%, transparent);
  padding: 6px 0 2px var(--flare-size-spacing-2sm);
  margin-top: 4px;
}
.flare-translation__text {
  margin: 0;
  font-size: 14px;
  line-height: 1.5;
  color: var(--flare-color-text-primary);
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}
.flare-translation__footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--flare-size-spacing-2sm);
  margin-top: 5px;
}
.flare-translation__by {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  color: var(--flare-color-text-tertiary);
}
.flare-translation__toggle {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  border: none;
  background: transparent;
  color: var(--flare-color-primary-text);
  font-size: 11px;
  cursor: pointer;
  padding: 0;
}
.flare-translation__toggle .is-up { transform: rotate(180deg); }
.flare-translation__original {
  margin: 6px 0 0;
  padding-top: 6px;
  border-top: 1px dashed var(--flare-color-border-primary);
  font-size: 13px;
  line-height: 1.5;
  color: var(--flare-color-text-secondary);
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}
.flare-translation__pending {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  margin: 0;
  font-size: 13px;
  color: var(--flare-color-text-tertiary);
}
.is-spin { animation: flare-translation-spin 0.9s linear infinite; }
@media (prefers-reduced-motion: reduce) {
  .is-spin { animation: none; }
}
@keyframes flare-translation-spin {
  to { transform: rotate(360deg); }
}
</style>
