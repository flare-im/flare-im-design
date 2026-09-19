<script setup lang="ts">
import { computed } from "vue";
import { NIcon } from "naive-ui";
import { TerminalOutline } from "../../shared/icon-glyphs";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareSlashCommand } from "../../shared/contracts";

const props = withDefaults(
  defineProps<{
    commands: FlareSlashCommand[];
    /** Current typed token (without the leading "/") — filters the list. */
    query?: string;
  }>(),
  { query: "" },
);
const emit = defineEmits<{
  (e: "select", command: FlareSlashCommand): void;
  (e: "close"): void;
}>();

const { t } = useFlareI18n();
const filtered = computed(() => {
  const q = props.query.trim().toLowerCase().replace(/^\//, "");
  if (!q) return props.commands;
  return props.commands.filter(
    (c) => c.command.toLowerCase().includes(q) || c.description?.toLowerCase().includes(q),
  );
});
</script>

<template>
  <div class="flare-slash-menu" role="listbox" :aria-label="t('slash.title')">
    <div class="flare-slash-menu__head">
      <n-icon aria-hidden="true" :size="13" :component="TerminalOutline" />{{ t("slash.title") }}
    </div>
    <button
      v-for="cmd in filtered"
      :key="cmd.command"
      type="button"
      role="option"
      class="flare-slash-menu__row"
      @click="emit('select', cmd)"
    >
      <span class="flare-slash-menu__cmd">/{{ cmd.command }}</span>
      <span v-if="cmd.hint" class="flare-slash-menu__hint">{{ cmd.hint }}</span>
      <span v-if="cmd.description" class="flare-slash-menu__desc">{{ cmd.description }}</span>
    </button>
    <div v-if="filtered.length === 0" class="flare-slash-menu__empty">{{ t("slash.empty") }}</div>
  </div>
</template>

<style scoped>
.flare-slash-menu {
  width: 300px;
  max-width: 100%;
  padding: 6px;
  border-radius: var(--flare-size-radius-xl);
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-primary);
  box-shadow: var(--flare-shadow-lg);
  max-height: 280px;
  overflow-y: auto;
}
.flare-slash-menu__head {
  display: flex;
  align-items: center;
  gap: 5px;
  padding: 6px 8px 4px;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--flare-color-text-tertiary);
}
.flare-slash-menu__row {
  width: 100%;
  display: grid;
  grid-template-columns: auto 1fr;
  align-items: baseline;
  gap: 4px 8px;
  padding: 8px 10px;
  border: none;
  border-radius: var(--flare-size-radius-lg);
  background: transparent;
  cursor: pointer;
  text-align: left;
  transition: background var(--flare-transition-fast);
}
.flare-slash-menu__row:hover { background: var(--flare-color-bg-secondary); }
.flare-slash-menu__cmd {
  font-family: var(--flare-component-font-family-mono);
  font-size: 13px;
  font-weight: 600;
  color: var(--flare-color-primary-text);
}
.flare-slash-menu__hint {
  font-size: 12px;
  color: var(--flare-color-text-tertiary);
  font-family: var(--flare-component-font-family-mono);
}
.flare-slash-menu__desc {
  grid-column: 1 / -1;
  font-size: 12px;
  color: var(--flare-color-text-secondary);
  line-height: 1.4;
}
.flare-slash-menu__empty {
  padding: 14px;
  text-align: center;
  font-size: 13px;
  color: var(--flare-color-text-tertiary);
}
</style>
