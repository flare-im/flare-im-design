<script setup lang="ts">
import FlareAvatar from "../conversation/FlareAvatar.vue";

defineProps<{ callerName: string; mode: "audio" | "video"; callerAvatarUrl?: string }>();
const emit = defineEmits<{ (e: "accept"): void; (e: "reject"): void }>();
</script>

<template>
  <div class="flare-incoming">
    <div class="flare-incoming__peer">
      <FlareAvatar :user-id="callerName" :display-name="callerName" :avatar-url="callerAvatarUrl" :size="104" />
      <div class="flare-incoming__name">{{ callerName }}</div>
      <div class="flare-incoming__hint">{{ mode === "video" ? "邀请你视频通话" : "邀请你语音通话" }}</div>
    </div>
    <div class="flare-incoming__actions">
      <div class="flare-incoming__col" @click="emit('reject')">
        <span class="flare-incoming__ico is-reject">📵</span>
        <span class="flare-incoming__lbl">拒绝</span>
      </div>
      <div class="flare-incoming__col" @click="emit('accept')">
        <span class="flare-incoming__ico is-accept">{{ mode === "video" ? "📹" : "📞" }}</span>
        <span class="flare-incoming__lbl">接听</span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.flare-incoming {
  position: relative; width: 100%; height: 100%; min-height: 420px;
  background: #111318; color: #fff; overflow: hidden;
}
.flare-incoming__peer {
  position: absolute; top: 96px; left: 0; right: 0;
  display: flex; flex-direction: column; align-items: center; gap: 12px;
}
.flare-incoming__name { font-size: 22px; font-weight: 600; }
.flare-incoming__hint { color: rgba(255, 255, 255, 0.7); font-size: 14px; }
.flare-incoming__actions {
  position: absolute; bottom: 48px; left: 0; right: 0; display: flex; justify-content: space-evenly;
}
.flare-incoming__col { display: flex; flex-direction: column; align-items: center; gap: 8px; cursor: pointer; }
.flare-incoming__ico {
  width: 60px; height: 60px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center; font-size: 24px;
}
.flare-incoming__ico.is-reject { background: #ef4444; }
.flare-incoming__ico.is-accept { background: #22c55e; }
.flare-incoming__lbl { font-size: 13px; color: rgba(255, 255, 255, 0.8); }
</style>
