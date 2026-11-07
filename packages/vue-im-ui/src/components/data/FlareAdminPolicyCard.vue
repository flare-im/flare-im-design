<script setup lang="ts">
import { NCard, useThemeVars } from "naive-ui";

/** Presentation only: the host owns controls, authorization and write protection. */
withDefaults(
  defineProps<{
    title: string;
    description?: string;
    source?: string;
    sourceDetail?: string;
    paused?: boolean;
    density?: "normal" | "compact";
  }>(),
  { density: "normal" },
);
const theme = useThemeVars();
</script>

<template>
  <NCard
    size="small"
    role="article"
    :aria-label="title"
    class="flare-admin-policy-card"
    :class="{
      'flare-admin-policy-card--compact': density === 'compact',
      'flare-admin-policy-card--paused': paused,
    }"
    :style="{
      '--flare-policy-muted': theme.textColor3,
      '--flare-policy-icon-bg': theme.actionColor,
      ...(paused ? { background: theme.actionColor } : {}),
    }"
    :content-style="{
      display: 'flex',
      flexDirection: 'column',
      minWidth: '0',
      gap:
        density === 'compact'
          ? 'var(--flare-size-spacing-xs, 4px)'
          : 'var(--flare-size-spacing-sm, 8px)',
      padding: density === 'compact' ? '8px 12px' : '12px 14px',
    }"
  >
    <header class="flare-admin-policy-card__header">
      <span
        v-if="$slots.icon"
        class="flare-admin-policy-card__icon"
        aria-hidden="true"
        ><slot name="icon"
      /></span>
      <h3 :title="density === 'compact' ? description : undefined">
        {{ title }}
      </h3>
      <div v-if="$slots.control" class="flare-admin-policy-card__control">
        <slot name="control" />
      </div>
    </header>
    <p
      v-if="description && density !== 'compact'"
      class="flare-admin-policy-card__description"
      :title="description"
    >
      {{ description }}
    </p>
    <div v-if="$slots.default" class="flare-admin-policy-card__body">
      <slot />
    </div>
    <footer
      v-if="source || sourceDetail || $slots.actions"
      class="flare-admin-policy-card__footer"
    >
      <div
        v-if="source || sourceDetail"
        class="flare-admin-policy-card__source"
      >
        <span v-if="source">{{ source }}</span>
        <span
          v-if="sourceDetail"
          class="flare-admin-policy-card__source-detail"
          >{{ sourceDetail }}</span
        >
      </div>
      <div v-if="$slots.actions" class="flare-admin-policy-card__actions">
        <slot name="actions" />
      </div>
    </footer>
  </NCard>
</template>

<style scoped>
.flare-admin-policy-card {
  min-width: 0;
}
.flare-admin-policy-card__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--flare-size-spacing-sm);
  min-height: 30px;
}
.flare-admin-policy-card__icon {
  display: grid;
  place-items: center;
  flex: none;
  width: 36px;
  height: 36px;
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-policy-icon-bg);
}
.flare-admin-policy-card__header h3 {
  flex: 1;
  font-size: 14px;
  line-height: 1.45;
  font-weight: 600;
  margin: 0;
  min-width: 0;
  overflow-wrap: anywhere;
}
.flare-admin-policy-card__control {
  display: flex;
  align-items: center;
  flex: none;
  min-width: 0;
  max-width: 60%;
  min-height: 30px;
}
.flare-admin-policy-card__description {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  color: var(--flare-policy-muted);
  font-size: 12px;
  line-height: 1.6;
  margin: 0;
}
.flare-admin-policy-card__body {
  min-width: 0;
}
.flare-admin-policy-card__body:empty {
  display: none;
}
.flare-admin-policy-card__footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 4px 8px;
  margin-top: auto;
}
.flare-admin-policy-card__source {
  display: flex;
  flex-wrap: wrap;
  gap: 4px 8px;
  color: var(--flare-policy-muted);
  font-size: 11px;
  line-height: 1.5;
}
.flare-admin-policy-card__source-detail {
  font-weight: 500;
}
.flare-admin-policy-card__actions {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 4px 8px;
}
.flare-admin-policy-card__actions :deep(.n-button) {
  font-size: 12px;
  min-height: 32px;
}
@media (pointer: coarse), (max-width: 600px) {
  .flare-admin-policy-card:not(.flare-admin-policy-card--compact)
    .flare-admin-policy-card__control,
  .flare-admin-policy-card:not(.flare-admin-policy-card--compact)
    .flare-admin-policy-card__actions
    :deep(.n-button) {
    min-height: 44px;
  }
}
</style>
