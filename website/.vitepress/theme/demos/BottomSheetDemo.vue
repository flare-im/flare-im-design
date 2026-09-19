<script setup>
import { ref } from "vue";
import { FlareBottomSheet, FlareButton } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
const open = ref(false);
</script>
<template>
  <DemoStage>
    <FlareButton label="打开底部面板" @click="open = true" />
    <FlareBottomSheet :open="open" title="选择通知方式" max-height="60vh" @close="open = false">
      <ul class="list">
        <li v-for="item in ['所有消息', '仅 @ 我', '静音']" :key="item"><button type="button" class="row" @click="open = false">{{ item }}</button></li>
      </ul>
    </FlareBottomSheet>
  </DemoStage>
</template>
<style scoped>
.list { list-style: none; margin: 0; padding: 8px 0 16px; }
.row { width: 100%; min-height: 48px; padding: 0 16px; border: 0; background: none; text-align: left; font-size: var(--flare-size-font-size-lg); color: var(--flare-color-text-primary); cursor: pointer; }
.row:hover { background: var(--flare-color-bg-hover); }
</style>
