<script setup>
import { ref } from "vue";
import FlareMomentActionPopover from "@flare-im/vue-ui/components/moments/FlareMomentActionPopover.vue";
import DemoStage from "./DemoStage.vue";
const liked = ref(false);
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareMomentActionPopover :liked="liked" @like="liked = !liked" @comment="() => {}" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { display: flex; justify-content: center; padding: 32px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
