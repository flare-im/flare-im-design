<script setup lang="ts">
import { ref, computed } from "vue";
import { NIcon } from "naive-ui";
import { MegaphoneOutline, ChevronDownOutline, CloseOutline } from "../../shared/icon-glyphs";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    text: string;
    /** Optional author line ("Posted by Ivy"). */
    author?: string;
    /** Collapse long text to one line with an expand toggle. */
    collapsible?: boolean;
    /** Show the dismiss control. */
    dismissible?: boolean;
  }>(),
  { collapsible: true, dismissible: false },
);
const emit = defineEmits<{ (e: "close"): void }>();

const { t } = useFlareI18n();
const expanded = ref(false);
const showToggle = computed(() => props.collapsible && props.text.length > 40);
</script>

<template>
  <div class="flare-announcement">
    <span class="flare-announcement__icon"><n-icon :size="16" :component="MegaphoneOutline" /></span>
    <div class="flare-announcement__body">
      <div class="flare-announcement__label">
        {{ t("announcement.title") }}
        <span v-if="author" class="flare-announcement__author">· {{ author }}</span>
      </div>
      <p class="flare-announcement__text" :class="{ 'is-clamped': showToggle && !expanded }">{{ text }}</p>
      <button
        v-if="showToggle"
        type="button"
        class="flare-announcement__toggle"
        @click="expanded = !expanded"
      >
        {{ expanded ? t("announcement.collapse") : t("announcement.expand") }}
        <n-icon :size="13" :component="ChevronDownOutline" :class="{ 'is-up': expanded }" />
      </button>
    </div>
    <button
      v-if="dismissible"
      type="button"
      class="flare-announcement__close"
      :aria-label="t('announcement.close')"
      @click="emit('close')"
    >
      <n-icon :size="16" :component="CloseOutline" />
    </button>
  </div>
</template>

<style scoped>
.flare-announcement {
  display: flex;
  gap: 10px;
  padding: 11px 12px;
  border-radius: var(--flare-size-radius-lg, 12px);
  background: var(--flare-color-bg-selected, #f1eaff);
  border: 1px solid color-mix(in srgb, var(--flare-color-primary, #7c3aed) 22%, transparent);
}
.flare-announcement__icon {
  flex: 0 0 auto;
  width: 26px;
  height: 26px;
  border-radius: 8px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  background: var(--im-brand-gradient, var(--flare-color-primary, #7c3aed));
}
.flare-announcement__body { flex: 1; min-width: 0; }
.flare-announcement__label {
  font-size: 12px;
  font-weight: 600;
  color: var(--flare-color-primary, #7c3aed);
}
.flare-announcement__author {
  font-weight: 400;
  color: var(--flare-color-text-tertiary, #a7a2b4);
}
.flare-announcement__text {
  margin: 3px 0 0;
  font-size: 13px;
  line-height: 1.5;
  color: var(--flare-color-text-primary, #15131c);
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}
.flare-announcement__text.is-clamped {
  display: -webkit-box;
  -webkit-line-clamp: 1;
  line-clamp: 1;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.flare-announcement__toggle {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  margin-top: 4px;
  border: none;
  background: transparent;
  color: var(--flare-color-primary, #7c3aed);
  font-size: 12px;
  cursor: pointer;
  padding: 0;
}
.flare-announcement__toggle .is-up { transform: rotate(180deg); }
.flare-announcement__close {
  flex: 0 0 auto;
  align-self: flex-start;
  border: none;
  background: transparent;
  color: var(--flare-color-text-tertiary, #a7a2b4);
  cursor: pointer;
  display: inline-flex;
}
</style>
