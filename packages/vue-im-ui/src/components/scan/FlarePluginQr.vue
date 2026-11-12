<script setup lang="ts">
import { onBeforeUnmount, ref, watch } from "vue";
import FlareQrMatrix from "../profile/FlareQrMatrix.vue";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
const props = defineProps<{ token?: string; ttlMs?: number; caption?: string; encodeQr?: (token: string) => Promise<string> }>();
const { t } = useFlareI18n();
const payload = ref("");
const phase = ref<"loading" | "ready" | "failed" | "expired">("loading");
let generation = 0;
let timer: ReturnType<typeof setTimeout> | undefined;
let expiresAt: number | undefined;
async function encode() {
  const current = ++generation;
  clearTimeout(timer); payload.value = ""; phase.value = "loading";
  if (!props.token) return;
  if (expiresAt !== undefined && expiresAt <= performance.now()) { phase.value = "expired"; return; }
  try {
    if (!props.encodeQr) throw new Error("encoderUnavailable");
    const url = await props.encodeQr(props.token);
    if (current !== generation) return;
    const remaining = expiresAt === undefined ? undefined : expiresAt - performance.now();
    if (remaining !== undefined && remaining <= 0) { phase.value = "expired"; return; }
    payload.value = url; phase.value = "ready";
    if (remaining !== undefined) timer = setTimeout(() => { payload.value = ""; phase.value = "expired"; }, remaining);
  } catch { if (current === generation) phase.value = "failed"; }
}
watch(() => [props.token, props.ttlMs] as const, () => {
  expiresAt = props.ttlMs === undefined ? undefined : performance.now() + (Number.isFinite(props.ttlMs) ? Math.max(0, props.ttlMs) : 0);
  void encode();
}, { immediate: true });
// A host callback changing identity cannot extend a code's received lifetime.
watch(() => props.encodeQr, () => { if (phase.value === "failed" && props.encodeQr) void encode(); });
onBeforeUnmount(() => { generation++; clearTimeout(timer); });
</script>
<template><div v-if="token" class="flare-plugin-qr" :aria-busy="phase === 'loading'"><FlareQrMatrix v-if="phase === 'ready'" :payload="payload" :label="caption || t('scan.myCode')" /><FlareStatusBanner v-else :text="phase === 'expired' ? t('scan.codeExpired') : phase === 'failed' ? t('qr.unavailable') : t('scan.phases.loading')" :tone="phase === 'expired' || phase === 'failed' ? 'warning' : 'info'" /><p v-if="caption">{{ caption }}</p></div></template>
<style scoped>.flare-plugin-qr { width: min(100%, 280px); margin-inline: auto; }.flare-plugin-qr p { text-align: center; color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); }</style>
