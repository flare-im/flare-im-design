<script setup lang="ts">
// The host supplies the invitation snapshot and handles clipboard and navigation.
// The panel renders the invite QR locally.
import { computed } from "vue";
import FlareInviteeRow from "./FlareInviteeRow.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareQrMatrix from "./FlareQrMatrix.vue";
import {
  referralDepthRows,
  type FlareInvitee,
  type FlareLoadInviteChildren,
  type FlareReferralStats,
} from "../../shared/contracts/invite";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    /** The person's invite code; empty while the host has none yet. */
    code: string;
    /** Host-validated registration link encoded in the QR. */
    shareUrl?: string;
    /** Referral counts per depth; omitted while unknown. */
    stats?: FlareReferralStats | null;
    /** Depth rows to show (1–3). */
    maxDepthShown?: number;
    /** Direct invitees loaded so far. */
    invitees: FlareInvitee[];
    /** Loads one authorized page for an expanded user. */
    onLoadChildren?: FlareLoadInviteChildren;
    /** Whether the operator permits viewing invite relationships. */
    showProfiles?: boolean;
    hasMore?: boolean;
    loadingMore?: boolean;
    /** First load in flight — skeleton, never a fake empty list. */
    loading?: boolean;
    title?: string;
    showTitle?: boolean;
  }>(),
  {
    shareUrl: "",
    stats: null,
    maxDepthShown: 3,
    showProfiles: true,
    hasMore: false,
    loadingMore: false,
    loading: false,
    title: undefined,
    showTitle: true,
  },
);
const emit = defineEmits<{
  (e: "copy", code: string): void;
  (e: "loadMore"): void;
  (e: "select", userId: string): void;
}>();

const { t } = useFlareI18nOptional();
const title = computed(() => props.title ?? t("myInvite.title"));

const depthRows = computed(() =>
  referralDepthRows(props.stats, props.maxDepthShown).map((depth) => ({
    depth,
    label: t(`myInvite.${depth}`),
    count: props.stats?.[depth] ?? 0,
  })),
);

const hasCode = computed(() => props.code.trim().length > 0);
const qrPayload = computed(() => {
  const link = hasCode.value && !props.loading ? props.shareUrl.trim() : "";
  // The local QR encoder uses byte mode at correction level M.
  return new TextEncoder().encode(link).length <= 2331 ? link : "";
});
const showSkeleton = computed(() => props.loading);
const showTree = computed(() => props.showProfiles && props.maxDepthShown > 0);
const showEmpty = computed(() => !props.loading && props.invitees.length === 0 && !props.hasMore);
</script>

<template>
  <section class="flare-my-invite" :aria-label="title" :aria-busy="loading || undefined">
    <header v-if="showTitle" class="flare-my-invite__head">
      <h3 class="flare-my-invite__title">{{ title }}</h3>
    </header>

    <div class="flare-my-invite__hero">
      <template v-if="qrPayload">
        <div class="flare-my-invite__qr">
          <FlareQrMatrix :payload="qrPayload" :label="t('myInvite.qrHint')" />
        </div>
        <p class="flare-my-invite__qr-hint" aria-hidden="true">{{ t("myInvite.qrHint") }}</p>
      </template>

      <div v-if="hasCode && !showSkeleton" class="flare-my-invite__copy-row">
        <div class="flare-my-invite__value-group">
          <span class="flare-my-invite__label">{{ t("myInvite.codeLabel") }}</span>
          <output class="flare-my-invite__code">{{ code }}</output>
        </div>
        <FlareButton
          class="flare-my-invite__copy-button"
          size="sm"
          :label="t('myInvite.copy')"
          @click="emit('copy', code)"
        />
      </div>

      <p v-if="showSkeleton" class="flare-my-invite__loading" role="status">
        <span class="flare-my-invite__ghost flare-my-invite__ghost--code" aria-hidden="true" />
        <span class="flare-my-invite__sr">{{ t("myInvite.loading") }}</span>
      </p>
      <div v-else-if="!hasCode" class="flare-my-invite__copy-row" role="status">
        <div class="flare-my-invite__value-group">
          <span class="flare-my-invite__label">{{ t("myInvite.codeLabel") }}</span>
          <p class="flare-my-invite__unavailable">{{ t("myInvite.codeUnavailable") }}</p>
        </div>
      </div>
    </div>

    <section v-if="depthRows.length" :aria-label="t('myInvite.statsTitle')">
      <h4 class="flare-my-invite__subtitle">{{ t("myInvite.statsTitle") }}</h4>
      <dl class="flare-my-invite__stats">
        <div v-for="row in depthRows" :key="row.depth" class="flare-my-invite__stat" :class="`flare-my-invite__stat--${row.depth}`">
          <dt class="flare-my-invite__stat-label">{{ row.label }}</dt>
          <dd class="flare-my-invite__stat-value">{{ row.count }}</dd>
        </div>
      </dl>
    </section>

    <section v-if="showTree" class="flare-my-invite__team" :aria-label="t('myInvite.relationships')">
      <h4 class="flare-my-invite__subtitle">{{ t("myInvite.relationships") }}</h4>
      <ul v-if="showSkeleton" class="flare-my-invite__rows" aria-hidden="true">
        <li v-for="n in 3" :key="n" class="flare-my-invite__row--skeleton">
          <span class="flare-my-invite__ghost flare-my-invite__ghost--avatar" />
          <span class="flare-my-invite__ghost flare-my-invite__ghost--line" />
        </li>
      </ul>
      <p v-else-if="showEmpty" class="flare-my-invite__empty" role="status">{{ t("myInvite.empty") }}</p>
      <ul v-else class="flare-my-invite__rows">
        <FlareInviteeRow
          v-for="invitee in invitees"
          :key="invitee.userId"
          :invitee="invitee"
          :depth="1"
          :max-depth-shown="maxDepthShown"
          :load-children="onLoadChildren"
          @select="emit('select', $event)"
        />
      </ul>
      <div v-if="hasMore && !showSkeleton" class="flare-my-invite__more">
        <FlareButton
          variant="ghost"
          size="sm"
          block
          :label="t('myInvite.loadMore')"
          :loading="loadingMore"
          :disabled="loadingMore || loading"
          @click="emit('loadMore')"
        />
      </div>
    </section>
  </section>
