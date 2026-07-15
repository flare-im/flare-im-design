<script setup>
import { reactive } from "vue";
import FlareRedPacketCard from "flare-core-vue-im-ui/components/messages/FlareRedPacketCard.vue";
import DemoStage from "./DemoStage.vue";
const state = reactive({ opened: false });
</script>
<template>
  <DemoStage>
    <div class="stack">
      <FlareRedPacketCard
        blessing="恭喜发财，大吉大利"
        :opened="state.opened"
        amount="¥8.88"
        @open="state.opened = true"
      />
      <FlareRedPacketCard blessing="新年快乐 🎊" finished />
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; gap: 14px; align-items: flex-start; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
