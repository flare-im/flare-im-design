<script setup lang="ts">
import { computed } from "vue";
import { AppsOutline } from "../../../shared/icon-glyphs";
import { NIcon } from "naive-ui";
import type { FlareContentElem } from "../../../shared/contracts/message";
import { useFlareI18n } from "../../../shared/i18n/useFlareI18n";
import FlareBusinessDetailBlock from "../FlareBusinessDetailBlock.vue";
import { businessPayload, businessSubtitle, businessTitle } from "../../../utils/businessMessage";
import { readString } from "../../../utils/contentData";

const props = defineProps<{
  content: FlareContentElem;
  isSelf: boolean;
}>();

const { t } = useFlareI18n();
const payload = computed(() => businessPayload(props.content, "mini_program"));
const title = computed(() => businessTitle(payload.value, t("business.miniProgram")));
const subtitle = computed(() => businessSubtitle(payload.value));
const appId = computed(() => readString(payload.value, "appId", "app_id", "miniProgramId", "mini_program_id"));
const path = computed(() => readString(payload.value, "path", "pagePath", "page_path", "route"));
const rows = computed(() => [
  ...(appId.value ? [{ key: "appId", label: "App ID", value: appId.value }] : []),
  ...(path.value ? [{ key: "path", label: "Path", value: path.value }] : []),
]);
</script>

<template>
  <div class="business-message-view business-message-view--mini-program">
    <header class="business-message-view__header">
      <span class="business-message-view__icon" aria-hidden="true">
        <n-icon :component="AppsOutline" />
      </span>
      <div class="business-message-view__main">
        <span class="business-message-view__kicker">{{ t("business.miniProgram") }}</span>
        <strong class="business-message-view__title">{{ title }}</strong>
        <p v-if="subtitle" class="business-message-view__body">{{ subtitle }}</p>
      </div>
    </header>
    <FlareBusinessDetailBlock
      :rows="rows"
      :action-label="t('business.viewDetail')"
      :action-disabled="!appId"
      :action-reason="t('state.capabilityUnavailable')"
      :collapsible="false"
    />
  </div>
</template>
