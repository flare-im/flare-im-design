<script setup>
import { ref } from "vue";
import FlareSearchBar from "@flare-im/vue-ui/components/general/FlareSearchBar.vue";
import DemoStage from "./DemoStage.vue";

const q = ref("");
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareSearchBar v-model="q" placeholder="搜索联系人、群组、消息" />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 360px; }
</style>
