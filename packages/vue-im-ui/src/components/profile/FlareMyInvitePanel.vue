<script setup lang="ts">
// "My invite" — the person's invite code with copy / share / regenerate, how many
// people each referral depth holds, and who they invited directly. The host
// fetched all of it and performs every action; this card only shows the snapshot
// and dispatches intent. It never touches the clipboard or a share sheet.
import { computed, onBeforeUnmount, onMounted, ref } from "vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareIcon from "../general/FlareIcon.vue";
import {
  inviteJoinedDateLabel,
  referralDepthRows,
  regenerateAvailability,
  type FlareInvitee,
  type FlareReferralStats,
} from "../../shared/contracts/invite";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    /** The person's invite code; empty while the host has none yet. */
    code: string;
    /** Host-built share link; shown under the code and carried by `share`. */
    shareUrl?: string;
    /** Referral counts per depth; omitted while unknown. */
    stats?: FlareReferralStats | null;
    /** Depth rows to show (1–3). */
    maxDepthShown?: number;
    /** Direct invitees loaded so far. */
    invitees: FlareInvitee[];
    /** `false` replaces the invitee list with its count. */
    showProfiles?: boolean;
    hasMore?: boolean;
    loadingMore?: boolean;
    /** First load in flight — skeleton, never a fake empty list. */
    loading?: boolean;
    canRegenerate?: boolean;
    /** Epoch ms from which regenerating is allowed again. */
    regenerateAvailableAt?: number | null;
    regenerating?: boolean;
    title?: string;
  }>(),
  {
    shareUrl: "",
    stats: null,
    maxDepthShown: 3,
    showProfiles: true,
    hasMore: false,
    loadingMore: false,
    loading: false,
    canRegenerate: false,
    regenerateAvailableAt: null,
    regenerating: false,
    title: undefined,
  },
);
const emit = defineEmits<{
  (e: "copy", code: string): void;
  (e: "share", url: string): void;
  (e: "regenerate"): void;
  (e: "loadMore"): void;
  (e: "select", userId: string): void;
}>();

const { t } = useFlareI18nOptional();
const title = computed(() => props.title ?? t("myInvite.title"));

// The cooldown is a clock reading; re-read it every half minute so the control
// re-enables on its own once the server's deadline passes.
const now = ref(Date.now());
let ticker: ReturnType<typeof setInterval> | null = null;
onMounted(() => {
  now.value = Date.now();
  ticker = setInterval(() => { now.value = Date.now(); }, 30_000);
});
onBeforeUnmount(() => { if (ticker !== null) clearInterval(ticker); });

const regenerate = computed(() => regenerateAvailability(props.canRegenerate, props.regenerateAvailableAt, now.value));
const cooldownText = computed(() => {
  const remaining = regenerate.value.remaining;
  if (!remaining) return "";
  const unitKey = remaining.unit === "day" ? "unitDays" : remaining.unit === "hour" ? "unitHours" : "unitMinutes";
  return t("myInvite.cooldown", { time: t(`myInvite.${unitKey}`, { n: remaining.count }) });
});

const depthRows = computed(() =>
  referralDepthRows(props.stats, props.maxDepthShown).map((depth) => ({
    depth,
    label: t(`myInvite.${depth}`),
    count: props.stats?.[depth] ?? 0,
  })),
);

const hasCode = computed(() => props.code.trim().length > 0);
const showSkeleton = computed(() => props.loading && !hasCode.value);
const inviteeCount = computed(() => props.stats?.direct ?? props.invitees.length);
const showEmpty = computed(() => !props.loading && props.showProfiles && props.invitees.length === 0);
const rows = computed(() =>
  props.invitees.map((invitee) => ({
    invitee,
    joined: t("myInvite.joined", { date: inviteJoinedDateLabel(invitee.joinedAt) }),
  })),
);

function share(): void {
  emit("share", props.shareUrl || props.code);
}
</script>

