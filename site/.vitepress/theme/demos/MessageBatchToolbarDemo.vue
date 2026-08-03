<script setup>
import { ref } from "vue";
import FlareMessageBatchToolbar from "@flare-im/vue-ui/components/messages/FlareMessageBatchToolbar.vue";
import DemoStage from "./DemoStage.vue";
const count = ref(3);
const total = 8;
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareMessageBatchToolbar
        :count="count"
        :total="total"
        @select-all="count = total"
        @forward-each="() => {}"
        @forward-merged="() => {}"
        @delete="() => {}"
        @exit="count = 0"
      />
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
