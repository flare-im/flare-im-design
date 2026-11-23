<script setup>
import { FlareIncomingCall } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
</script>

<template>
  <DemoStage>
    <div class="row">
      <!-- Phones: the full-screen presentation. -->
      <div class="stage">
        <FlareIncomingCall caller-name="Ivy Chen" mode="video" />
      </div>
      <!-- PC: the non-modal banner. A transform makes this frame its containing block, so the banner's
           fixed position lands in the frame's top trailing corner instead of the docs page's. -->
      <div class="banner-frame">
        <FlareIncomingCall caller-name="Ivy Chen" mode="audio" presentation="banner" />
      </div>
    </div>
  </DemoStage>
</template>

<style scoped>
.row { display: flex; flex-wrap: wrap; gap: var(--flare-size-spacing-2xl); align-items: flex-start; width: 100%; }
.stage { width: 100%; max-width: 320px; height: 560px; }
.banner-frame { position: relative; transform: translateZ(0); flex: 1 1 400px; min-height: 140px; border-radius: var(--flare-size-radius-card); background: var(--flare-color-bg-secondary); }
</style>
