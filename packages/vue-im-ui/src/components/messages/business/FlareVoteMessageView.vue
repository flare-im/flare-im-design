<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import FlareVoteMessage from "../standalone/FlareVoteMessage.vue";
import type { FlareContentElem } from "../../../shared/contracts/message";
import { useFlareI18n } from "../../../shared/i18n/useFlareI18n";
import FlareBusinessDetailBlock from "../FlareBusinessDetailBlock.vue";
import {
  businessPayload,
  businessStatus,
  businessSubtitle,
  businessTitle,
} from "../../../utils/businessMessage";
import { asRecord, readArray, readNumber, readString } from "../../../utils/contentData";

const props = defineProps<{
  content: FlareContentElem;
  isSelf: boolean;
}>();
// A tapped option reports its index; the options are controls only while someone takes the vote.
const emit = defineEmits<{ (event: "vote", optionIndex: number): void }>();
const instance = getCurrentInstance();
const canVote = computed(() => Boolean(instance?.vnode.props?.onVote));

const { t } = useFlareI18n();
const payload = computed(() => businessPayload(props.content, "vote"));
const title = computed(() => businessTitle(payload.value, t("business.vote")));
const subtitle = computed(() => businessSubtitle(payload.value));
const status = computed(() => businessStatus(payload.value));

type VoteOptionView = {
  key: string;
  label: string;
  votes: number;
  percent: number | null;
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
const hasResults = computed(() => countLookup.value.size > 0 || readNumber(payload.value, -1, "totalVotes", "total_votes", "voteCount", "vote_count") >= 0 || participantCount.value > 0);
const voteMeta = computed(() => hasResults.value ? `${options.value.length} options · ${totalVotes.value} votes` : `${options.value.length} options`);

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
      : hasResults.value ? 0 : null;
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

</script>

<template>
  <div class="business-message-view business-message-view--vote">
    <FlareVoteMessage :title="title" :options="options.map(option => ({ text: option.label, pct: option.percent }))"
      :total="[subtitle, status, voteMeta].filter(Boolean).join(' · ')" :read-only="!canVote"
      @select="(_option: unknown, index: number) => emit('vote', index)" />
  </div>
</template>
