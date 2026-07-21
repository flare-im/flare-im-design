<script setup lang="ts">
import { computed } from "vue";
import { CheckboxOutline } from "../../../shared/icon-glyphs";
import { NIcon } from "naive-ui";
import type { FlareContentElem } from "../../../shared/contracts/message";
import { useFlareI18n } from "../../../shared/i18n/useFlareI18n";
import FlareBusinessDetailBlock from "../FlareBusinessDetailBlock.vue";
import {
  businessPayload,
  businessRows,
  businessStatus,
  businessSubtitle,
  businessTitle,
  participantIds,
  statusTone,
} from "../../../utils/businessMessage";

const props = defineProps<{
  content: FlareContentElem;
  isSelf: boolean;
}>();

const { t } = useFlareI18n();
const payload = computed(() => businessPayload(props.content, "task"));
const title = computed(() => businessTitle(payload.value, t("business.task")));
const subtitle = computed(() => businessSubtitle(payload.value));
const status = computed(() => businessStatus(payload.value));
const rows = computed(() =>
  businessRows(payload.value, {
    owner: t("business.owner"),
    assignee: t("business.assignee"),
    dueTime: t("business.dueTime"),
    participants: t("business.participants"),
  }),
);
const participants = computed(() => participantIds(payload.value));
const detailRows = computed(() => {
  if (participants.value.length && !rows.value.some((row) => row.key === "participants")) {
    return [
      ...rows.value,
      { key: "participants", label: t("business.participants"), value: participants.value.join(", ") },
    ];
  }
  return rows.value;
});
</script>

<template>
  <div class="business-message-view business-message-view--task">
    <header class="business-message-view__header">
      <span class="business-message-view__icon" aria-hidden="true">
        <n-icon :component="CheckboxOutline" />
      </span>
      <div class="business-message-view__main">
        <span class="business-message-view__kicker">{{ t("business.task") }}</span>
        <strong class="business-message-view__title">{{ title }}</strong>
        <p v-if="subtitle" class="business-message-view__body">{{ subtitle }}</p>
      </div>
      <span
        v-if="status"
        class="business-message-view__status"
        :class="`business-message-view__status--${statusTone(status)}`"
      >
        {{ status }}
      </span>
    </header>
    <FlareBusinessDetailBlock
      :rows="detailRows"
      :action-label="t('business.viewDetail')"
      :collapsible="detailRows.length > 3"
    />
  </div>
</template>
