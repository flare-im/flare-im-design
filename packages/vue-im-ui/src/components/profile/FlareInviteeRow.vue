<script setup lang="ts">
import { computed, ref, useId } from "vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";
import {
  inviteJoinedDateLabel,
  type FlareInvitee,
  type FlareLoadInviteChildren,
} from "../../shared/contracts/invite";
import { flareIcons } from "../../shared/icons";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

const props = defineProps<{
  invitee: FlareInvitee;
  depth: number;
  maxDepthShown: number;
  loadChildren?: FlareLoadInviteChildren;
}>();
const emit = defineEmits<{ (e: "select", userId: string): void }>();
const { t } = useFlareI18nOptional();
const branchId = useId();
const expanded = ref(false);
const children = ref<FlareInvitee[] | null>(null);
const nextCursor = ref<string>();
const loading = ref(false);
const failed = ref(false);

const canExpand = computed(() =>
  props.invitee.hasChildren === true && props.depth < props.maxDepthShown && !!props.loadChildren,
);
const joined = computed(() => props.invitee.joinedAt > 0
  ? t("myInvite.joined", { date: inviteJoinedDateLabel(props.invitee.joinedAt) })
  : "",
);

async function loadPage() {
  const loadChildren = props.loadChildren;
  if (!loadChildren || !canExpand.value || loading.value) return;
  const cursor = nextCursor.value;
  loading.value = true;
  failed.value = false;
  try {
    const page = await loadChildren(props.invitee.userId, cursor);
    const entries = children.value ?? [];
    const seen = new Set(entries.map((entry) => entry.userId));
    children.value = [...entries, ...page.invitees.filter((entry) => {
      if (seen.has(entry.userId)) return false;
      seen.add(entry.userId);
      return true;
    })];
    nextCursor.value = page.nextCursor && page.nextCursor !== cursor ? page.nextCursor : undefined;
  } catch {
    failed.value = true;
  } finally {
    loading.value = false;
  }
}

function toggleBranch() {
  expanded.value = !expanded.value;
  if (expanded.value && children.value === null && !failed.value) void loadPage();
}
</script>

<template>
  <li class="flare-my-invite__row">
    <div class="flare-my-invite__row-actions">
      <button type="button" class="flare-my-invite__person" @click="emit('select', invitee.userId)">
        <FlareAvatar
          :user-id="invitee.userId"
          :display-name="invitee.displayName"
          :avatar-url="invitee.avatarUrl"
          :size="44"
        />
        <span class="flare-my-invite__person-text">
          <span class="flare-my-invite__name">{{ invitee.displayName }}</span>
          <span v-if="joined" class="flare-my-invite__joined">{{ joined }}</span>
        </span>
      </button>
      <FlareIconButton
        v-if="canExpand"
        :icon="expanded ? flareIcons['chevron-down'] : flareIcons['chevron-right']"
        :ariaLabel="t(expanded ? 'myInvite.collapseBranch' : 'myInvite.expandBranch', { name: invitee.displayName })"
        :aria-expanded="expanded"
        :aria-controls="branchId"
        :custom-size="44"
        @click="toggleBranch"
      />
    </div>

    <div
      v-if="canExpand"
      v-show="expanded"
      :id="branchId"
      class="flare-my-invite__children"
      :aria-busy="loading || undefined"
    >
      <ul v-if="children?.length" class="flare-my-invite__child-list">
        <FlareInviteeRow
          v-for="child in children"
          :key="child.userId"
          :invitee="child"
          :depth="depth + 1"
          :max-depth-shown="maxDepthShown"
          :load-children="loadChildren"
          @select="emit('select', $event)"
        />
      </ul>
      <FlareStatusBanner
        v-if="failed"
        :text="t('myInvite.branchFailed')"
        tone="warning"
        :action-text="t('common.retry')"
        @action="loadPage"
      />
      <FlareButton
        v-else-if="nextCursor"
        variant="ghost"
        size="sm"
        :label="t('myInvite.loadMore')"
        :loading="loading"
        :disabled="loading"
        @click="loadPage"
      />
      <p v-else-if="loading" class="flare-my-invite__child-status" role="status">{{ t("myInvite.loading") }}</p>
      <p v-else-if="children?.length === 0" class="flare-my-invite__child-status" role="status">{{ t("myInvite.branchEmpty") }}</p>
    </div>
  </li>
</template>

<style scoped>
.flare-my-invite__row + .flare-my-invite__row { border-top: 1px solid var(--flare-color-border-secondary); }
.flare-my-invite__row-actions { display: flex; align-items: center; gap: var(--flare-size-spacing-xs); }
.flare-my-invite__person {
  display: flex;
  align-items: center;
  flex: 1;
  min-width: 0;
  min-height: var(--flare-size-layout-touch-target);
  gap: var(--flare-size-spacing-md);
  padding: var(--flare-size-spacing-sm) 0;
  border: 0;
  border-radius: var(--flare-size-radius-sm);
  background: none;
  color: inherit;
  font: inherit;
  text-align: start;
  cursor: pointer;
}
.flare-my-invite__person:hover { background: var(--flare-color-bg-hover); }
.flare-my-invite__person:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
.flare-my-invite__person-text { display: grid; gap: 2px; min-width: 0; }
.flare-my-invite__name { font-size: var(--flare-size-font-size-lg); font-weight: 500; overflow-wrap: anywhere; }
.flare-my-invite__joined { font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-tertiary); }
.flare-my-invite__children {
  margin-inline-start: var(--flare-size-spacing-md);
  padding-inline-start: var(--flare-size-spacing-md);
  padding-block-end: var(--flare-size-spacing-xs);
  border-inline-start: 1px solid var(--flare-color-border-secondary);
}
.flare-my-invite__child-list { list-style: none; padding: 0; margin: 0; }
.flare-my-invite__child-status {
  margin: 0;
  padding-block: var(--flare-size-spacing-sm);
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-sm);
}
</style>
