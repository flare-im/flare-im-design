<script setup lang="ts">
import { computed } from "vue";
import { CalendarOutline } from "@vicons/ionicons5";
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
  statusTone,
} from "../../../utils/businessMessage";

const props = defineProps<{
  content: FlareContentElem;
  isSelf: boolean;
}>();

const { t } = useFlareI18n();
const payload = computed(() => businessPayload(props.content, "schedule"));
const title = computed(() => businessTitle(payload.value, t("business.schedule")));
const subtitle = computed(() => businessSubtitle(payload.value));
const status = computed(() => businessStatus(payload.value));
const rows = computed(() =>
  businessRows(payload.value, {
    owner: t("business.owner"),
    dueTime: t("business.dueTime"),
    location: t("business.location"),
    participants: t("business.participants"),
  }),
);
</script>

<template>
  <div class="business-message-view business-message-view--schedule">
    <header class="business-message-view__header">
      <span class="business-message-view__icon" aria-hidden="true">
        <n-icon :component="CalendarOutline" />
      </span>
      <div class="business-message-view__main">
        <span class="business-message-view__kicker">{{ t("business.schedule") }}</span>
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
      :rows="rows"
      :action-label="t('business.viewDetail')"
      :collapsible="rows.length > 2"
    />
  </div>
</template>
