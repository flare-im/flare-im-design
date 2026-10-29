<script setup>
import { ref } from "vue";
import { FlareCallRecordCard } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// 通话记录按查看者视角显示一行状态：主叫看到「对方未接听 / 对方已拒绝」，被叫看到「未接听 / 已拒绝」；
// 被叫的未接来电用危险色。进行中的群通话、查看者不在其中时显示「加入」，已结束的单聊显示「回拨」；
// 点击后宿主发起操作，处理中按钮显示进度且不再响应。插件不可用时记录保留、操作消失。
const joining = ref(false);
const callingBack = ref(false);
</script>
<template>
  <DemoStage>
    <div class="stack">
      <FlareCallRecordCard
        media="audio"
        scope="single"
        state="ended"
        end-reason="completed"
        :duration-seconds="192"
        viewer-is-initiator
        :can-join="false"
        can-call-back
        :busy="callingBack"
        @call-back="callingBack = !callingBack"
      />
      <FlareCallRecordCard
        media="video"
        scope="single"
        state="ended"
        end-reason="missed"
        :viewer-is-initiator="false"
        :can-join="false"
        can-call-back
      />
      <FlareCallRecordCard media="audio" scope="single" state="ringing" viewer-is-initiator :can-join="false" :can-call-back="false" />
      <FlareCallRecordCard
        media="video"
        scope="group"
        state="ongoing"
        :joined-count="3"
        :viewer-is-initiator="false"
        can-join
        :can-call-back="false"
        :busy="joining"
        @join="joining = !joining"
      />
      <FlareCallRecordCard
        media="audio"
        scope="group"
        state="ended"
        end-reason="completed"
        :duration-seconds="754"
        :viewer-is-initiator="false"
        :can-join="false"
        :can-call-back="false"
      />
      <FlareCallRecordCard
        media="audio"
        scope="single"
        state="ended"
        end-reason="declined"
        viewer-is-initiator
        :can-join="false"
        can-call-back
        disabled
      />
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; gap: 14px; align-items: flex-start; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
