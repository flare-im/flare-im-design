<script setup lang="ts">
// The network and line diagnostics page's body: the access directory the host read (`access.getStatus`,
// `access.listAccessPoints`) in, the kit's words and rows out, and every action back to the host. What the page says
// is decided by utils/accessDiagnostics.ts (spec/access-diagnostics-vectors.json), the same in every kit. The component
// holds no SDK: it never reads the clipboard or the network, it reports intent and draws what the host feeds back.
// An action is drawn only while the host listens for it.
import { computed, getCurrentInstance, nextTick, ref, useId, watch } from "vue";
import type { ComponentPublicInstance } from "vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import {
  flareAccessDiagnostics,
  flareAccessExportFeedback,
  flareAccessImportFeedback,
  flareAccessProtocolLabel,
  flareAccessRefreshFeedback,
  flareAccessRttTone,
  flareAccessSource,
  type FlareAccessNoticeText,
  type FlareAccessPoint,
  type FlareAccessPointRow,
  type FlareAccessRttGrade,
  type FlareAccessStatus,
} from "../../utils/accessDiagnostics";
import FlareDescriptionList from "../data/FlareDescriptionList.vue";
import type { FlareDescriptionItem } from "../data/description-list";
import FlareButton from "../general/FlareButton.vue";
import FlareInput from "../general/FlareInput.vue";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";
import FlareTag from "../general/FlareTag.vue";

const props = withDefaults(
  defineProps<{
    /** What `access.getStatus` returned; null until the host has read it. */
    status?: FlareAccessStatus | null;
    /** What `access.listAccessPoints` returned. */
    accessPoints?: readonly FlareAccessPoint[];
    /** `access.refresh` is in flight. */
    refreshing?: boolean;
    /** The `outcome` of the last `access.refresh`. */
    refreshOutcome?: string | null;
    /** `access.importRecovery` is in flight. */
    importing?: boolean;
    /** The `outcome` of the last `access.importRecovery`. */
    importOutcome?: string | null;
    /** Its `code` when rejected. */
    importCode?: string | null;
    /** The host is gathering and copying the diagnostics. */
    exporting?: boolean;
    /** The host's word on the clipboard: `copied` or `failed`. */
    exportOutcome?: string | null;
  }>(),
  {
    status: null,
    accessPoints: () => [],
    refreshing: false,
    refreshOutcome: null,
    importing: false,
    importOutcome: null,
    importCode: null,
    exporting: false,
    exportOutcome: null,
  },
);
const emit = defineEmits<{
  (e: "pin", accessPointId: string): void;
  (e: "unpin"): void;
  (e: "refresh"): void;
  (e: "importRecovery", link: string): void;
  (e: "exportDiagnostics"): void;
}>();
const instance = getCurrentInstance();
const { t } = useFlareI18nOptional();
const uid = useId();
const listens = (listener: string) => Boolean(instance?.vnode.props?.[listener]);

const model = computed(() => flareAccessDiagnostics(props.status, props.accessPoints));
const sections = computed(() =>
  model.value.state === "recovering" ? (["recovery", "current", "lines"] as const) : (["current", "lines", "recovery"] as const),
);

const NOTICE_KEYS: Record<FlareAccessNoticeText, string> = {
  healthy: "accessDiagnostics.healthy",
  notConnected: "accessDiagnostics.notConnected",
  serviceUnavailable: "connection.serviceUnavailable",
  waitingForNetwork: "connection.waitingForNetwork",
  accessPointMismatch: "accessDiagnostics.accessPointMismatch",
  manifestStale: "accessDiagnostics.manifestStaleNotice",
};
const RTT_KEYS: Record<FlareAccessRttGrade, string> = {
  good: "accessDiagnostics.rttGood",
  fair: "accessDiagnostics.rttFair",
  poor: "accessDiagnostics.rttPoor",
};

function rttText(shownMs: number | null, grade: FlareAccessRttGrade | null): string | null {
  return shownMs === null || grade === null ? null : `${shownMs} ms · ${t(RTT_KEYS[grade])}`;
}

const sourceText = computed(() => {
  const { kind, detail } = flareAccessSource(props.status?.source);
  switch (kind) {
    case "seed": return t("accessDiagnostics.sourceSeed");
    case "mirror": return `${t("accessDiagnostics.sourceMirror")} ${detail}`;
    case "wellKnown": return `${t("accessDiagnostics.accessPoint")} ${detail}`;
    case "recovery": return t("accessDiagnostics.sourceRecovery");
    case "development": return t("accessDiagnostics.sourceDevelopment");
    case "none": return t("accessDiagnostics.sourceNone");
    case "unknown": return detail;
  }
});
const manifestText = computed(() => {
  switch (model.value.manifest) {
    case "valid": return t("accessDiagnostics.manifestValid");
    case "stale": return t("accessDiagnostics.manifestStale");
    case "none": return t("accessDiagnostics.manifestNone");
  }
});

