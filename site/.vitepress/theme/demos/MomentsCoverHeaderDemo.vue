<script setup>
import FlareMomentsCoverHeader from "@flare-im/vue-ui/components/moments/FlareMomentsCoverHeader.vue";
import DemoStage from "./DemoStage.vue";
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareMomentsCoverHeader user-id="ivy" name="Ivy Chen" signature="设计即沟通 · 一套契约四端实现" @edit-cover="() => {}" @avatar="() => {}" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { max-width: 420px; margin: 0 auto; border-radius: 14px; overflow: hidden; background: var(--flare-color-bg-primary); border: 1px solid var(--flare-color-border-primary); }
</style>
