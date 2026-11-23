<script setup>
import { computed, ref } from "vue";
import { useRoute } from "vitepress";
import { FlareMomentComposer } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
const sw = (a, b) => "data:image/svg+xml;utf8," + encodeURIComponent(
  `<svg xmlns='http://www.w3.org/2000/svg' width='80' height='80'><rect width='80' height='80' fill='${a}'/></svg>`.replace(/#/g, "%23"));
const location = ref("上海 · 徐汇");
const route = useRoute();
const failed = ref(false);
const en = computed(() => route.path.startsWith("/en/"));
const error = computed(() => failed.value ? (en.value ? "Could not post. Your draft is retained." : "发表失败，草稿已保留") : "");
const images = ref([sw("#a78bfa"), sw("#fca5a5"), sw("#6ee7b7")]);
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareMomentComposer layout="page" :images="images" v-model:location="location" location-editable :submit-error="error" :visibility="en ? 'Public' : '公开'" @submit="failed = !failed" @cancel="() => {}" @add-image="images.push(sw('#6ee7b7'))" @remove-image="images.splice($event, 1)" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { width: 100%; max-width: var(--flare-size-layout-modal-width-dialog); height: 560px; margin-inline: auto; border: 1px solid var(--flare-color-border-primary); border-radius: var(--flare-size-radius-lg); overflow: hidden; background: var(--flare-color-bg-secondary); }
</style>
