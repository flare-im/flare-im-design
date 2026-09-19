<script setup lang="ts">
import { ref } from "vue";
import { FlareButton, FlareInput, FlareTextarea, FlareSearchBar, FlareSelect, FlareMomentActionPopover, FlareComposerMediaPreview, FlareFormSheet } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
const input = ref("Ivy Chen");
const query = ref("");
const note = ref("Review the attachment and confirm the delivery time.");
const selection = ref("all");
const mediaOpen = ref(false);
const sheetOpen = ref(false);
const options = [{ value: "all", label: "All messages" }, { value: "unread", label: "Unread messages" }, { value: "muted", label: "Muted conversations" }];
</script>

<template>
  <DemoStage>
    <main id="surface-integrity-fixture">
      <FlareInput v-model="input" clearable placeholder="Display name" />
      <FlareSearchBar v-model="query" placeholder="Search messages" />
      <FlareTextarea v-model="note" show-count :maxlength="200" :rows="2" :max-rows="4" placeholder="Message note" />
      <FlareSelect v-model="selection" :options="options" title="Message filter" />
      <FlareMomentActionPopover can-delete />
      <div class="fixture-actions">
        <FlareButton @click="mediaOpen = true">Attachment preview</FlareButton>
        <FlareButton variant="secondary" @click="sheetOpen = true">Edit note</FlareButton>
      </div>
      <FlareComposerMediaPreview :show="mediaOpen" kind="file" :items="[{ id: 'review', name: 'surface-review.pdf', kind: 'file', size: 24576 }]" @update:show="mediaOpen = $event" @submit="mediaOpen = false" />
      <FlareFormSheet :open="sheetOpen" title="Edit note" @close="sheetOpen = false" @confirm="sheetOpen = false">
        <FlareTextarea v-model="note" placeholder="Edit message note" :max-rows="4" />
      </FlareFormSheet>
    </main>
  </DemoStage>
</template>

<style scoped>
#surface-integrity-fixture { display: grid; gap: 20px; width: min(540px, 100%); box-sizing: border-box; padding: 24px; background: var(--flare-color-bg-secondary); color: var(--flare-color-text-primary); }
.fixture-actions { display: flex; flex-wrap: wrap; gap: 12px; }
</style>
