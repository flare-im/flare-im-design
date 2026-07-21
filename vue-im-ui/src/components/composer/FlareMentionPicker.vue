<script setup lang="ts">
import { computed, ref } from "vue";
import { NIcon } from "naive-ui";
import { SearchOutline, PeopleOutline } from "../../shared/icon-glyphs";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareMentionCandidate } from "../../shared/contracts";

const props = defineProps<{
  candidates: FlareMentionCandidate[];
  /** Prepend a synthetic "@所有人" row (host handles the broadcast). */
  allowEveryone?: boolean;
}>();
const emit = defineEmits<{
  (e: "select", candidate: FlareMentionCandidate): void;
  (e: "close"): void;
}>();

const { t } = useFlareI18n();
const query = ref("");

const everyone = computed<FlareMentionCandidate | null>(() =>
  props.allowEveryone
    ? { id: "__all__", name: t("mention.everyone"), detail: t("mention.everyoneDetail"), isEveryone: true }
    : null,
);

const filtered = computed(() => {
  const q = query.value.trim().toLowerCase();
  const people = q
    ? props.candidates.filter(
        (c) => c.name.toLowerCase().includes(q) || c.detail?.toLowerCase().includes(q),
      )
    : props.candidates;
  const showEveryone = everyone.value && (!q || t("mention.everyone").toLowerCase().includes(q));
  return showEveryone ? [everyone.value as FlareMentionCandidate, ...people] : people;
});
</script>

<template>
  <div class="flare-mention-picker">
    <div class="flare-mention-picker__search">
      <n-icon :size="16" :component="SearchOutline" class="flare-mention-picker__search-ico" />
      <input
        v-model="query"
        type="text"
        class="flare-mention-picker__input"
        :placeholder="t('mention.search')"
        @keydown.esc="emit('close')"
      />
    </div>

    <div class="flare-mention-picker__list">
      <button
        v-for="c in filtered"
        :key="c.id"
        type="button"
        class="flare-mention-picker__row"
        :class="{ 'is-everyone': c.isEveryone }"
        @click="emit('select', c)"
      >
        <span v-if="c.isEveryone" class="flare-mention-picker__everyone-ico">
          <n-icon :size="18" :component="PeopleOutline" />
        </span>
        <FlareAvatar v-else :user-id="c.id" :display-name="c.name" :avatar-url="c.avatarUrl" :size="32" />
        <span class="flare-mention-picker__body">
          <span class="flare-mention-picker__name">{{ c.name }}</span>
          <span v-if="c.detail" class="flare-mention-picker__detail">{{ c.detail }}</span>
        </span>
      </button>
      <FlareEmptyState v-if="filtered.length === 0" :title="t('mention.empty')" icon="🔍" />
    </div>
  </div>
</template>

<style scoped>
.flare-mention-picker {
  width: 280px;
  max-width: 100%;
  display: flex;
  flex-direction: column;
  border-radius: var(--flare-size-radius-xl, 14px);
  background: var(--flare-color-bg-primary, #fff);
  border: 1px solid var(--flare-color-border-primary, #e9e6f1);
  box-shadow: var(--flare-shadow-lg, 0 12px 28px rgba(21, 18, 32, 0.16));
  overflow: hidden;
}
.flare-mention-picker__search {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 12px;
  border-bottom: 1px solid var(--flare-color-border-primary, #e9e6f1);
}
.flare-mention-picker__search-ico { color: var(--flare-color-text-tertiary, #a7a2b4); }
.flare-mention-picker__input {
  flex: 1;
  border: none;
  outline: none;
  background: transparent;
  font-size: 14px;
  color: var(--flare-color-text-primary, #15131c);
}
.flare-mention-picker__list {
  max-height: 264px;
  overflow-y: auto;
  padding: 6px;
}
.flare-mention-picker__row {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 7px 8px;
  border: none;
  border-radius: var(--flare-size-radius-lg, 10px);
  background: transparent;
  cursor: pointer;
  text-align: left;
  transition: background var(--flare-transition-fast, 150ms ease);
}
.flare-mention-picker__row:hover { background: var(--flare-color-bg-secondary, #f6f5fb); }
.flare-mention-picker__everyone-ico {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  background: var(--im-brand-gradient, var(--flare-color-primary, #7c3aed));
  flex: 0 0 auto;
}
.flare-mention-picker__body {
  min-width: 0;
  display: flex;
  flex-direction: column;
}
.flare-mention-picker__name {
  font-size: 14px;
  color: var(--flare-color-text-primary, #15131c);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-mention-picker__detail {
  font-size: 12px;
  color: var(--flare-color-text-tertiary, #a7a2b4);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
