<script setup>
import { ref } from "vue";
import FlareInput from "@flare-im/vue-ui/components/general/FlareInput.vue";
import DemoStage from "./DemoStage.vue";

const text = ref("Flare IM 组件库");
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareInput v-model="text" placeholder="请输入…" :max-length="40" clearable />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 360px; }
</style>
