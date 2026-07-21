<script setup lang="ts">
import { NIcon } from "naive-ui";
import { ChevronBackOutline } from "../../shared/icon-glyphs";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

/**
 * Chat header — a transparent bar (no filled surface) that blends into the chat
 * canvas. When `back` is set, a leading back button sits to the LEFT of the
 * identity avatar; hosts wire `@back` to their navigation.
 */
withDefaults(defineProps<{ back?: boolean }>(), { back: false });
const emit = defineEmits<{ (event: "back"): void }>();
const { t } = useFlareI18n();
</script>

<template>
  <header class="im-chat-header">
    <button
      v-if="back"
      type="button"
      class="im-chat-header__back"
      :title="t('common.back')"
      :aria-label="t('common.back')"
      @click="emit('back')"
    >
      <n-icon :size="22" :component="ChevronBackOutline" />
    </button>
    <div class="im-chat-header__identity">
      <slot name="identity" />
    </div>
    <div class="im-chat-header__actions">
      <slot name="actions" />
    </div>
  </header>
</template>

<style scoped>
.im-chat-header {
  display: flex;
  align-items: center;
  gap: 8px;
  min-height: var(--layout-header, 60px);
  min-width: 0;
  padding: 8px 12px;
  /* No filled surface — the header blends into the chat canvas (no white bar). */
  background: transparent;
  border-bottom: none;
  box-shadow: none;
}

.im-chat-header__back {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex: 0 0 auto;
  width: 36px;
  height: 36px;
  margin: 0 -2px 0 -4px;
  padding: 0;
  border: 0;
  border-radius: 10px;
  color: var(--im-chat-hdr-title, var(--flare-color-text-primary, #111318));
  background: transparent;
  cursor: pointer;
  transition: background var(--im-motion-fast, 140ms ease), color var(--im-motion-fast, 140ms ease);
}

.im-chat-header__back:hover {
  color: var(--im-brand-primary, var(--flare-color-primary, #7c3aed));
  background: color-mix(in srgb, var(--im-brand-primary) 10%, transparent);
}

.im-chat-header__identity {
  display: flex;
  align-items: center;
  min-width: 0;
  flex: 1;
}

.im-chat-header__actions {
  display: flex;
  align-items: center;
  gap: 4px;
  flex-shrink: 0;
}

@media (min-width: 900px) {
  .im-chat-header {
    min-height: 62px;
    padding-inline: 16px;
  }
}
</style>
