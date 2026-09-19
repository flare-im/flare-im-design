<script setup lang="ts">
import { computed } from 'vue';
import FlareTransferProgress from './FlareTransferProgress.vue';
import FlareStatusBanner from '../general/FlareStatusBanner.vue';
import { retryableTransferIds, type TransferAction, type TransferQueueItem } from '../../shared/contracts/transfer';
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
const props = withDefaults(defineProps<{items: TransferQueueItem[]; loading?: boolean; error?: string; title?: string; emptyText?: string; retryFailedText?: string; reloadText?: string}>(), {loading:false});
const { t } = useFlareI18n();
const strings = computed(() => ({
  title: props.title ?? t("transferQueue.title"),
  emptyText: props.emptyText ?? t("transferQueue.empty"),
  retryFailedText: props.retryFailedText ?? t("transferQueue.retryFailed"),
  reloadText: props.reloadText ?? t("transferQueue.reload"),
}));
const emit = defineEmits<{action:[value:{id:string;action:TransferAction}];retryFailed:[ids:string[]];reload:[]}>();
const retryIds = computed(()=>retryableTransferIds(props.items));
</script>
<template>
  <section class="flare-transfer-queue" :aria-label="strings.title">
    <header><h3>{{ strings.title }} <span>{{ items.length }}</span></h3><button v-if="retryIds.length" type="button" @click="emit('retryFailed', [...retryIds])">{{ strings.retryFailedText }} ({{ retryIds.length }})</button></header>
    <progress v-if="loading" :aria-label="strings.title" />
    <FlareStatusBanner v-if="error" :text="error" tone="danger" :action-text="loading ? undefined : strings.reloadText" @action="emit('reload')" />
    <p v-if="!items.length && !loading && !error" role="status">{{ strings.emptyText }}</p>
    <div v-if="items.length" class="flare-transfer-queue__list" tabindex="0" role="region" :aria-label="strings.title">
      <FlareTransferProgress v-for="item in items" :key="item.id" :name="item.name" :state="item.state" :status-text="item.statusText" :progress="item.progress" :action-labels="item.actionLabels" :busy="item.busy" @action="emit('action', { id: item.id, action: $event })" />
    </div>
  </section>
</template>
<style scoped>
.flare-transfer-queue { display:grid; gap:12px; min-width:0; color:var(--flare-color-text-primary); }
header { display:flex; flex-wrap:wrap; gap:8px; align-items:center; justify-content:space-between; }
h3 { margin:0; font-size:16px; } h3 span { color:var(--flare-color-text-secondary); font-weight:400; }
button { min-height:48px; padding:8px 12px; font:inherit; border:1px solid var(--flare-color-border-primary); border-radius:8px; background:var(--flare-color-bg-primary); color:inherit; cursor:pointer; }
button:focus-visible, .flare-transfer-queue__list:focus-visible { outline:2px solid var(--flare-color-border-selected); outline-offset:2px; }
.flare-transfer-queue__list { display:grid; gap:8px; max-height:60vh; overflow:auto; overscroll-behavior:contain; padding:2px; }
</style>
