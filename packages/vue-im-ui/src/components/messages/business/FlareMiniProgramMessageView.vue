<script setup lang="ts">
import { computed } from "vue";
import { AppsOutline } from "../../../shared/icon-glyphs";
import { NIcon } from "naive-ui";
import type { FlareContentElem } from "../../../shared/contracts/message";
import { useFlareI18n } from "../../../shared/i18n/useFlareI18n";
import { businessPayload, businessSubtitle, businessTitle } from "../../../utils/businessMessage";

const props = defineProps<{
  content: FlareContentElem;
  isSelf: boolean;
}>();

const { t } = useFlareI18n();
const payload = computed(() => businessPayload(props.content, "mini_program"));
const title = computed(() => businessTitle(payload.value, t("business.miniProgram")));
const subtitle = computed(() => businessSubtitle(payload.value));
// The card names the mini program; its app id and page path are routing data, not something people read.
</script>

<template>
  <div class="business-message-view business-message-view--mini-program">
    <header class="business-message-view__header">
      <span class="business-message-view__icon" aria-hidden="true">
        <n-icon aria-hidden="true" :component="AppsOutline" />
      </span>
      <div class="business-message-view__main">
        <span class="business-message-view__kicker">{{ t("business.miniProgram") }}</span>
        <strong class="business-message-view__title">{{ title }}</strong>
        <p v-if="subtitle" class="business-message-view__body">{{ subtitle }}</p>
      </div>
    </header>
  </div>
</template>
