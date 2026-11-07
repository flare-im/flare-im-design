<script setup lang="ts">
// The version block of an About page, in the settings list's rows: the version, the build, the channel and the row that
// checks for an update. What that row says and does is utils/updatePrompt.ts (spec/update-prompt-vectors.json), the same
// in every kit. The component holds no SDK: it reports intent, and the row is disabled while work is under way or while
// the host does not listen for what it would do.
import { computed, getCurrentInstance } from "vue";
import type { FlareSettingsItem, FlareSettingsSection } from "../../shared/contracts";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import {
  flareVersionChannelText,
  flareVersionPanel,
  type FlareVersionChannelText,
  type FlareVersionPanelDetail,
  type FlareVersionPanelRow,
} from "../../utils/updatePrompt";
import FlareSettingsList from "./FlareSettingsList.vue";

const props = withDefaults(
  defineProps<{
    /** `UpdateStatus.current.version`. */
    version: string;
    /** `UpdateStatus.current.build`. */
    build?: number | null;
    /** `UpdateStatus.current.channel`. */
    channel?: string | null;
    /** `UpdateStatus.state`. */
    updateState?: string | null;
  }>(),
  { build: null, channel: null, updateState: null },
);
const emit = defineEmits<{
  (e: "check"): void;
  (e: "update"): void;
}>();
const instance = getCurrentInstance();
const { t } = useFlareI18nOptional();
const listens = (listener: string) => Boolean(instance?.vnode.props?.[listener]);

const ROW_KEY = "update";
const ROW_TEXT: Record<FlareVersionPanelRow, string> = {
  check: "versionPanel.check",
  update: "connection.update",
  restart: "updatePrompt.restart",
};
const DETAIL_TEXT: Record<FlareVersionPanelDetail, string> = {
  checking: "versionPanel.checking",
  upToDate: "versionPanel.upToDate",
  available: "updatePrompt.titleAvailable",
  required: "updatePrompt.titleRequired",
  downloading: "updatePrompt.titleDownloading",
  verifying: "updatePrompt.titleVerifying",
  ready: "updatePrompt.titleReady",
  installing: "updatePrompt.titleInstalling",
  failed: "updatePrompt.titleFailed",
};
const CHANNEL_TEXT: Record<FlareVersionChannelText, string> = {
  stable: "versionPanel.channelStable",
  beta: "versionPanel.channelBeta",
  internal: "versionPanel.channelInternal",
};

const model = computed(() => flareVersionPanel(props.updateState));
const detail = computed(() => (model.value.detail === null ? undefined : t(DETAIL_TEXT[model.value.detail])));
const handled = computed(() => {
  const { action } = model.value;
  return action !== null && listens(action === "check" ? "onCheck" : "onUpdate");
});

const sections = computed<FlareSettingsSection[]>(() => {
  const items: FlareSettingsItem[] = [{ key: "version", label: t("versionPanel.version"), kind: "value", detail: props.version }];
  if (props.build !== null) items.push({ key: "build", label: t("versionPanel.build"), kind: "value", detail: String(props.build) });
  if (props.channel) {
    const known = flareVersionChannelText(props.channel);
    items.push({ key: "channel", label: t("versionPanel.channel"), kind: "value", detail: known ? t(CHANNEL_TEXT[known]) : props.channel });
  }
  items.push({ key: ROW_KEY, label: t(ROW_TEXT[model.value.row]), kind: "action", detail: detail.value, disabled: !handled.value });
  return [{ title: t("versionPanel.title"), items }];
});

function select(item: FlareSettingsItem) {
  if (item.key !== ROW_KEY || !handled.value) return;
  if (model.value.action === "check") emit("check");
  else emit("update");
}
</script>

<template>
  <div class="flare-version-panel">
    <span class="flare-version-panel__spoken" role="status">{{ detail }}</span>
    <FlareSettingsList :sections="sections" @select="select" />
  </div>
</template>

<style scoped>
.flare-version-panel {
  position: relative;
  min-width: 0;
}
.flare-version-panel__spoken {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
}
</style>
