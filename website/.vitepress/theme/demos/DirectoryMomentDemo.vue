<script setup>
import { computed } from "vue";
import {
  FlareAnnouncementReadBar,
  FlareContactMatchList,
  FlareMomentsVisibilityRuleList,
  FlareMomentAudienceSheet,
} from "@flare-im/vue-ui";
import DemoStage from "./DemoStage.vue";

const props = defineProps({
  component: { type: String, required: true },
  previewState: { type: String, default: "ready" },
});
const contacts = [
  { userId: "ivy", displayName: "Ivy Chen", matchedBy: "+86 138 **** 1204", alreadyFriend: true },
  { userId: "leo", displayName: "Leo Wang", matchedBy: "leo@example.com", alreadyFriend: false },
];
const loading = computed(() => props.previewState === "loading");
const empty = computed(() => props.previewState === "empty");
</script>

<template>
  <DemoStage>
    <div class="directory-demo">
      <FlareMomentsVisibilityRuleList
        v-if="component === 'MomentsVisibilityRuleList'"
        kind="hideFrom"
        :members="empty ? [] : contacts"
        :loading="loading"
      />
      <FlareContactMatchList
        v-else-if="component === 'ContactMatchList'"
        :matches="empty ? [] : contacts"
        :loading="loading"
      />
      <FlareAnnouncementReadBar
        v-else-if="component === 'AnnouncementReadBar'"
        :read-count="previewState === 'read' ? 12 : 7"
        :member-count="12"
        :self-read="previewState === 'read'"
        can-view-unread
      />
      <FlareMomentAudienceSheet
        v-else
        :visibility="0"
        :audience-mode="previewState === 'picking' ? 1 : 0"
        :audience-user-ids="previewState === 'picking' ? ['ivy'] : []"
        :contacts="contacts"
        :open="previewState === 'picking'"
      />
    </div>
  </DemoStage>
</template>

<style scoped>
.directory-demo { width: 100%; max-width: 520px; margin-inline: auto; overflow: auto; background: var(--flare-color-bg-primary); }
</style>
