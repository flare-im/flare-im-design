<script setup lang="ts">
import { computed } from "vue";
import { CheckboxOutline } from "@vicons/ionicons5";
import { NIcon } from "naive-ui";
import type { FlareContentElem } from "../../../shared/contracts/message";
import { useFlareI18n } from "../../../shared/i18n/useFlareI18n";
import FlareBusinessDetailBlock from "../FlareBusinessDetailBlock.vue";
import {
  businessPayload,
  businessStatus,
  businessSubtitle,
  businessTitle,
  statusTone,
} from "../../../utils/businessMessage";
import { asRecord, readArray, readNumber, readString } from "../../../utils/contentData";

const props = defineProps<{
  content: FlareContentElem;
  isSelf: boolean;
}>();

const { t } = useFlareI18n();
const payload = computed(() => businessPayload(props.content, "vote"));
const title = computed(() => businessTitle(payload.value, t("business.vote")));
const subtitle = computed(() => businessSubtitle(payload.value));
const status = computed(() => businessStatus(payload.value));

type VoteOptionView = {
  key: string;
  label: string;
  votes: number;
  percent: number;
};

const rawOptions = computed(() => readArray(payload.value, "options", "choices", "voteOptions", "vote_options"));
const countLookup = computed(() => buildCountLookup(payload.value));
const participantCount = computed(() =>
  readArray(payload.value, "participantUserIds", "participant_user_ids", "participants", "voterIds", "voter_ids").length,
);
const totalVotes = computed(() => {
  const explicit = readNumber(payload.value, -1, "totalVotes", "total_votes", "voteCount", "vote_count");
  if (explicit >= 0) return explicit;
  const sum = Array.from(countLookup.value.values()).reduce((total, count) => total + count, 0);
  return Math.max(sum, participantCount.value);
});
const options = computed<VoteOptionView[]>(() =>
  rawOptions.value
    .map((item, index) => optionView(item, index, countLookup.value, totalVotes.value))
    .filter((item): item is VoteOptionView => Boolean(item)),
);
const voteMeta = computed(() => `${options.value.length} options · ${totalVotes.value} votes`);

function optionView(
  item: unknown,
  index: number,
  lookup: Map<string, number>,
  total: number,
): VoteOptionView | null {
  const record = asRecord(item);
  const label = typeof item === "string"
    ? item
    : readString(record, "text", "label", "title", "name", "option");
  if (!label) return null;
  const id = readString(record, "id", "optionId", "option_id", "key") || String(index);
  const directVotes = readNumber(record, -1, "votes", "voteCount", "vote_count", "count", "selectedCount", "selected_count");
  const voterCount = readArray(record, "voters", "voterIds", "voter_ids", "participantUserIds", "participant_user_ids").length;
  const votes = Math.max(0, directVotes >= 0 ? directVotes : voterCount || lookup.get(id) || lookup.get(label) || lookup.get(String(index)) || 0);
  const explicitPercent = readNumber(record, -1, "percent", "percentage", "rate", "ratio");
  const percent = explicitPercent >= 0
    ? normalizePercent(explicitPercent)
    : total > 0
      ? Math.round((votes / total) * 1000) / 10
      : 0;
  return {
    key: id,
    label,
    votes,
    percent,
  };
}

function buildCountLookup(source: Record<string, unknown>): Map<string, number> {
  const map = new Map<string, number>();
  for (const key of ["voteCounts", "vote_counts", "counts", "statistics", "stats", "results", "voteResults", "vote_results"]) {
    const value = source[key];
    if (Array.isArray(value)) {
      value.forEach((item, index) => {
        const record = asRecord(item);
        const id = readString(record, "id", "optionId", "option_id", "key") || String(index);
        const label = readString(record, "text", "label", "title", "name", "option");
        const count = readNumber(record, -1, "votes", "voteCount", "vote_count", "count", "selectedCount", "selected_count");
        if (count >= 0) {
          map.set(id, count);
          if (label) map.set(label, count);
        }
      });
      continue;
    }
    const record = asRecord(value);
    for (const [entryKey, entryValue] of Object.entries(record)) {
      const count = typeof entryValue === "number" ? entryValue : Number(entryValue);
      if (Number.isFinite(count)) map.set(entryKey, Math.max(0, count));
    }
  }
  return map;
}

function normalizePercent(value: number): number {
  const percent = value <= 1 ? value * 100 : value;
  return Math.min(100, Math.max(0, Math.round(percent * 10) / 10));
}

function formatPercent(value: number): string {
  return `${Number.isInteger(value) ? value.toFixed(0) : value.toFixed(1)}%`;
}
</script>

<template>
  <div class="business-message-view business-message-view--vote">
    <header class="business-message-view__header">
      <span class="business-message-view__icon" aria-hidden="true">
        <n-icon :component="CheckboxOutline" />
      </span>
      <div class="business-message-view__main">
        <span class="business-message-view__kicker">{{ t("business.vote") }}</span>
        <strong class="business-message-view__title">{{ title }}</strong>
        <p class="business-message-view__body">{{ subtitle || voteMeta }}</p>
      </div>
      <span
        v-if="status"
        class="business-message-view__status"
        :class="`business-message-view__status--${statusTone(status)}`"
      >
        {{ status }}
      </span>
    </header>
    <div v-if="options.length" class="business-vote-results">
      <div
        v-for="option in options"
        :key="option.key"
        class="business-vote-option"
        :style="{ '--vote-percent': `${option.percent}%` }"
      >
        <div class="business-vote-option__row">
          <span class="business-vote-option__label">{{ option.label }}</span>
          <span class="business-vote-option__meta">{{ option.votes }} votes · {{ formatPercent(option.percent) }}</span>
        </div>
        <div class="business-vote-option__bar" aria-hidden="true" />
      </div>
    </div>
    <FlareBusinessDetailBlock
      :rows="[]"
      :action-label="t('business.viewDetail')"
      :collapsible="false"
    />
  </div>
</template>

<style scoped>
.business-vote-results {
  display: grid;
  gap: 8px;
  padding: 0 12px 11px;
}

.business-vote-option {
  display: grid;
  gap: 6px;
  min-width: 0;
}

.business-vote-option__row {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: baseline;
  gap: 10px;
  min-width: 0;
}

.business-vote-option__label {
  min-width: 0;
  overflow: hidden;
  color: var(--im-text-primary, var(--text-primary));
  font-size: 12px;
  font-weight: 600;
  line-height: 1.35;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.business-vote-option__meta {
  flex: 0 0 auto;
  color: var(--im-text-tertiary, var(--text-tertiary));
  font-size: 11px;
  font-weight: 600;
  line-height: 1.2;
}

.business-vote-option__bar {
  position: relative;
  height: 6px;
  overflow: hidden;
  border-radius: 999px;
  background: color-mix(in srgb, var(--im-primary, #7c3aed) 8%, var(--im-bg-surface-alt, #f4f6fb));
}

.business-vote-option__bar::before {
  position: absolute;
  inset: 0 auto 0 0;
  width: var(--vote-percent, 0%);
  border-radius: inherit;
  background: color-mix(in srgb, var(--im-primary, #7c3aed) 72%, var(--im-text-primary, #111827));
  content: "";
  transition: width var(--im-motion-normal, 180ms ease);
}

@media (max-width: 420px) {
  .business-vote-option__row {
    grid-template-columns: 1fr;
    gap: 3px;
  }
}
</style>
