<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import type { FlareContentElem } from "../../../shared/contracts/message";
import { useFlareI18n } from "../../../shared/i18n/useFlareI18n";
import FlareBusinessDetailBlock from "../FlareBusinessDetailBlock.vue";
import FlareTaskMessage from "../standalone/FlareTaskMessage.vue";
import {
  businessPayload,
  businessRows,
  businessStatus,
  businessSubtitle,
  businessTitle,
  participantIds,
  statusTone,
} from "../../../utils/businessMessage";

// Timeline adapter: task payload → the contract body (checkbox + title + meta)
// with the detail rows underneath, the same shape the native dispatchers use.
// The box is a control only while someone takes the toggle, which reports the
// done state the user asks for.
const props = defineProps<{
  content: FlareContentElem;
  isSelf: boolean;
}>();
const emit = defineEmits<{ (event: "taskToggle", done: boolean): void }>();
const instance = getCurrentInstance();
const toggleListeners = computed(() =>
  instance?.vnode.props?.onTaskToggle ? { toggle: () => emit("taskToggle", !done.value) } : {},
);

const { t } = useFlareI18n();
const payload = computed(() => businessPayload(props.content, "task"));
const title = computed(() => businessTitle(payload.value, t("business.task")));
const subtitle = computed(() => businessSubtitle(payload.value));
const status = computed(() => businessStatus(payload.value));
const done = computed(
  () => payload.value.done === true || payload.value.completed === true || statusTone(status.value) === "success",
);
const meta = computed(() => [subtitle.value, status.value].filter(Boolean).join(" · "));
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
    <FlareTaskMessage embedded :title="title" :meta="meta" :done="done" v-on="toggleListeners" />
    <FlareBusinessDetailBlock
      :rows="detailRows"
      :collapsible="detailRows.length > 3"
    />
  </div>
</template>

<style scoped>
.business-message-view--task .fm-task {
  width: 100%;
  padding: 11px 12px 9px;
}
</style>
