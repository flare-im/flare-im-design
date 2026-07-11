<script setup>
import FlareTimeStamp from "flare-core-vue-im-ui/components/messages/TimeStamp.vue";
import DemoStage from "./DemoStage.vue";

const labels = ["刚刚", "14:32", "昨天", "周三", "6/28"];
</script>

<template>
  <DemoStage>
    <div class="ts-row">
      <FlareTimeStamp v-for="l in labels" :key="l" :label="l" />
    </div>
  </DemoStage>
</template>

<style scoped>
.ts-row { display: flex; gap: 10px; flex-wrap: wrap; justify-content: center; align-items: center; }
</style>