</template>

<style scoped>
.flare-my-invite {
  display: grid;
  container-type: inline-size;
  gap: var(--flare-size-spacing-md);
  min-width: 0;
  color: var(--flare-color-text-primary);
}
.flare-my-invite__title {
  margin: 0;
  font-size: var(--flare-size-font-size-lg);
  font-weight: 600;
}
.flare-my-invite__subtitle {
  margin: 0 0 var(--flare-size-spacing-sm);
  font-size: var(--flare-size-font-size-md);
  font-weight: 500;
  color: var(--flare-color-text-secondary);
}
.flare-my-invite__hero {
  display: grid;
  gap: var(--flare-size-spacing-md);
  padding: var(--flare-size-spacing-md);
  border-radius: var(--flare-size-radius-xl);
  border: 1px solid var(--flare-color-border-secondary);
  background: var(--flare-color-bg-selected);
}
.flare-my-invite__qr {
  width: min(196px, 100%);
  margin: var(--flare-size-spacing-sm) auto 0;
}
.flare-my-invite__qr-hint {
  margin: 0 0 var(--flare-size-spacing-xs);
  text-align: center;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-secondary);
}
.flare-my-invite__copy-row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-primary);
}
.flare-my-invite__value-group {
  display: grid;
  gap: var(--flare-size-spacing-xs);
  flex: 1 0 min(100%, 11rem);
  min-width: 0;
}
.flare-my-invite__copy-button {
  margin-inline-start: auto;
  border-radius: var(--flare-size-radius-full);
}
.flare-my-invite__label,
.flare-my-invite__stat-label {
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-secondary);
}
/* The code is the one thing a person reads back: fixed pitch, wide tracking, selectable as a unit. */
.flare-my-invite__code {
  display: block;
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: var(--flare-size-font-size-3xl);
  font-weight: 600;
  letter-spacing: 0.12em;
  overflow-wrap: anywhere;
  user-select: all;
  color: var(--flare-color-primary-text);
}
.flare-my-invite__unavailable,
.flare-my-invite__empty,
.flare-my-invite__loading {
  margin: 0;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-secondary);
  overflow-wrap: anywhere;
}
.flare-my-invite__stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(100%, 96px), 1fr));
  gap: var(--flare-size-spacing-sm);
  margin: 0;
}
@container (width < 400px) {
  .flare-my-invite__stats { grid-template-columns: repeat(2, minmax(0, 1fr)); }
}
.flare-my-invite__stat {
  display: grid;
  gap: 2px;
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  border-radius: var(--flare-size-radius-md);
  border: 1px solid var(--flare-color-border-secondary);
}
.flare-my-invite__stat-value {
  margin: 0;
  font-size: var(--flare-size-font-size-3xl);
  font-weight: 600;
  font-variant-numeric: tabular-nums;
}
.flare-my-invite__stat--total .flare-my-invite__stat-value { color: var(--flare-color-primary-text); }
.flare-my-invite__team {
  padding: var(--flare-size-spacing-md);
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-primary);
}
.flare-my-invite__rows { list-style: none; margin: 0; padding: 0; }
.flare-my-invite__more { padding-top: var(--flare-size-spacing-sm); }
.flare-my-invite__row--skeleton {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-md);
  min-height: var(--flare-size-layout-touch-target);
}
.flare-my-invite__ghost {
  display: block;
  border-radius: var(--flare-size-radius-sm);
  background: var(--flare-color-bg-secondary);
  animation: flare-my-invite-pulse 1.4s ease-in-out infinite;
}
.flare-my-invite__ghost--code { width: 60%; height: 28px; background: var(--flare-color-bg-primary); }
.flare-my-invite__ghost--avatar { width: var(--flare-size-layout-avatar-size); height: var(--flare-size-layout-avatar-size); border-radius: var(--flare-size-radius-full); flex: none; }
.flare-my-invite__ghost--line { width: 45%; height: var(--flare-size-icon-size-sm); }
@keyframes flare-my-invite-pulse { 50% { opacity: 0.55; } }
@media (prefers-reduced-motion: reduce) { .flare-my-invite__ghost { animation: none; } }
.flare-my-invite__sr {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip: rect(0 0 0 0);
  white-space: nowrap;
}
</style>
