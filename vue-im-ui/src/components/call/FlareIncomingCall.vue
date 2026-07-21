<script setup lang="ts">
import { computed } from "vue";
import { NIcon } from "naive-ui";
import { CallOutline, VideocamOutline } from "../../shared/icon-glyphs";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = defineProps<{ callerName: string; mode: "audio" | "video"; callerAvatarUrl?: string }>();
const emit = defineEmits<{ (e: "accept"): void; (e: "reject"): void }>();

const { t } = useFlareI18n();
const answerIcon = computed(() => (props.mode === "video" ? VideocamOutline : CallOutline));
const hint = computed(() => (props.mode === "video" ? t("call.invitingVideo") : t("call.invitingVoice")));
</script>

<template>
  <div class="flare-incoming">
    <div class="flare-incoming__peer">
      <div class="flare-incoming__avatar">
        <FlareAvatar :user-id="callerName" :display-name="callerName" :avatar-url="callerAvatarUrl" :size="112" />
      </div>
      <div class="flare-incoming__name">{{ callerName }}</div>
      <div class="flare-incoming__hint">{{ hint }}</div>
    </div>

    <div class="flare-incoming__actions">
      <button type="button" class="flare-incoming__col" @click="emit('reject')">
        <span class="flare-incoming__ico is-reject"><n-icon :size="28" :component="CallOutline" /></span>
        <span class="flare-incoming__lbl">{{ t("call.decline") }}</span>
      </button>
      <button type="button" class="flare-incoming__col" @click="emit('accept')">
        <span class="flare-incoming__ico is-accept"><n-icon :size="28" :component="answerIcon" /></span>
        <span class="flare-incoming__lbl">{{ t("call.answer") }}</span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.flare-incoming {
  position: relative;
  width: 100%;
  height: 100%;
  min-height: 460px;
  color: #fff;
  overflow: hidden;
  background:
    radial-gradient(120% 70% at 50% -6%, rgba(124, 58, 237, 0.34), transparent 60%),
    linear-gradient(168deg, #221d31 0%, #17131f 46%, #100c17 100%);
}
.flare-incoming__peer {
  position: absolute;
  top: 104px;
  left: 0;
  right: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 14px;
}
.flare-incoming__avatar {
  position: relative;
  border-radius: 50%;
  box-shadow: 0 0 0 6px rgba(255, 255, 255, 0.08), 0 18px 44px rgba(0, 0, 0, 0.42);
}
.flare-incoming__avatar::before,
.flare-incoming__avatar::after {
  content: "";
  position: absolute;
  inset: -6px;
  border-radius: 50%;
  border: 2px solid rgba(167, 139, 250, 0.5);
  animation: flare-incoming-pulse 2s ease-out infinite;
}
.flare-incoming__avatar::after {
  animation-delay: 1s;
}
@keyframes flare-incoming-pulse {
  0% { transform: scale(1); opacity: 0.7; }
  100% { transform: scale(1.5); opacity: 0; }
}
@media (prefers-reduced-motion: reduce) {
  .flare-incoming__avatar::before,
  .flare-incoming__avatar::after { animation: none; }
}
.flare-incoming__name {
  font-size: 24px;
  font-weight: 600;
}
.flare-incoming__hint {
  color: rgba(255, 255, 255, 0.72);
  font-size: 14px;
}
.flare-incoming__actions {
  position: absolute;
  bottom: 52px;
  left: 0;
  right: 0;
  display: flex;
  justify-content: space-evenly;
}
.flare-incoming__col {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  border: 0;
  background: none;
  cursor: pointer;
}
.flare-incoming__ico {
  display: grid;
  place-items: center;
  width: 64px;
  height: 64px;
  border-radius: 50%;
  color: #fff;
  transition: transform var(--flare-transition-fast, 150ms ease), filter var(--flare-transition-fast, 150ms ease);
}
.flare-incoming__col:active .flare-incoming__ico {
  transform: scale(0.92);
}
.flare-incoming__ico.is-reject {
  background: linear-gradient(160deg, #ff5a5f, #e2373c);
  box-shadow: 0 10px 26px rgba(226, 55, 60, 0.42);
  transform: rotate(135deg);
}
.flare-incoming__ico.is-reject :deep(svg) {
  transform: rotate(-135deg);
}
.flare-incoming__col:active .flare-incoming__ico.is-reject {
  transform: rotate(135deg) scale(0.92);
}
.flare-incoming__ico.is-accept {
  background: linear-gradient(160deg, #34d17f, #16a34a);
  box-shadow: 0 10px 26px rgba(22, 163, 74, 0.42);
  animation: flare-incoming-bob 1.4s ease-in-out infinite;
}
@keyframes flare-incoming-bob {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-4px); }
}
@media (prefers-reduced-motion: reduce) {
  .flare-incoming__ico.is-accept { animation: none; }
}
.flare-incoming__lbl {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.82);
}
</style>
