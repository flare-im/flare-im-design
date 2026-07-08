<script setup lang="ts">
import { computed, ref } from "vue";
import { ChevronDownOutline, ChevronForwardOutline, ChevronUpOutline } from "@vicons/ionicons5";
import { NIcon } from "naive-ui";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareBusinessDetailRow } from "../../shared/contracts/message";

const props = withDefaults(
  defineProps<{
    title?: string;
    subtitle?: string;
    statusLabel?: string;
    statusTone?: "default" | "success" | "warning" | "danger" | "info";
    rows?: FlareBusinessDetailRow[];
    actionLabel?: string;
    actionDisabled?: boolean;
    actionReason?: string;
    collapsible?: boolean;
    defaultExpanded?: boolean;
  }>(),
  {
    title: "",
    subtitle: "",
    statusLabel: "",
    statusTone: "default",
    rows: () => [],
    actionLabel: "",
    actionDisabled: false,
    actionReason: "",
    collapsible: true,
    defaultExpanded: false,
  },
);

const emit = defineEmits<{
  (event: "action"): void;
}>();

const { t } = useFlareI18n();
const expanded = ref(props.defaultExpanded || !props.collapsible);

const visibleRows = computed(() => {
  if (!props.collapsible || expanded.value) return props.rows;
  return props.rows.slice(0, 2);
});
const hasFooter = computed(() => (props.collapsible && props.rows.length > 2) || Boolean(props.actionLabel));
const hasPrimaryContent = computed(() => Boolean(props.title || props.statusLabel || visibleRows.value.length));

function toggleExpanded(): void {
  if (!props.collapsible || props.rows.length <= 2) return;
  expanded.value = !expanded.value;
}
</script>

<template>
  <section class="business-detail-block" :class="`business-detail-block--status-${statusTone}`">
    <header v-if="title || statusLabel" class="business-detail-block__header">
      <div class="business-detail-block__titles">
        <strong v-if="title">{{ title }}</strong>
        <span v-if="subtitle" class="business-detail-block__subtitle">{{ subtitle }}</span>
      </div>
      <span v-if="statusLabel" class="business-detail-block__status">{{ statusLabel }}</span>
    </header>

    <dl v-if="visibleRows.length" class="business-detail-block__rows">
      <div v-for="row in visibleRows" :key="row.key" class="business-detail-block__row">
        <dt>{{ row.label }}</dt>
        <dd :class="row.tone ? `is-${row.tone}` : undefined">{{ row.value }}</dd>
      </div>
    </dl>

    <footer
      v-if="hasFooter"
      class="business-detail-block__footer"
      :class="{ 'business-detail-block__footer--flush': !hasPrimaryContent }"
    >
      <button
        v-if="collapsible && rows.length > 2"
        class="business-detail-block__toggle"
        type="button"
        @click="toggleExpanded"
      >
        <span>{{ expanded ? t("business.collapse") : t("business.expand") }}</span>
        <n-icon :component="expanded ? ChevronUpOutline : ChevronDownOutline" />
      </button>
      <button
        v-if="actionLabel"
        class="business-detail-block__action"
        type="button"
        :disabled="actionDisabled"
        :title="actionDisabled ? actionReason : undefined"
        @click="emit('action')"
      >
        <span>{{ actionLabel }}</span>
        <n-icon :component="ChevronForwardOutline" />
      </button>
    </footer>
  </section>
</template>

<style scoped>
.business-detail-block {
  margin: 0;
  padding: 0 12px 11px;
  background: transparent;
}

.business-detail-block__header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 8px;
  margin-bottom: 8px;
  padding-top: 1px;
}

.business-detail-block__titles strong {
  display: block;
  font-size: 13px;
  color: var(--im-text-primary, var(--text-primary));
}

.business-detail-block__subtitle {
  display: block;
  margin-top: 2px;
  font-size: 12px;
  color: var(--im-text-secondary, var(--text-secondary));
}

.business-detail-block__status {
  flex-shrink: 0;
  padding: 2px 8px;
  border-radius: 999px;
  font-size: 11px;
  font-weight: 600;
  color: var(--im-text-secondary, var(--text-secondary));
  background: color-mix(in srgb, var(--im-bg-surface, var(--bg-tertiary)) 76%, transparent);
}

