<script setup>
import { ref } from "vue";
import FlareCallView from "@flare-im/vue-ui/components/call/FlareCallView.vue";
import DemoStage from './DemoStage.vue';
const state = ref('connected');
const ended = ref(0);
</script>
<template>
  <DemoStage>
  <section class="call-recovery-demo">
    <label>通话状态 <select v-model="state" aria-label="通话状态"><option v-for="value in ['calling','ringing','connected','reconnecting','failed']" :key="value">{{ value }}</option></select></label>
    <p>本地状态演示，不建立 RTC 通话。挂断 {{ ended }} 次</p>
    <div class="stage">
      <FlareCallView peer-name="Ivy Chen" mode="video" :state="state" duration-label="03:24" :camera-on="true"
        :status-detail="state === 'reconnecting' ? '网络不稳定，正在恢复媒体连接' : undefined" recovery-text="重新连接" @recover="state = 'reconnecting'" @hangup="ended++" />
    </div>
  </section>
  </DemoStage>
</template>
<style scoped>
.stage { width: 100%; max-width: 400px; }
select { min-height:48px; }
</style>
