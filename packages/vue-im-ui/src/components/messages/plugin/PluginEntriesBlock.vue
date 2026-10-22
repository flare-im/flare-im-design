<script setup lang="ts">
import FlareAvatar from "../../conversation/FlareAvatar.vue";
import { useFlareI18nOptional } from "../../../shared/i18n/useFlareI18n";
import type { FlarePluginEntriesBlock, FlarePluginEntry, FlarePluginUser } from "../../../shared/contracts/plugin-ui";

// Numbered entries (a sign-up list): number, avatar, name and text per row; "see all (total)" when the
// card shows fewer than there are, which hands over to the detail view.
const props = defineProps<{
  block: FlarePluginEntriesBlock;
  /** The resolved (or fallback) user of an id. */
  userOf: (userId: string) => FlarePluginUser;
}>();
const emit = defineEmits<{ (e: "seeAll"): void }>();
const { t } = useFlareI18nOptional();

/** entry.name, else the resolved user's, else the fallback; no name without a user. */
function nameOf(entry: FlarePluginEntry): string | undefined {
  if (entry.name) return entry.name;
  return entry.userId ? props.userOf(entry.userId).name : undefined;
}
</script>

<template>
  <div class="flare-plugin-entries">
    <ol v-if="block.items.length" class="flare-plugin-entries__list">
      <li v-for="entry in block.items" :key="entry.index" class="flare-plugin-entries__row" :data-entry-index="entry.index">
        <span v-if="block.numbered" class="flare-plugin-entries__number" data-entry-number="true">{{ entry.index }}.</span>
        <FlareAvatar
          v-if="entry.userId"
          class="flare-plugin-entries__avatar"
          :user-id="entry.userId"
          :display-name="nameOf(entry) ?? ''"
          :avatar-url="userOf(entry.userId).avatarUrl"
          :size="24"
        />
        <span class="flare-plugin-entries__line">
          <b v-if="nameOf(entry)" class="flare-plugin-entries__name" data-entry-name="true">{{ nameOf(entry) }}</b>
          <span class="flare-plugin-entries__text" data-entry-text="true">{{ entry.text }}</span>
        </span>
      </li>
    </ol>
    <p v-else-if="block.emptyText" class="flare-plugin-entries__empty" data-entries-empty="true">{{ block.emptyText }}</p>
    <button v-if="block.more" type="button" class="flare-plugin-entries__all" data-entries-see-all="true" @click="emit('seeAll')">
      {{ t("pluginView.seeAll", { count: block.total }) }}
    </button>
  </div>
</template>

<style scoped>
.flare-plugin-entries { display: grid; justify-items: start; gap: var(--flare-size-spacing-xs); min-width: 0; }
.flare-plugin-entries__list { display: grid; gap: var(--flare-size-spacing-xs); width: 100%; margin: 0; padding: 0; list-style: none; }
.flare-plugin-entries__row { display: flex; align-items: center; gap: var(--flare-size-spacing-sm); min-width: 0; font-size: var(--flare-size-font-size-md); }
.flare-plugin-entries__number { flex: none; min-width: 2ch; color: var(--flare-color-text-tertiary); font-variant-numeric: tabular-nums; }
.flare-plugin-entries__avatar { flex: none; }
.flare-plugin-entries__line { flex: 1; display: flex; gap: var(--flare-size-spacing-xs); min-width: 0; }
.flare-plugin-entries__name { flex: none; max-width: 40%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-weight: var(--flare-size-font-weight-medium); color: var(--flare-color-text-primary); }
.flare-plugin-entries__text { min-width: 0; overflow-wrap: anywhere; color: var(--flare-color-text-primary); }
.flare-plugin-entries__empty { margin: 0; font-size: var(--flare-size-font-size-md); color: var(--flare-color-text-tertiary); }
.flare-plugin-entries__all {
  position: relative;
  padding: 0;
  border: 0;
  background: none;
  font: inherit;
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-primary-text);
  cursor: pointer;
}
/* A text-sized key whose target reaches the touch-target size around it. */
.flare-plugin-entries__all::after { content: ""; position: absolute; inset: calc(var(--flare-size-spacing-md) * -1) calc(var(--flare-size-spacing-sm) * -1); }
.flare-plugin-entries__all:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
</style>
