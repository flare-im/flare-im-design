<script setup lang="ts">
import FlareAvatar from "../../conversation/FlareAvatar.vue";
import type { FlarePluginPeopleBlock, FlarePluginUser } from "../../../shared/contracts/plugin-ui";

// One row per group: overlapping avatars (the resolver already capped them at the block's max), the
// group's label and its count, coloured by the group's tone with the *Text tokens.
defineProps<{
  block: FlarePluginPeopleBlock;
  userOf: (userId: string) => FlarePluginUser;
}>();
</script>

<template>
  <div class="flare-plugin-people">
    <div
      v-for="(group, index) in block.groups"
      :key="index"
      class="flare-plugin-people__row"
      :class="`is-${group.tone ?? 'neutral'}`"
      :data-people-tone="group.tone ?? 'neutral'"
    >
      <span v-if="group.userIds.length" class="flare-plugin-people__stack" aria-hidden="true">
        <FlareAvatar
          v-for="userId in group.userIds"
          :key="userId"
          class="flare-plugin-people__avatar"
          :user-id="userId"
          :display-name="userOf(userId).name"
          :avatar-url="userOf(userId).avatarUrl"
          :size="24"
          :data-people-user="userId"
        />
      </span>
      <span class="flare-plugin-people__label" data-people-label="true">{{ group.label }}</span>
      <span class="flare-plugin-people__count" data-people-count="true">{{ group.count }}</span>
    </div>
  </div>
</template>

<style scoped>
.flare-plugin-people { display: grid; gap: var(--flare-size-spacing-xs); min-width: 0; }
.flare-plugin-people__row { display: flex; align-items: center; gap: var(--flare-size-spacing-sm); min-width: 0; font-size: var(--flare-size-font-size-md); color: var(--flare-plugin-people-ink); }
.flare-plugin-people__row.is-neutral { --flare-plugin-people-ink: var(--flare-color-text-secondary); }
.flare-plugin-people__row.is-info { --flare-plugin-people-ink: var(--flare-color-info-text); }
.flare-plugin-people__row.is-success { --flare-plugin-people-ink: var(--flare-color-success-text); }
.flare-plugin-people__row.is-warning { --flare-plugin-people-ink: var(--flare-color-warning-text); }
.flare-plugin-people__row.is-danger { --flare-plugin-people-ink: var(--flare-color-error-text); }
.flare-plugin-people__stack { display: inline-flex; flex: none; }
/* Each avatar sits a third over the one before it, ringed in the card surface so the edge reads. */
.flare-plugin-people__avatar { border-radius: var(--flare-size-radius-full); box-shadow: 0 0 0 2px var(--flare-color-bg-primary); }
.flare-plugin-people__avatar + .flare-plugin-people__avatar { margin-inline-start: calc(var(--flare-size-spacing-sm) * -1); }
.flare-plugin-people__label { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.flare-plugin-people__count { flex: none; font-weight: var(--flare-size-font-weight-semibold); font-variant-numeric: tabular-nums; }
</style>
