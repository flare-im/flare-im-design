<script setup lang="ts">
import { computed, getCurrentInstance, ref } from "vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import FlareQrMatrix from "./FlareQrMatrix.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import type { FlareQrPhase } from "../../shared/contracts/qr";

const props = defineProps<{
  name: string;
  subtitle?: string;
  avatarUrl?: string;
  /** Text to encode (profile link, add-friend token). Without it the card says the code is unavailable. */
  qrPayload?: string;
  hint?: string;
  phase?: FlareQrPhase;
  refreshInMs?: number;
}>();

const { t } = useFlareI18n();

const instance = getCurrentInstance();
const emit = defineEmits<{ refresh: []; save: []; share: [] }>();
const payload = computed(() => (!props.phase || props.phase === "ready" || props.phase === "offline") && (props.refreshInMs === undefined || props.refreshInMs > 0) ? props.qrPayload?.trim() || "" : "");
const matrix = ref<InstanceType<typeof FlareQrMatrix> | null>(null);
const busy = computed(() => props.phase === "loading" || props.phase === "refreshing");
const unavailableTitle = computed(() => busy.value ? t("scan.phases.loading") : (props.refreshInMs !== undefined && props.refreshInMs <= 0) ? t("scan.codeExpired") : t("qr.unavailable"));
defineExpose({ exportSvg: () => matrix.value?.exportSvg() ?? null, exportPng: async () => { if (!matrix.value) throw new Error("QR unavailable"); return matrix.value.exportPng(); } });
</script>

<template>
  <section class="flare-qr-card" :aria-label="t('scan.myCode')" :aria-busy="busy">
    <div class="flare-qr-card__head">
      <FlareAvatar :user-id="name" :display-name="name" :avatar-url="avatarUrl" :size="40" />
      <div class="flare-qr-card__id">
        <div class="flare-qr-card__name">{{ name }}</div>
        <div v-if="subtitle" class="flare-qr-card__sub">{{ subtitle }}</div>
      </div>
    </div>

    <div class="flare-qr-card__symbol">
      <FlareQrMatrix v-if="payload" ref="matrix" class="flare-qr-card__code"
        :label="t('qr.code', { name })" :payload="payload" />
      <div v-else class="flare-qr-card__frame flare-qr-card__unavailable" role="status">
        <FlareEmptyState :title="unavailableTitle" icon="qr" :loading="busy"
          :action-text="!busy && instance?.vnode.props?.onRefresh ? t('common.retry') : undefined" @action="emit('refresh')" />
      </div>
    </div>
    <p v-if="payload" class="flare-qr-card__hint">{{ hint ?? t("qr.scanHint") }}</p>
    <div v-if="payload && (instance?.vnode.props?.onRefresh || instance?.vnode.props?.onSave || instance?.vnode.props?.onShare)" class="flare-qr-card__actions">
      <FlareButton v-if="instance?.vnode.props?.onRefresh" class="flare-qr-card__refresh"
        size="sm" variant="quiet" appearance="text" :label="t('pluginView.refresh')" @click="emit('refresh')" />
      <FlareButton v-if="instance?.vnode.props?.onSave" class="flare-qr-card__save"
        size="sm" variant="quiet" appearance="text" :label="t('scan.saveCode')" @click="emit('save')" />
      <FlareButton v-if="instance?.vnode.props?.onShare" class="flare-qr-card__share"
        size="sm" variant="quiet" appearance="text" :label="t('scan.shareCode')" @click="emit('share')" />
    </div>
  </section>
</template>

<style scoped>
.flare-qr-card {
  display: grid;
  gap: var(--flare-size-spacing-lg);
  box-sizing: border-box;
  width: 100%;
  max-width: var(--flare-size-component-qr-card-width);
  min-width: 0;
  margin-inline: auto;
  padding: var(--flare-size-spacing-lg);
  color: var(--flare-color-text-primary);
  background: var(--flare-color-bg-primary);
}
.flare-qr-card__head { display: flex; align-items: center; gap: var(--flare-size-spacing-md); min-width: 0; }
.flare-qr-card__id { flex: 1; min-width: 0; }
.flare-qr-card__name { font-size: var(--flare-size-font-size-2xl); font-weight: var(--flare-size-font-weight-semibold); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.flare-qr-card__sub { margin-top: var(--flare-size-spacing-3xs); font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-secondary); overflow-wrap: anywhere; }
.flare-qr-card__symbol { width: 100%; max-width: var(--flare-size-component-qr-code-size); min-width: 0; margin-inline: auto; }
.flare-qr-card__code { width: 100%; }
.flare-qr-card__frame { box-sizing: border-box; aspect-ratio: 1; display: grid; place-items: center; border-radius: var(--flare-size-radius-lg); background: var(--flare-color-bg-secondary); }
.flare-qr-card__unavailable { text-align: center; font-size: var(--flare-size-font-size-md); color: var(--flare-color-text-secondary); }
.flare-qr-card__hint { margin: 0; text-align: center; font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-secondary); overflow-wrap: anywhere; }
.flare-qr-card__actions {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  width: 100%;
  max-width: var(--flare-size-component-qr-code-size);
  margin-inline: auto;
}
.flare-qr-card__refresh { grid-column: 1; justify-self: start; }
.flare-qr-card__save { grid-column: 2; justify-self: center; }
.flare-qr-card__share { grid-column: 3; justify-self: end; }
</style>
