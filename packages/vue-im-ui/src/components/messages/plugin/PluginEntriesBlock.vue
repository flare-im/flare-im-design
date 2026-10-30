<script setup lang="ts">
import FlareAvatar from "../../conversation/FlareAvatar.vue";
import FlareTag from "../../general/FlareTag.vue";
import { useFlareI18nOptional } from "../../../shared/i18n/useFlareI18n";
import {
  flarePluginBadgeTone,
  flarePluginEntryGroupHeader,
  type FlarePluginEntriesBlock,
  type FlarePluginEntry,
  type FlarePluginUser,
} from "../../../shared/contracts/plugin-ui";

// Entries (a sign-up list, a poll's voters): number, avatar, name and text per row; "see all (total)" when the
// card shows fewer than there are, which hands over to the detail view. A grouped list is one flat list with a
// header row ("火锅 · 3 票 · 60%") before the first item of each group (spec rules.entriesGrouped); the viewer's
// own row carries the "me" tag, and an item's badge (a ledger line's kind) comes before its text (rules.badge).
const props = defineProps<{
  block: FlarePluginEntriesBlock;
  /** The resolved (or fallback) user of an id. */
  userOf: (userId: string) => FlarePluginUser;
  /** The viewer's user id. */
  viewerId?: string;
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
      <template v-for="(entry, position) in block.items" :key="`${position}-${entry.index}`">
      <li
        v-if="entry.group"
        class="flare-plugin-entries__group"
        role="presentation"
        data-entry-group="true"
      >{{ flarePluginEntryGroupHeader(entry.group, (count) => t("pluginView.votes", { count })) }}</li>
      <li class="flare-plugin-entries__row" :data-entry-index="entry.index">
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
          <span v-if="viewerId && entry.userId === viewerId" class="flare-plugin-entries__me" data-entry-me="true">{{ t("pluginView.me") }}</span>
          <FlareTag
            v-if="entry.badge"
            class="flare-plugin-entries__badge"
            :label="entry.badge.text"
            :tone="flarePluginBadgeTone(entry.badge.tone)"
            data-entry-badge="true"
          />
          <span class="flare-plugin-entries__text" data-entry-text="true">{{ entry.text }}</span>
        </span>
      </li>
      </template>
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
.flare-plugin-entries__row { display: flex; align-items: center; gap: var(--flare-size-spacing-sm); min-width: 0; font-size: var(--flare-plugin-meta-size, var(--flare-size-font-size-md)); }
.flare-plugin-entries__number { flex: none; min-width: 2ch; color: var(--flare-color-text-tertiary); font-variant-numeric: tabular-nums; }
.flare-plugin-entries__avatar { flex: none; }
.flare-plugin-entries__line { flex: 1; display: flex; align-items: baseline; gap: var(--flare-size-spacing-xs); min-width: 0; }
.flare-plugin-entries__badge { flex: none; max-width: 40%; }
.flare-plugin-entries__name { flex: none; max-width: 40%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-weight: var(--flare-size-font-weight-medium); color: var(--flare-color-text-primary); }
.flare-plugin-entries__text { min-width: 0; overflow-wrap: anywhere; color: var(--flare-color-text-primary); }
.flare-plugin-entries__group {
  padding-block-start: var(--flare-size-spacing-xs);
  font-size: var(--flare-size-font-size-sm);
  font-weight: var(--flare-size-font-weight-semibold);
  color: var(--flare-color-text-secondary);
}
.flare-plugin-entries__group:first-child { padding-block-start: 0; }
.flare-plugin-entries__me {
  flex: none;
  padding: 0 var(--flare-size-spacing-xs);
  border-radius: var(--flare-size-radius-xs);
  background: var(--flare-color-bg-selected);
  font-size: var(--flare-size-font-size-xs);
  line-height: var(--flare-size-line-height-snug);
  color: var(--flare-color-primary-text);
}
.flare-plugin-entries__empty { margin: 0; font-size: var(--flare-plugin-meta-size, var(--flare-size-font-size-md)); color: var(--flare-color-text-tertiary); }
.flare-plugin-entries__all {
  position: relative;
  padding: 0;
  border: 0;
  background: none;
  font: inherit;
  font-size: var(--flare-plugin-meta-size, var(--flare-size-font-size-md));
  color: var(--flare-color-primary-text);
  cursor: pointer;
}
/* A text-sized key whose target reaches the touch-target size around it. */
.flare-plugin-entries__all::after { content: ""; position: absolute; inset: calc(var(--flare-size-spacing-md) * -1) calc(var(--flare-size-spacing-sm) * -1); }
.flare-plugin-entries__all:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
</style>
