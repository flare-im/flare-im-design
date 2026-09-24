<script setup lang="ts">
import { computed, ref } from "vue";
import { NIcon } from "naive-ui";
import { flareIcons } from "../../shared/icons";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareFilterTabs, { type FlareFilterTabOption } from "../general/FlareFilterTabs.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareContact } from "../../shared/contracts";

const props = defineProps<{
  readers: FlareContact[];
  unread: FlareContact[];
  /** Show the header dismiss control (sheet mode). */
  dismissible?: boolean;
}>();
const emit = defineEmits<{
  (e: "select", id: string): void;
  (e: "close"): void;
}>();

const { t } = useFlareI18n();
const active = ref<"read" | "unread">("read");

const tabs = computed<FlareFilterTabOption[]>(() => [
  { value: "read", label: t("readReceipt.read"), badge: props.readers.length },
  { value: "unread", label: t("readReceipt.unread"), badge: props.unread.length },
]);
const list = computed(() => (active.value === "read" ? props.readers : props.unread));
</script>

<template>
  <div class="flare-read-receipt">
    <header class="flare-read-receipt__head">
      <div class="flare-read-receipt__title">
        <n-icon aria-hidden="true" :size="16" :component="flareIcons.read" />
        {{ t("readReceipt.title") }}
      </div>
      <button
        v-if="dismissible"
        type="button"
        class="flare-read-receipt__close"
        :aria-label="t('readReceipt.close')"
        @click="emit('close')"
      >
        <n-icon aria-hidden="true" :size="18" :component="flareIcons.close" />
      </button>
    </header>

    <FlareFilterTabs v-model="active" :options="tabs" />

    <div class="flare-read-receipt__list">
      <button
        v-for="c in list"
        :key="c.id"
        type="button"
        class="flare-read-receipt__row"
        @click="emit('select', c.id)"
      >
        <FlareAvatar :user-id="c.id" :display-name="c.name" :avatar-url="c.avatarUrl" :size="36" />
        <span class="flare-read-receipt__name">{{ c.name }}</span>
      </button>
      <FlareEmptyState
        v-if="list.length === 0"
        :title="active === 'read' ? t('readReceipt.emptyRead') : t('readReceipt.emptyUnread')"
        icon="success"
      />
    </div>
  </div>
</template>

<style scoped>
.flare-read-receipt {
  width: 320px;
  max-width: 100%;
  display: flex;
  flex-direction: column;
  border-radius: var(--flare-size-radius-xl);
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-primary);
  box-shadow: var(--flare-shadow-lg);
  overflow: hidden;
}
.flare-read-receipt__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--flare-size-spacing-2md) 16px var(--flare-size-spacing-2sm);
}
.flare-read-receipt__title {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  font-size: 15px;
  font-weight: 600;
  color: var(--flare-color-text-primary);
}
.flare-read-receipt__close {
  border: none;
  background: transparent;
  color: var(--flare-color-text-tertiary);
  cursor: pointer;
  display: inline-flex;
}
.flare-read-receipt__list {
  max-height: 320px;
  overflow-y: auto;
  padding: 6px 8px var(--flare-size-spacing-2sm);
}
.flare-read-receipt__row {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px;
  border: none;
  border-radius: var(--flare-size-radius-lg);
  background: transparent;
  color: var(--flare-color-text-primary);
  font-size: 14px;
  cursor: pointer;
  transition: background var(--flare-transition-fast);
}
.flare-read-receipt__row:hover { background: var(--flare-color-bg-secondary); }
.flare-read-receipt__name {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