<template>
  <section class="flare-my-invite" :aria-label="title" :aria-busy="loading || undefined">
    <header class="flare-my-invite__head">
      <h3 class="flare-my-invite__title">{{ title }}</h3>
    </header>

    <div class="flare-my-invite__code-block">
      <span class="flare-my-invite__label">{{ t("myInvite.codeLabel") }}</span>
      <p v-if="showSkeleton" class="flare-my-invite__loading" role="status">
        <span class="flare-my-invite__ghost flare-my-invite__ghost--code" aria-hidden="true" />
        <span class="flare-my-invite__sr">{{ t("myInvite.loading") }}</span>
      </p>
      <output v-else-if="hasCode" class="flare-my-invite__code">{{ code }}</output>
      <p v-else class="flare-my-invite__unavailable">{{ t("myInvite.codeUnavailable") }}</p>
      <p v-if="shareUrl && hasCode" class="flare-my-invite__link">{{ shareUrl }}</p>

      <div class="flare-my-invite__actions">
        <FlareButton variant="secondary" size="sm" :disabled="!hasCode" @click="emit('copy', code)">
          <FlareIcon name="copy" :size="16" /> {{ t("myInvite.copy") }}
        </FlareButton>
        <FlareButton variant="primary" size="sm" :disabled="!hasCode" @click="share">
          <FlareIcon name="share" :size="16" /> {{ t("myInvite.share") }}
        </FlareButton>
        <FlareButton
          v-if="regenerate.shown"
          variant="ghost"
          size="sm"
          :loading="regenerating"
          :disabled="!regenerate.enabled || regenerating || loading"
          @click="emit('regenerate')"
        >
          <FlareIcon v-if="!regenerating" name="refresh" :size="16" />
          {{ regenerating ? t("myInvite.regenerating") : t("myInvite.regenerate") }}
        </FlareButton>
      </div>
      <p v-if="cooldownText" class="flare-my-invite__cooldown" role="status">{{ cooldownText }}</p>
    </div>

    <dl v-if="depthRows.length" class="flare-my-invite__stats" :aria-label="t('myInvite.statsTitle')">
      <div v-for="row in depthRows" :key="row.depth" class="flare-my-invite__stat" :class="`flare-my-invite__stat--${row.depth}`">
        <dt class="flare-my-invite__stat-label">{{ row.label }}</dt>
        <dd class="flare-my-invite__stat-value">{{ row.count }}</dd>
      </div>
    </dl>

    <div class="flare-my-invite__team">
      <h4 class="flare-my-invite__subtitle">{{ t("myInvite.inviteesTitle") }}</h4>

      <p v-if="!showProfiles" class="flare-my-invite__count-only">{{ t("myInvite.countOnly", { count: inviteeCount }) }}</p>

      <template v-else>
        <ul v-if="showSkeleton" class="flare-my-invite__rows" aria-hidden="true">
          <li v-for="n in 3" :key="n" class="flare-my-invite__row flare-my-invite__row--skeleton">
            <span class="flare-my-invite__ghost flare-my-invite__ghost--avatar" />
            <span class="flare-my-invite__ghost flare-my-invite__ghost--line" />
          </li>
        </ul>
        <p v-else-if="showEmpty" class="flare-my-invite__empty" role="status">{{ t("myInvite.empty") }}</p>
        <ul v-else class="flare-my-invite__rows">
          <li v-for="row in rows" :key="row.invitee.userId" class="flare-my-invite__row">
            <button type="button" class="flare-my-invite__person" @click="emit('select', row.invitee.userId)">
              <FlareAvatar
                :user-id="row.invitee.userId"
                :display-name="row.invitee.displayName"
                :avatar-url="row.invitee.avatarUrl"
                :size="44"
              />
              <span class="flare-my-invite__person-text">
                <span class="flare-my-invite__name">{{ row.invitee.displayName }}</span>
                <span class="flare-my-invite__joined">{{ row.joined }}</span>
              </span>
            </button>
          </li>
        </ul>
        <div v-if="hasMore && !showSkeleton" class="flare-my-invite__more">
          <FlareButton
            variant="ghost"
            size="sm"
            block
            :label="t('myInvite.loadMore')"
            :loading="loadingMore"
            :disabled="loadingMore"
            @click="emit('loadMore')"
          />
        </div>
      </template>
    </div>
  </section>
</template>

<style scoped>
.flare-my-invite {
  display: grid;
  gap: var(--flare-size-spacing-md);
  min-width: 0;
  padding: var(--flare-size-spacing-md);
  border-radius: var(--flare-size-radius-lg);
  border: 1px solid var(--flare-color-border-primary);
  background: var(--flare-color-bg-primary);
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
.flare-my-invite__code-block {
  display: grid;
  gap: var(--flare-size-spacing-sm);
  padding: var(--flare-size-spacing-md);
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-secondary);
}
.flare-my-invite__label,
.flare-my-invite__stat-label {
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-tertiary);
}
/* The code is the one thing a person reads back: fixed pitch, wide tracking, selectable as a unit. */
.flare-my-invite__code {
  display: block;
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: var(--flare-size-font-size-4xl);
  font-weight: 600;
  letter-spacing: 0.18em;
  user-select: all;
  color: var(--flare-color-primary-text);
}
.flare-my-invite__unavailable,
.flare-my-invite__empty,
.flare-my-invite__count-only,
.flare-my-invite__cooldown,
.flare-my-invite__link,
.flare-my-invite__loading {
  margin: 0;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-secondary);
  overflow-wrap: anywhere;
}
.flare-my-invite__link { color: var(--flare-color-text-tertiary); }
.flare-my-invite__count-only { font-size: var(--flare-size-font-size-lg); color: var(--flare-color-text-primary); }
.flare-my-invite__actions { display: flex; flex-wrap: wrap; gap: var(--flare-size-spacing-sm); }
.flare-my-invite__actions :deep(.flare-button__label) { display: inline-flex; align-items: center; gap: var(--flare-size-spacing-xs); }
.flare-my-invite__stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(96px, 1fr));
  gap: var(--flare-size-spacing-sm);
  margin: 0;
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
.flare-my-invite__rows { list-style: none; margin: 0; padding: 0; display: grid; }
.flare-my-invite__row + .flare-my-invite__row { border-top: 1px solid var(--flare-color-border-secondary); }
.flare-my-invite__person {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-md);
  width: 100%;
  min-height: var(--flare-size-layout-touch-target);
  padding: var(--flare-size-spacing-sm) 0;
  border: 0;
  background: none;
  color: inherit;
  font: inherit;
  text-align: start;
  cursor: pointer;
}
.flare-my-invite__person:hover { background: var(--flare-color-bg-hover); }
.flare-my-invite__person:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
.flare-my-invite__person-text { display: grid; gap: 2px; min-width: 0; }
.flare-my-invite__name { font-size: var(--flare-size-font-size-lg); font-weight: 500; overflow-wrap: anywhere; }
.flare-my-invite__joined { font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-tertiary); }
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