const facts = computed<FlareDescriptionItem[]>(() => {
  const { status } = props;
  const items: FlareDescriptionItem[] = [
    { key: "accessPoint", label: t("accessDiagnostics.accessPoint"), value: status?.accessPointId, monospace: true },
    { key: "region", label: t("accessDiagnostics.region"), value: status?.regionId },
    { key: "protocol", label: t("accessDiagnostics.protocol"), value: flareAccessProtocolLabel(status?.protocol) },
    { key: "rtt", label: t("accessDiagnostics.rtt"), value: rttText(model.value.rttMs, model.value.rttGrade) },
    { key: "serial", label: t("accessDiagnostics.serial"), value: status?.loaded ? status.serial : null, monospace: true },
    { key: "source", label: t("accessDiagnostics.source"), value: sourceText.value },
    { key: "manifest", label: t("accessDiagnostics.manifest"), value: manifestText.value },
    {
      key: "developmentMode",
      label: t("connection.developmentMode"),
      value: t(status?.developmentMode ? "accessDiagnostics.on" : "accessDiagnostics.off"),
    },
  ];
  if (model.value.reportedAccessPointId !== null) {
    items.push({
      key: "reportedAccessPoint",
      label: t("accessDiagnostics.reportedAccessPoint"),
      value: model.value.reportedAccessPointId,
      monospace: true,
    });
  }
  if (model.value.recoveryRounds !== null) {
    items.push({ key: "recoveryRounds", label: t("accessDiagnostics.recoveryRounds"), value: model.value.recoveryRounds });
  }
  return items;
});

const POINT_KEYS = {
  active: "accessDiagnostics.statusActive",
  draining: "accessDiagnostics.statusDraining",
  disabled: "accessDiagnostics.statusDisabled",
  unknown: "accessDiagnostics.statusUnknown",
} as const;
const BREAKER_KEYS = { open: "accessDiagnostics.breakerOpen", halfOpen: "accessDiagnostics.breakerHalfOpen" } as const;

function pinOffered(row: FlareAccessPointRow): boolean {
  return row.pin !== null && listens(row.pin === "pin" ? "onPin" : "onUnpin");
}
function pinLabel(row: FlareAccessPointRow): string {
  return t(row.pin === "pin" ? "accessDiagnostics.pin" : "accessDiagnostics.unpin");
}
function togglePin(row: FlareAccessPointRow) {
  if (row.pin === "pin") emit("pin", row.accessPointId);
  else emit("unpin");
}

const refreshFeedback = computed(() => {
  const feedback = flareAccessRefreshFeedback(props.refreshOutcome);
  if (!feedback) return null;
  const keys = {
    adopted: "accessDiagnostics.refreshAdopted",
    upToDate: "accessDiagnostics.refreshUpToDate",
    failed: "accessDiagnostics.refreshFailed",
    skipped: "accessDiagnostics.refreshSkipped",
  } as const;
  return { text: t(keys[feedback.text]), tone: feedback.tone };
});
const importFeedback = computed(() => {
  const feedback = flareAccessImportFeedback(props.importOutcome, props.importCode);
  if (!feedback) return null;
  const keys = {
    adopted: "accessDiagnostics.importAdopted",
    unchanged: "accessDiagnostics.importUnchanged",
    rollback: "accessDiagnostics.importRollback",
    expired: "accessDiagnostics.importExpired",
    wrongApp: "accessDiagnostics.importWrongApp",
    developmentMode: "accessDiagnostics.importDevelopmentMode",
    untrusted: "accessDiagnostics.importUntrusted",
    malformed: "accessDiagnostics.importMalformed",
    rejected: "accessDiagnostics.importRejected",
  } as const;
  return { text: t(keys[feedback.text]), tone: feedback.tone };
});
const exportFeedback = computed(() => {
  const feedback = flareAccessExportFeedback(props.exportOutcome);
  if (!feedback) return null;
  return { text: t(feedback.text === "copied" ? "accessDiagnostics.exportCopied" : "accessDiagnostics.exportFailed"), tone: feedback.tone };
});

// The banners are drawn silently; the newest answer, else the page's lead notice, is what a screen reader hears.
const spoken = computed(() => {
  const answer = importFeedback.value ?? refreshFeedback.value ?? exportFeedback.value;
  if (answer) return answer.text;
  const lead = model.value.notices[0];
  return lead ? t(NOTICE_KEYS[lead.text]) : "";
});

