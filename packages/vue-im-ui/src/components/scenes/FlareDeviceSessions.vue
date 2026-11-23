<script setup lang="ts">
import { computed, useId } from 'vue';
import SceneList from './SceneList.vue';
import { deviceSessionActions, type DeviceSessionEntry } from '../../shared/contracts/scenes';
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
const props = defineProps<{
  items: DeviceSessionEntry[];
  loading?: boolean;
  error?: string;
  title?: string;
  currentText?: string;
  emptyText?: string;
  hintText?: string;
  grouped?: boolean;
}>();
const { t } = useFlareI18nOptional();
const hintId = `flare-devices-${useId()}`;
const strings = computed(() => ({
  title: props.title ?? t("deviceSessions.title"),
  currentText: props.currentText ?? t("deviceSessions.current"),
  emptyText: props.emptyText ?? t("deviceSessions.empty"),
  hintText: props.hintText ?? t("deviceSessions.hint"),
}));
const emit=defineEmits<{action:[value:{id:string;action:string}];reload:[]}>();
const current = computed(() => props.items.filter(item => item.current));
const others = computed(() => props.items.filter(item => !item.current));
const showGroups = computed(() => props.grouped && !props.loading && !props.error && current.value.length > 0);
const rows = computed(() => [...current.value, ...others.value].map(item => ({
  ...item,
  badge: item.current ? strings.value.currentText : item.badge,
  actions: deviceSessionActions(item),
})));
const currentRows = computed(() => current.value.map(item => ({ ...item, actions: deviceSessionActions(item) })));
</script>
<template>
  <div class="device-sessions">
    <p v-if="strings.hintText && items.length" :id="hintId" class="device-sessions__hint">{{ strings.hintText }}</p>
    <template v-if="showGroups">
      <SceneList :items="currentRows" :title="strings.currentText" />
      <SceneList v-if="others.length" :items="others" :title="t('deviceSessions.others')" action-appearance="text" @action="emit('action', $event)" />
    </template>
    <SceneList v-else :items="rows" :title="strings.title" :loading="loading" :error="error" :empty-text="strings.emptyText" action-appearance="text" :aria-describedby="strings.hintText && items.length ? hintId : undefined" @action="emit('action',$event)" @reload="emit('reload')" />
  </div>
</template>
<style scoped>
.device-sessions { min-width: 0; }
.device-sessions > .scene-list + .scene-list { margin-block-start: var(--flare-size-spacing-lg); }
.device-sessions__hint { margin: 0 0 var(--flare-size-spacing-md); color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-md); line-height: var(--flare-size-line-height-normal); }
</style>