.business-detail-block--status-success .business-detail-block__status {
  color: var(--success);
  background: rgba(34, 197, 94, 0.12);
}

.business-detail-block--status-warning .business-detail-block__status {
  color: var(--warning);
  background: rgba(245, 158, 11, 0.12);
}

.business-detail-block--status-danger .business-detail-block__status {
  color: var(--error);
  background: rgba(239, 68, 68, 0.12);
}

.business-detail-block--status-info .business-detail-block__status {
  color: var(--info);
  background: rgba(47, 107, 255, 0.12);
}

.business-detail-block__rows {
  display: grid;
  margin: 0;
  overflow: hidden;
  border: 1px solid color-mix(in srgb, var(--im-border, #d7dce5) 54%, transparent);
  border-radius: 8px;
  background: color-mix(in srgb, var(--im-bg-surface-alt, #f4f6fb) 44%, var(--im-bg-surface, #fff));
}

.business-detail-block__row {
  display: grid;
  grid-template-columns: minmax(58px, 0.34fr) minmax(0, 1fr);
  gap: 10px;
  align-items: start;
  padding: 8px 9px;
  border-top: 1px solid color-mix(in srgb, var(--im-border, #d7dce5) 30%, transparent);
}

.business-detail-block__row:first-child {
  border-top: 0;
}

.business-detail-block__row dt {
  margin: 0;
  font-size: 11px;
  line-height: 1.4;
  white-space: nowrap;
  color: var(--im-text-tertiary, var(--text-tertiary));
}

.business-detail-block__row dd {
  margin: 0;
  font-size: 12px;
  line-height: 1.4;
  color: var(--im-text-primary, var(--text-primary));
  overflow-wrap: anywhere;
}

.business-detail-block__row dd.is-success {
  color: var(--success);
}

.business-detail-block__row dd.is-warning {
  color: var(--warning);
}

.business-detail-block__row dd.is-danger {
  color: var(--error);
}

.business-detail-block__row dd.is-info {
  color: var(--info);
}

.business-detail-block__footer {
  display: flex;
  align-items: center;
  min-height: 38px;
  margin: 10px -12px -11px;
  overflow: hidden;
  border-top: 1px solid color-mix(in srgb, var(--im-border, #d7dce5) 56%, transparent);
  background: color-mix(in srgb, var(--im-bg-surface-alt, #f4f6fb) 42%, var(--im-bg-surface, #fff));
}

.business-detail-block__footer--flush {
  margin-top: 0;
}

.business-detail-block__toggle,
.business-detail-block__action {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  min-width: 0;
  height: 38px;
  padding: 0 12px;
  border: 0;
  color: var(--im-text-secondary, var(--text-secondary));
  background: transparent;
  cursor: pointer;
  font: inherit;
  font-size: 12px;
  font-weight: 600;
  line-height: 1;
  transition:
    color var(--im-motion-fast, 140ms ease),
    background var(--im-motion-fast, 140ms ease);
}

.business-detail-block__toggle {
  flex: 0 0 auto;
  border-right: 1px solid color-mix(in srgb, var(--im-border, #d7dce5) 46%, transparent);
}

.business-detail-block__action {
  flex: 1 1 auto;
  justify-content: flex-end;
  color: color-mix(in srgb, var(--im-primary, #7c3aed) 88%, var(--im-text-primary, #111827));
}

.business-detail-block__toggle:hover,
.business-detail-block__toggle:focus-visible,
.business-detail-block__action:hover,
.business-detail-block__action:focus-visible {
  background: color-mix(in srgb, var(--im-primary, #7c3aed) 6%, transparent);
  outline: none;
}

.business-detail-block__action:disabled {
  color: var(--im-text-tertiary, var(--text-tertiary));
  cursor: not-allowed;
  opacity: 0.68;
}

.business-detail-block__toggle .n-icon,
.business-detail-block__action .n-icon {
  flex: 0 0 auto;
  font-size: 14px;
}
</style>
