<script setup lang="ts">
import { computed } from "vue";
import { ChatbubbleEllipsesOutline, FlaskOutline, SearchOutline } from "../../shared/icon-glyphs";
import { NButton, NIcon } from "naive-ui";
import { useRouter } from "vue-router";
import { loginTransportDisplayName, useFlareWorkbenchUi } from "@flare-im/vue-ui/composables";
import { useFlareSdk } from "../sdk/flareSdkContext";
import { useFlareI18n } from "../shared/i18n";

const sdk = useFlareSdk();
const router = useRouter();
const workbenchUi = useFlareWorkbenchUi();
const { t } = useFlareI18n();

const runtimeProductLabel = computed(() =>
  sdk.sdkRuntimeStatus.value === "tauri-native" ? "Flare Core Tauri" : "Flare Core Web",
);
const activeTransportLabel = computed(() => loginTransportDisplayName(sdk.form.transportMode));

function openLab(): void {
  void router.push({ name: "sdk-lab" });
}
</script>

<template>
  <section class="flutter-page chat-route chat-route--placeholder">
    <div class="chat-placeholder">
      <div class="chat-placeholder__mark">
        <n-icon :component="ChatbubbleEllipsesOutline" :size="34" />
      </div>
      <div class="chat-placeholder__copy">
        <span>{{ runtimeProductLabel }}</span>
        <strong>{{ t("chat.selectTitle") }}</strong>
        <p>{{ t("chat.selectHint") }}</p>
      </div>
      <div class="chat-placeholder__metrics" aria-label="Current SDK state">
        <div>
          <strong>{{ sdk.conversations.value.length }}</strong>
          <span>local conversations</span>
        </div>
        <div>
          <strong>{{ sdk.totalUnread.value }}</strong>
          <span>unread messages</span>
        </div>
        <div>
          <strong>{{ sdk.connectionState.value }}</strong>
          <span>connection state</span>
        </div>
        <div>
          <strong>{{ activeTransportLabel }}</strong>
          <span>protocol</span>
        </div>
      </div>
      <div class="chat-placeholder__actions">
        <n-button type="primary" @click="workbenchUi.openStartChat()">
          <template #icon><n-icon :component="ChatbubbleEllipsesOutline" /></template>
          {{ t("workbench.newChat") }}
        </n-button>
        <n-button secondary @click="workbenchUi.openChatSearch()">
          <template #icon><n-icon :component="SearchOutline" /></template>
          {{ t("workbench.searchMessages") }}
        </n-button>
        <n-button secondary @click="openLab">
          <template #icon><n-icon :component="FlaskOutline" /></template>
          SDK Lab
        </n-button>
      </div>
    </div>
  </section>
</template>
