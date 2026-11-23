<script setup>
import { ref } from "vue";
import { FlareButton, FlareCallSurface, FlareCallView } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

// The surface is a window over the page, so the demo opens it on demand and closes it from the call itself.
const open = ref(false);
const mode = ref("audio");
const expanded = ref(false);
</script>

<template>
  <DemoStage>
    <div class="controls">
      <label>模式 <select v-model="mode" aria-label="模式"><option value="audio">audio</option><option value="video">video</option></select></label>
      <label><input v-model="expanded" type="checkbox" :disabled="mode !== 'video'"> 展开</label>
      <FlareButton :label="open ? '通话窗口已打开' : '打开通话窗口'" :disabled="open" @click="open = true" />
    </div>
    <FlareCallSurface v-if="open" :mode="mode" :expanded="mode === 'video' && expanded" label="Ivy Chen">
      <FlareCallView
        peer-name="Ivy Chen"
        :mode="mode"
        state="connected"
        duration-label="03:24"
        encrypted
        @minimize="open = false"
        @hangup="open = false"
      />
    </FlareCallSurface>
  </DemoStage>
</template>

<style scoped>
.controls { display: flex; flex-wrap: wrap; align-items: center; gap: var(--flare-size-spacing-md); }
label { display: inline-flex; align-items: center; gap: var(--flare-size-spacing-2xs); min-height: var(--flare-size-layout-touch-target); }
select { min-width: var(--flare-size-layout-touch-target); min-height: var(--flare-size-layout-touch-target); }
</style>