const link = ref("");
const importable = computed(() => link.value.trim() !== "" && !props.importing);
function importLink() {
  if (importable.value) emit("importRecovery", link.value.trim());
}
// An adopted link is done with: left in the field it would only invite a second import.
watch(() => props.importOutcome, (outcome) => {
  if (outcome === "adopted") link.value = "";
});

// A link opens this page from outside, at its top, and the answer stands lower than a phone shows: unseen, a refused
// link would look like nothing happened. The page loads while the link is checked, so what has arrived above (not what
// ticks) brings it back when the lines push it down again.
// The sections are a `v-for`, so the ref is a list of the one answer.
const importAnswer = ref<ComponentPublicInstance[]>([]);
watch(
  () => [importFeedback.value?.text, props.importing, props.status == null, props.accessPoints?.length],
  async () => {
    if (!importFeedback.value || props.importing) return;
    await nextTick();
    (importAnswer.value[0]?.$el as HTMLElement | undefined)?.scrollIntoView?.({ block: "nearest" });
  },
  { immediate: true },
);
</script>

<template>
  <section class="flare-access-diagnostics" :data-flare-access-state="model.state" :aria-label="t('accessDiagnostics.title')">
    <span class="flare-access-diagnostics__spoken" role="status">{{ spoken }}</span>
    <div v-if="model.notices.length" class="flare-access-diagnostics__notices">
      <FlareStatusBanner
        v-for="notice in model.notices"
        :key="notice.text"
        :text="t(NOTICE_KEYS[notice.text])"
        :tone="notice.tone"
        :pulse="notice.pulse"
        aria-live="off"
      />
    </div>

    <template v-for="section in sections" :key="section">
      <section v-if="section === 'current'" class="flare-access-diagnostics__section" :aria-labelledby="`${uid}-current`">
        <h3 :id="`${uid}-current`" class="flare-access-diagnostics__title">{{ t("accessDiagnostics.current") }}</h3>
        <FlareDescriptionList :items="facts">
          <template #item-rtt>
            <FlareTag
              v-if="model.rttGrade"
              :label="rttText(model.rttMs, model.rttGrade) ?? ''"
              :tone="flareAccessRttTone(model.rttGrade)"
            />
            <span v-else class="flare-access-diagnostics__none">—</span>
          </template>
        </FlareDescriptionList>
      </section>

      <section v-else-if="section === 'lines'" class="flare-access-diagnostics__section" :aria-labelledby="`${uid}-lines`">
        <h3 :id="`${uid}-lines`" class="flare-access-diagnostics__title">{{ t("accessDiagnostics.lines") }}</h3>
        <p v-if="!model.regions.length" class="flare-access-diagnostics__empty">{{ t("accessDiagnostics.noLines") }}</p>
        <div v-for="region in model.regions" :key="region.regionId ?? ''" class="flare-access-diagnostics__region">
          <h4 v-if="region.regionId" class="flare-access-diagnostics__region-title">{{ region.regionId }}</h4>
          <ul class="flare-access-diagnostics__points">
            <li
              v-for="row in region.accessPoints"
              :key="row.accessPointId"
              class="flare-access-diagnostics__point"
              :data-flare-access-point="row.accessPointId"
            >
              <div class="flare-access-diagnostics__point-body">
                <div class="flare-access-diagnostics__point-title">
                  <span class="flare-access-diagnostics__point-id">{{ row.accessPointId }}</span>
                  <FlareTag v-if="row.current" :label="t('accessDiagnostics.currentTag')" tone="info" />
                  <FlareTag v-if="row.pinned" :label="t('accessDiagnostics.pinnedTag')" />
                </div>
                <span v-if="row.host" class="flare-access-diagnostics__point-host">{{ row.host }}</span>
                <div class="flare-access-diagnostics__point-facts">
                  <FlareTag :label="t(POINT_KEYS[row.status])" :tone="row.statusTone" dot />
                  <FlareTag v-if="row.breaker" :label="t(BREAKER_KEYS[row.breaker])" :tone="row.breakerTone ?? 'neutral'" />
                  <FlareTag
                    v-if="row.grade"
                    :label="rttText(row.shownMs, row.grade) ?? ''"
                    :tone="flareAccessRttTone(row.grade)"
                  />
                </div>
              </div>
              <FlareButton
                v-if="pinOffered(row)"
                size="sm"
                variant="secondary"
                :label="pinLabel(row)"
                :aria-label="`${pinLabel(row)} ${row.accessPointId}`"
                @click="togglePin(row)"
              />
            </li>
          </ul>
        </div>
      </section>

      <section v-else class="flare-access-diagnostics__section" :aria-labelledby="`${uid}-recovery`">
        <h3 :id="`${uid}-recovery`" class="flare-access-diagnostics__title">{{ t("accessDiagnostics.recovery") }}</h3>
        <div v-if="listens('onRefresh') || listens('onExportDiagnostics')" class="flare-access-diagnostics__actions">
          <FlareButton
            v-if="listens('onRefresh')"
            variant="secondary"
            :label="t('accessDiagnostics.refresh')"
            :loading="refreshing"
            @click="emit('refresh')"
          />
          <FlareButton
            v-if="listens('onExportDiagnostics')"
            variant="secondary"
            :label="t('accessDiagnostics.export')"
            :loading="exporting"
            @click="emit('exportDiagnostics')"
          />
        </div>
        <FlareStatusBanner
          v-if="refreshFeedback"
          :text="refreshFeedback.text"
          :tone="refreshFeedback.tone"
          :dot="false"
          aria-live="off"
        />
        <FlareStatusBanner
          v-if="exportFeedback"
          :text="exportFeedback.text"
          :tone="exportFeedback.tone"
          :dot="false"
          aria-live="off"
        />
        <div v-if="listens('onImportRecovery')" class="flare-access-diagnostics__import">
          <label class="flare-access-diagnostics__label" :for="`${uid}-import`">{{ t("accessDiagnostics.importLabel") }}</label>
          <div class="flare-access-diagnostics__import-row">
            <FlareInput
              :id="`${uid}-import`"
              v-model="link"
              class="flare-access-diagnostics__import-field"
              monospace
              :placeholder="t('accessDiagnostics.importPlaceholder')"
              :disabled="importing"
              :spellcheck="false"
              @submit="importLink"
            />
            <FlareButton
              :label="t('accessDiagnostics.import')"
              :loading="importing"
              :disabled="!importable"
              @click="importLink"
            />
          </div>
          <p class="flare-access-diagnostics__hint">{{ t("accessDiagnostics.importHint") }}</p>
          <FlareStatusBanner
            v-if="importFeedback"
            ref="importAnswer"
            :text="importFeedback.text"
            :tone="importFeedback.tone"
            :dot="false"
            aria-live="off"
          />
        </div>
      </section>
    </template>
  </section>
