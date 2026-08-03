<script setup>
import { ref } from "vue";
import FlareChatWallpaperPicker from "@flare-im/vue-ui/components/conversation/FlareChatWallpaperPicker.vue";
import DemoStage from "./DemoStage.vue";
const options = [
  { id: "default", color: "#f6f5fb", label: "默认" },
  { id: "violet", color: "linear-gradient(160deg,#ede9fe,#c4b5fd)" },
  { id: "dusk", color: "linear-gradient(160deg,#312e81,#7c3aed)" },
  { id: "rose", color: "linear-gradient(160deg,#ffe4e6,#fb7185)" },
  { id: "mint", color: "linear-gradient(160deg,#d1fae5,#34d399)" },
  { id: "sand", color: "linear-gradient(160deg,#fef3c7,#f59e0b)" },
  { id: "sky", color: "linear-gradient(160deg,#e0f2fe,#38bdf8)" },
  { id: "ink", color: "linear-gradient(160deg,#1f2937,#4b5563)" },
];
const selected = ref("violet");
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareChatWallpaperPicker :options="options" :selected-id="selected" @select="(id) => (selected = id)" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { display: flex; justify-content: center; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
