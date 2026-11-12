<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from "vue";
import FlareButton from "../../../general/FlareButton.vue";
import FlareQrMatrix from "../../../profile/FlareQrMatrix.vue";
import { useFlareI18nOptional } from "../../../../shared/i18n/useFlareI18n";
import { flareServerNowMs } from "../../../../shared/server-clock";
import {
  flarePluginQrExpired,
  flarePluginQrRefreshMs,
  type FlarePluginQrBlock,
} from "../../../../shared/contracts/plugin-ui";

// A QR code (vocabulary 2; it replaces the flare.qr renderer): the kit QR matrix of `value`, its label above and
// caption under it. A code with an expiry is covered once it passes (the server's clock) and, when the plugin
// declared a refresh query and the host listens, offers to refresh: the host runs the query and passes back a view.
const props = defineProps<{ block: FlarePluginQrBlock; canRefresh?: boolean; busy?: boolean }>();
const emit = defineEmits<{ refresh: [] }>();
const { t } = useFlareI18nOptional();
const now = ref(flareServerNowMs());
const expired = computed(() => flarePluginQrExpired(props.block, now.value));
let timer: ReturnType<typeof setTimeout> | undefined;
function schedule(): void {
  clearTimeout(timer);
  timer = undefined;
  const wait = flarePluginQrRefreshMs(props.block, now.value);
  // setTimeout holds at most ~24.8 days; a later expiry is looked at again then.
  if (wait !== null) timer = setTimeout(() => { now.value = flareServerNowMs(); schedule(); }, Math.min(wait, 2_147_000_000));
}
watch(() => [props.block.value, props.block.expiresAtMs], () => { now.value = flareServerNowMs(); schedule(); }, { immediate: true });
onBeforeUnmount(() => clearTimeout(timer));
const refreshable = computed(() => Boolean(props.block.refreshOperation) && props.canRefresh);
</script>

<template>
  <div class="flare-plugin-qr" :class="{ 'is-expired': expired }" :data-qr-expired="expired || undefined">
    <p v-if="block.label" class="flare-plugin-qr__label">{{ block.label }}</p>
    <div class="flare-plugin-qr__code">
      <FlareQrMatrix :payload="block.value" :label="block.label || block.caption || t('pluginView.qrCode')" :aria-hidden="expired || undefined" />
      <div v-if="expired" class="flare-plugin-qr__cover" role="status">
        <span>{{ t("pluginView.qrExpired") }}</span>
        <FlareButton
          v-if="refreshable"
          variant="secondary"
          size="sm"
          :label="t('pluginView.qrRefresh')"
          :disabled="busy"
          data-qr-refresh="true"
          @click="emit('refresh')"
        />
      </div>
    </div>
    <p v-if="block.caption" class="flare-plugin-qr__caption">{{ block.caption }}</p>
  </div>
</template>

<style scoped>
.flare-plugin-qr { display: grid; justify-items: center; gap: var(--flare-size-spacing-sm); min-width: 0; }
.flare-plugin-qr__label { margin: 0; font-size: var(--flare-size-font-size-md); font-weight: var(--flare-size-font-weight-medium); color: var(--flare-color-text-primary); text-align: center; }
.flare-plugin-qr__code { position: relative; width: min(100%, 220px); }
.flare-plugin-qr.is-expired :deep(.flare-qr-matrix) { opacity: 0.12; }
.flare-plugin-qr__cover {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: var(--flare-size-spacing-sm);
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-text-primary);
  text-align: center;
}
.flare-plugin-qr__caption { margin: 0; font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-tertiary); text-align: center; overflow-wrap: anywhere; }
</style>
