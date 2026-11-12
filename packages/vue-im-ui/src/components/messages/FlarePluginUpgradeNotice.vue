<script setup lang="ts">
// What a plugin contribution this build cannot draw shows instead (unavailableReason upgrade_required, docs
// plugin-components.md "Upgrade notice"): a message card's line, the mark of a "+" or "Me" entry, or a whole page.
// The kit asks nothing: the host reads update.plugin_upgrade_status for the placeholder's minBuild and passes the
// answer as `status`; the update key shows only when that build is offered to this device and the host passes
// `onUpdate` (which opens update.open_flow or the platform update UI). Without a build, only the copy shows.
import { computed } from "vue";
import FlareButton from "../general/FlareButton.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import FlareTag from "../general/FlareTag.vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import {
  flarePluginUpgradeMode,
  type FlarePluginUpgradeStatus,
  type FlarePluginUpgradeVariant,
} from "../../shared/contracts/plugin-ui";

const props = withDefaults(
  defineProps<{
    /** card: a line and the update key inside a message card; entry: a mark beside an entry; page: the whole page. */
    variant?: FlarePluginUpgradeVariant;
    /** What the page was (the placeholder's title); page only. */
    title?: string;
    /** update.plugin_upgrade_status for the placeholder's minBuild; absent while the host has not asked. */
    status?: FlarePluginUpgradeStatus | null;
    /** Opens the update flow. Without it no key is drawn. */
    onUpdate?: () => void;
    /** The update flow is opening. */
    busy?: boolean;
  }>(),
  { variant: "card", title: undefined, status: undefined, onUpdate: undefined, busy: false },
);
const { t } = useFlareI18nOptional();
const mode = computed(() => flarePluginUpgradeMode(props.status, Boolean(props.onUpdate)));
const text = computed(() =>
  mode.value === "notAvailable" ? t("pluginUpgrade.notAvailable") : t("pluginView.unavailable.upgradeRequired"),
);
function update(): void {
  if (!props.busy && mode.value === "update") props.onUpdate?.();
}
</script>

<template>
  <FlareTag
    v-if="variant === 'entry'"
    class="flare-plugin-upgrade-notice flare-plugin-upgrade-notice--entry"
    :label="t('pluginUpgrade.badge')"
    tone="warning"
    data-upgrade-notice="entry"
  />
  <FlareEmptyState
    v-else-if="variant === 'page'"
    class="flare-plugin-upgrade-notice flare-plugin-upgrade-notice--page"
    :title="title || t('pluginUpgrade.title')"
    :description="mode === 'notAvailable' ? t('pluginUpgrade.notAvailable') : t('pluginUpgrade.description')"
    icon="info"
    data-upgrade-notice="page"
    :data-upgrade-mode="mode"
  >
    <template v-if="mode === 'update'" #actions>
      <FlareButton
        variant="primary"
        :label="t('pluginUpgrade.action')"
        :loading="busy"
        :disabled="busy"
        data-upgrade-action="true"
        @click="update"
      />
    </template>
  </FlareEmptyState>
  <div
    v-else
    class="flare-plugin-upgrade-notice flare-plugin-upgrade-notice--card"
    role="status"
    data-upgrade-notice="card"
    :data-upgrade-mode="mode"
  >
    <p class="flare-plugin-upgrade-notice__text">{{ text }}</p>
    <FlareButton
      v-if="mode === 'update'"
      class="flare-plugin-upgrade-notice__action"
      variant="primary"
      size="sm"
      appearance="text"
      :label="t('pluginUpgrade.action')"
      :loading="busy"
      :disabled="busy"
      data-upgrade-action="true"
      @click="update"
    />
  </div>
</template>

<style scoped>
.flare-plugin-upgrade-notice--card {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  column-gap: var(--flare-size-spacing-sm);
  row-gap: var(--flare-size-spacing-2xs);
  min-width: 0;
}
.flare-plugin-upgrade-notice__text {
  flex: 1 1 12em;
  min-width: 0;
  margin: 0;
  font-size: var(--flare-size-font-size-sm);
  line-height: var(--flare-size-line-height-snug);
  color: var(--flare-color-text-secondary);
  overflow-wrap: anywhere;
}
.flare-plugin-upgrade-notice__action {
  flex: none;
}
</style>