</template>

<style scoped>
.flare-access-diagnostics {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-xl);
  min-width: 0;
  color: var(--flare-color-text-primary);
}
.flare-access-diagnostics__spoken {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
}
.flare-access-diagnostics__notices,
.flare-access-diagnostics__section {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
}
.flare-access-diagnostics__section {
  gap: var(--flare-size-spacing-md);
}
.flare-access-diagnostics__title {
  margin: 0;
  font-size: var(--flare-text-body-font-size);
  font-weight: var(--flare-size-font-weight-semibold);
  line-height: var(--flare-text-body-line-height);
}
.flare-access-diagnostics__none,
.flare-access-diagnostics__empty {
  margin: 0;
  color: var(--flare-color-text-tertiary);
  font-size: var(--flare-text-body-font-size);
}
.flare-access-diagnostics__region {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-xs);
  min-width: 0;
}
.flare-access-diagnostics__region-title,
.flare-access-diagnostics__label {
  margin: 0;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-text-caption-font-size);
  font-weight: var(--flare-size-font-weight-regular);
  line-height: var(--flare-text-body-line-height);
}
.flare-access-diagnostics__points {
  display: flex;
  flex-direction: column;
  margin: 0;
  padding: 0;
  list-style: none;
}
.flare-access-diagnostics__point {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--flare-size-spacing-md);
  min-width: 0;
  padding-block: var(--flare-size-spacing-sm);
}
.flare-access-diagnostics__point + .flare-access-diagnostics__point {
  border-top: 1px solid var(--flare-color-border-secondary);
}
.flare-access-diagnostics__point-body {
  display: flex;
  flex: 1;
  flex-direction: column;
  gap: var(--flare-size-spacing-xs);
  min-width: 0;
}
.flare-access-diagnostics__point-title,
.flare-access-diagnostics__point-facts {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
  min-width: 0;
}
.flare-access-diagnostics__point-id {
  min-width: 0;
  font-family: var(--flare-component-font-family-mono);
  font-size: var(--flare-text-body-font-size);
  overflow-wrap: anywhere;
}
.flare-access-diagnostics__point-host,
.flare-access-diagnostics__hint {
  margin: 0;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-text-caption-font-size);
  line-height: var(--flare-text-body-line-height);
  overflow-wrap: anywhere;
}
.flare-access-diagnostics__actions,
.flare-access-diagnostics__import-row {
  display: flex;
  flex-wrap: wrap;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
}
.flare-access-diagnostics__import {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-xs);
  min-width: 0;
}
.flare-access-diagnostics__import-field {
  flex: 1;
  min-width: 0;
}
</style>
