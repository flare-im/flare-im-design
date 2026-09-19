<script setup>
import { computed, ref } from "vue";
import { FlareMessageBatchToolbar } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

const total = 8;
const ids = ref(["m1", "m2", "m3"]);
// What the host says it can do with a selection; an absent entry hides that action entirely.
const capabilities = { forwardEach: true, forwardMerged: true, pin: true, delete: true };
const last = ref("");
const selectAll = () => { ids.value = Array.from({ length: total }, (_, index) => `m${index + 1}`); };
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareMessageBatchToolbar
        :selected-ids="ids"
        :total="total"
        :capabilities="capabilities"
        @action="(event) => (last = event.action)"
        @select-all="selectAll"
        @clear-selection="ids = []"
        @exit="ids = []"
      />
      <p class="note">{{ last ? `最近一次操作：${last}` : "选择消息后在这里执行批量操作。" }}</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { position: relative; width: 100%; max-width: 520px; }
.note { margin: 12px 0 0; color: var(--flare-color-text-tertiary); font-size: 13px; }
</style>
