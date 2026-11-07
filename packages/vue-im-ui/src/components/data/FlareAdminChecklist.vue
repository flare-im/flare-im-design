<script lang="ts">
/** `unknown` is its own state: a check that could not run is neither a pass nor a failure. */
export type FlareAdminCheckStatus = "pass" | "fail" | "unknown";
export interface FlareAdminCheckItem {
  id: string;
  title: string;
  status: FlareAdminCheckStatus;
  /** The state in words; icon and colour never carry it alone. */
  statusText: string;
  /** One line on why the check ended this way. */
  description?: string;
  /** What the check found, one line each. */
  details?: readonly string[];
}
</script>

<script setup lang="ts">
/** Pre-flight results as a read-only list. The host runs the checks and words every line. */
import { Check, CircleHelp, X } from "@lucide/vue";

defineProps<{
  /** Names the list for assistive technology. */
  label: string;
  items: readonly FlareAdminCheckItem[];
}>();
const icons = { pass: Check, fail: X, unknown: CircleHelp };
</script>

<template>
  <ul class="flare-admin-checklist" :aria-label="label">
    <li
      v-for="item in items"
      :key="item.id"
      class="flare-admin-checklist__item"
      :class="`flare-admin-checklist__item--${item.status}`"
    >
      <span class="flare-admin-checklist__mark" aria-hidden="true">
        <component :is="icons[item.status]" :size="14" :stroke-width="2.5" />
      </span>
      <div class="flare-admin-checklist__body">
        <div class="flare-admin-checklist__head">
          <span class="flare-admin-checklist__title">{{ item.title }}</span>
          <span class="flare-admin-checklist__status">{{ item.statusText }}</span>
        </div>
        <p v-if="item.description" class="flare-admin-checklist__description">
          {{ item.description }}
        </p>
        <ul v-if="item.details?.length" class="flare-admin-checklist__details">
          <li v-for="(detail, index) in item.details" :key="index">{{ detail }}</li>
        </ul>
      </div>
    </li>
  </ul>
</template>

<style scoped>
.flare-admin-checklist {
  display: grid;
  gap: var(--flare-size-spacing-sm);
  margin: 0;
  padding: 0;
  list-style: none;
  min-width: 0;
}
.flare-admin-checklist__item {
  display: flex;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
}
.flare-admin-checklist__mark {
  display: inline-flex;
  flex: none;
  align-items: center;
  justify-content: center;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  color: var(--flare-color-text-secondary);
  background: var(--flare-color-bg-secondary);
}
.flare-admin-checklist__item--pass .flare-admin-checklist__mark {
  color: var(--flare-color-success-text);
}
.flare-admin-checklist__item--fail .flare-admin-checklist__mark {
  color: var(--flare-color-error-text);
}
.flare-admin-checklist__item--unknown .flare-admin-checklist__mark {
  color: var(--flare-color-warning-text);
}
.flare-admin-checklist__body {
  flex: 1;
  min-width: 0;
}
.flare-admin-checklist__head {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  justify-content: space-between;
  gap: var(--flare-size-spacing-sm);
}
.flare-admin-checklist__title {
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-text-primary);
  overflow-wrap: anywhere;
}
.flare-admin-checklist__status {
  flex: none;
  font-size: var(--flare-text-caption-font-size);
  font-weight: var(--flare-size-font-weight-semibold);
  color: var(--flare-color-text-secondary);
}
.flare-admin-checklist__item--pass .flare-admin-checklist__status {
  color: var(--flare-color-success-text);
}
.flare-admin-checklist__item--fail .flare-admin-checklist__status {
  color: var(--flare-color-error-text);
}
.flare-admin-checklist__item--unknown .flare-admin-checklist__status {
  color: var(--flare-color-warning-text);
}
.flare-admin-checklist__description,
.flare-admin-checklist__details {
  margin: var(--flare-size-spacing-xs) 0 0;
  font-size: var(--flare-text-caption-font-size);
  line-height: var(--flare-size-line-height-relaxed);
  color: var(--flare-color-text-secondary);
  overflow-wrap: anywhere;
}
.flare-admin-checklist__details {
  padding-inline-start: var(--flare-size-spacing-lg);
}
</style>
