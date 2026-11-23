<script setup lang="ts">
import { computed } from "vue";
import { flareCountBadgeText } from "../../shared/contracts/count-badge";

/**
 * The unread pill: a tab's, a navigation item's or a row's count of unread things, in the primary colour with
 * tabular digits, capped at 99+ (`flareCountBadgeText`, spec/count-badge-vectors.json). `more` says there are more
 * than `count` (the server counted one page) and reads 99+ whatever the count. Nothing is drawn for a count of 0
 * unless `dot` (a small marker with no number) or `more` is set. `quiet` is the muted look of a conversation the
 * viewer silenced. The same contract as the Flutter kit's FlareUnreadBadge.
 */
const props = withDefaults(defineProps<{
  count: number;
  /** A marker with no number when the count is 0 (a new item, a row that is unread). */
  dot?: boolean;
  /** The muted look: a neutral surface instead of the primary colour. */
  quiet?: boolean;
  /** There are more than `count`: the badge reads 99+. */
  more?: boolean;
  /** The highest count drawn as a number; above it the badge reads `{maxCount}+`. The shared contract caps at 99. */
  maxCount?: number;
}>(), { dot: false, quiet: false, more: false, maxCount: 99 });

const value = computed(() => (Number.isFinite(props.count) ? Math.max(0, Math.trunc(props.count)) : 0));
const cap = computed(() => (Number.isFinite(props.maxCount) && props.maxCount >= 1 ? Math.trunc(props.maxCount) : 99));
/** `number` draws the pill, `dot` the marker, `none` nothing. */
const shape = computed<"number" | "dot" | "none">(() => {
  if (props.more || value.value > 0) return "number";
  return props.dot ? "dot" : "none";
});
const text = computed(() => {
  if (cap.value === 99) return flareCountBadgeText(value.value, props.more);
  return props.more || value.value > cap.value ? `${cap.value}+` : String(value.value);
});
</script>

<template>
  <span
    v-if="shape === 'number'"
    class="flare-unread-badge"
    :class="{ 'flare-unread-badge--quiet': quiet }"
    data-shape="number"
  >{{ text }}</span>
  <span
    v-else-if="shape === 'dot'"
    class="flare-unread-badge flare-unread-badge--dot"
    aria-hidden="true"
    data-shape="dot"
  />
</template>

<style scoped>
/* The same pill as the conversation row's unread count and the navigation badge: primary fill, the outgoing
   bubble's foreground for the digits, a quiet neutral variant for a silenced conversation. */
.flare-unread-badge {
  display: inline-flex;
  flex: none;
  align-items: center;
  justify-content: center;
  box-sizing: border-box;
  min-width: var(--flare-size-icon-size-md);
  height: var(--flare-size-icon-size-md);
  padding-inline: var(--flare-size-spacing-2xs);
  border-radius: var(--flare-size-radius-full);
  background: var(--flare-color-primary);
  color: var(--flare-color-message-outgoing-foreground);
  font-size: var(--flare-size-font-size-xs);
  font-weight: 600;
  line-height: 1;
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}
.flare-unread-badge--quiet {
  background: var(--flare-color-bg-tertiary);
  color: var(--flare-color-text-secondary);
}
.flare-unread-badge--dot {
  min-width: 0;
  width: var(--flare-size-spacing-sm);
  height: var(--flare-size-spacing-sm);
  padding: 0;
}
/* Forced colours drop the fill: an outline keeps the pill and the dot visible. */
@media (forced-colors: active) {
  .flare-unread-badge { border: 1px solid CanvasText; }
}
</style>
