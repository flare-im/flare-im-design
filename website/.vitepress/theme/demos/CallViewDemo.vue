<script setup>
import { ref } from "vue";
import { FlareCallView } from "@flare-im/vue-ui/components";
import DemoStage from './DemoStage.vue';
const state = ref('connected');
const mode = ref('video');
const peerMuted = ref(false);
const peerSpeaking = ref(true);
const ended = ref(0);
</script>
<template>
  <DemoStage>
  <section class="call-recovery-demo">
    <label>通话状态 <select v-model="state" aria-label="通话状态"><option v-for="value in ['calling','ringing','connected','reconnecting','failed']" :key="value">{{ value }}</option></select></label>
    <label>模式 <select v-model="mode" aria-label="模式"><option value="video">video</option><option value="audio">audio</option></select></label>
    <label><input v-model="peerMuted" type="checkbox"> 对方已静音</label>
    <label><input v-model="peerSpeaking" type="checkbox"> 对方在说话</label>
    <p>本地状态演示，不建立 RTC 通话。挂断 {{ ended }} 次</p>
    <div class="stage">
      <FlareCallView peer-name="Ivy Chen" :mode="mode" :state="state" duration-label="03:24" :camera-on="true"
        :peer-muted="peerMuted" :peer-speaking="peerSpeaking" can-start-video @start-video="mode = 'video'"
        :status-detail="state === 'reconnecting' ? '网络不稳定，正在恢复媒体连接' : undefined" recovery-text="重新连接" @recover="state = 'reconnecting'" @hangup="ended++">
        <template #localVideo>
          <div class="self-preview" role="img" aria-label="本端画面" />
        </template>
      </FlareCallView>
    </div>
  </section>
  </DemoStage>
</template>
<style scoped>
.stage { width: 100%; max-width: 400px; }
select { min-width: 48px; min-height: 48px; }
label { display: inline-flex; align-items: center; gap: 6px; min-height: 48px; margin-inline-end: 12px; }
.self-preview { width: 100%; height: 100%; background: linear-gradient(160deg, #3a4a63, #1c2230); }
</style>
