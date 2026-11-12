<script setup lang="ts">
import { computed } from "vue";
import FlareButton from "../general/FlareButton.vue";
import FlarePermissionPrompt from "../general/FlarePermissionPrompt.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { flareScanMarkerBounds, type FlareScanViewState, type FlareScanMarker, type FlareScanCapabilities } from "../../shared/contracts/scan";
const props = withDefaults(defineProps<{ state: FlareScanViewState; markers?: FlareScanMarker[]; hint?: string; torch?: boolean; capabilities: FlareScanCapabilities }>(), { markers: () => [], torch: false });
const emit = defineEmits<{ close: []; toggleTorch: []; pickImage: []; paste: []; openMyCode: []; selectMarker: [id: string]; retry: []; requestPermission: []; openSettings: [] }>();
const { t } = useFlareI18n();
const permission = computed(() => ({ permissionUndetermined: "undetermined", denied: "unavailable", restricted: "restricted" } as const)[props.state as "denied"]);
function markerStyle(marker: FlareScanMarker) { const bounds = flareScanMarkerBounds(marker); return { left: `${bounds.left * 100}%`, top: `${bounds.top * 100}%`, width: `${bounds.width * 100}%`, height: `${bounds.height * 100}%` }; }
</script>
<template>
  <section class="flare-scan-viewfinder" :aria-label="t('scan.title')" :aria-busy="state === 'preparing' || state === 'imageDecoding'">
    <header class="flare-scan-viewfinder__toolbar"><FlareButton variant="quiet" :label="t('common.close')" @click="emit('close')" /><strong>{{ t('scan.title') }}</strong><FlareButton v-if="capabilities.torch" variant="quiet" :label="torch ? t('scan.torchOff') : t('scan.torchOn')" @click="emit('toggleTorch')" /></header>
    <div class="flare-scan-viewfinder__preview">
      <slot name="preview" />
      <div v-if="permission" class="flare-scan-viewfinder__permission"><FlarePermissionPrompt kind="camera" :state="permission" :feature-label="t('scan.title')" :detail="state === 'denied' ? t('scan.permissionHelp') : undefined" @request="emit('requestPermission')" @open-settings="emit('openSettings')" /></div>
      <div v-if="state === 'live' || state === 'lowLight'" class="flare-scan-viewfinder__guide" aria-hidden="true" />
      <button v-for="(marker, index) in markers" :key="marker.id" class="flare-scan-viewfinder__marker" :style="markerStyle(marker)" :disabled="state !== 'choosing'" :aria-label="marker.label || t('scan.chooseCode', { number: index + 1 })" @click="emit('selectMarker', marker.id)">{{ index + 1 }}</button>
      <p class="flare-scan-viewfinder__status" role="status" aria-live="polite">{{ hint || t(`scan.states.${state}`) }}</p>
    </div>
    <footer class="flare-scan-viewfinder__toolbar">
      <FlareButton v-if="capabilities.album" variant="secondary" :label="t('scan.album')" @click="emit('pickImage')" />
      <FlareButton v-if="capabilities.paste" variant="secondary" :label="t('scan.paste')" @click="emit('paste')" />
      <FlareButton v-if="capabilities.myCode" variant="secondary" :label="t('scan.myCode')" @click="emit('openMyCode')" />
      <FlareButton v-if="['paused', 'cameraError', 'imageError', 'noCodeInImage', 'noCamera'].includes(state)" variant="primary" :label="t('common.retry')" @click="emit('retry')" />
    </footer>
  </section>
</template>
<style scoped>
.flare-scan-viewfinder { display: flex; flex-direction: column; min-height: 0; height: 100%; background: var(--flare-color-bg-primary); color: var(--flare-color-text-primary); }
.flare-scan-viewfinder__toolbar { display: flex; align-items: center; justify-content: space-between; gap: var(--flare-size-spacing-sm); flex-wrap: wrap; padding: var(--flare-size-spacing-md); }
.flare-scan-viewfinder__preview { position: relative; flex: 1; min-height: 280px; overflow: hidden; background: var(--flare-color-bg-secondary); }
.flare-scan-viewfinder__preview :deep(video) { width: 100%; height: 100%; object-fit: cover; }
.flare-scan-viewfinder__permission { position: absolute; inset: 0; display: grid; place-items: center; padding: var(--flare-size-spacing-lg); }
.flare-scan-viewfinder__guide { position: absolute; inset: 20%; border: 2px solid var(--flare-color-primary); border-radius: var(--flare-size-radius-xl); pointer-events: none; }
.flare-scan-viewfinder__marker { position: absolute; min-width: var(--flare-size-layout-touch-target); min-height: var(--flare-size-layout-touch-target); border: 2px solid var(--flare-color-primary); border-radius: var(--flare-size-radius-md); background: var(--flare-color-bg-primary); color: var(--flare-color-text-primary); font: inherit; cursor: pointer; }
.flare-scan-viewfinder__marker:focus-visible { outline: 2px solid var(--flare-color-primary); outline-offset: 3px; }
.flare-scan-viewfinder__marker:disabled { pointer-events: none; }
.flare-scan-viewfinder__status { position: absolute; inset-inline: var(--flare-size-spacing-md); bottom: var(--flare-size-spacing-md); margin: 0; padding: var(--flare-size-spacing-sm); text-align: center; background: var(--flare-color-bg-primary); border-radius: var(--flare-size-radius-lg); }
</style>
