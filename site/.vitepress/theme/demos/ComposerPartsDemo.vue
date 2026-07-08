<script setup>
import { ref } from "vue";
import DemoIcon from "./DemoIcon.vue";
// Free composition: only the parts this product needs — a voice hold button and
// an action panel — assembled by hand instead of using the complete Composer.
const holding = ref(false);
const cancel = ref(false);
const log = ref("");
const actions = [
  { k: "image", label: "图片", icon: "image" },
  { k: "file", label: "文件", icon: "folder" },
  { k: "task", label: "任务", icon: "task" },
];
function down() { holding.value = true; cancel.value = false; }
function move(e) { if (holding.value) cancel.value = e.offsetY < -30; }
function up() {
  if (!holding.value) return;
  log.value = cancel.value ? "已取消发送" : "语音已发送 · 2\"";
  holding.value = false; cancel.value = false;
}
</script>

<template>
  <div class="wrap">
    <div class="parts">
      <div class="part">
        <div class="cap">FlareVoiceHoldButton</div>
        <button
          class="hold" :class="{ holding, cancel }"
          @pointerdown="down" @pointermove="move" @pointerup="up" @pointerleave="up"
        >
          <DemoIcon name="mic" :size="17" />
          <span>{{ holding ? (cancel ? "松开取消" : "松开发送 · 上滑取消") : "按住 说话" }}</span>
        </button>
      </div>

      <div class="part">
        <div class="cap">FlareComposerActionPanel</div>
        <div class="grid">
          <button v-for="a in actions" :key="a.k" @click="log = `选择了 ${a.label}`">
            <span class="tico"><DemoIcon :name="a.icon" :size="20" /></span>
            <span class="tlbl">{{ a.label }}</span>
          </button>
        </div>
      </div>

      <div class="part">
        <div class="cap">FlareComposerSendButton</div>
        <div class="sendrow">
          <button class="send off"><DemoIcon name="send" :size="16" /></button>
          <button class="send" @click="log = '已发送'"><DemoIcon name="send" :size="16" /></button>
          <span class="note">禁用 / 可发送</span>
        </div>
      </div>
    </div>
    <div class="echo">{{ log || "各部件独立可用，自行组装成产品需要的输入框" }}</div>
  </div>
</template>

<style scoped>
.wrap { width: 100%; max-width: 460px; }
.parts { display: flex; flex-direction: column; gap: 16px; }
.part { border: 1px dashed var(--flare-color-border-primary); border-radius: 12px; padding: 12px; }
.cap { font-size: 11px; font-family: var(--vp-font-family-mono, monospace); color: var(--flare-color-text-tertiary); margin-bottom: 8px; }
.hold { width: 100%; display: flex; align-items: center; justify-content: center; gap: 8px; height: 40px; border: none; border-radius: 12px; background: var(--flare-color-bg-secondary); color: var(--flare-color-text-secondary); font-size: 14px; font-weight: 500; cursor: pointer; touch-action: none; user-select: none; }
.hold.holding { background: var(--flare-color-bg-selected); color: var(--flare-color-primary); }
.hold.cancel { background: color-mix(in srgb, var(--flare-color-error) 12%, transparent); color: var(--flare-color-error); }
.grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; }
.grid button { display: flex; flex-direction: column; align-items: center; gap: 6px; border: none; background: none; cursor: pointer; }
.tico { width: 48px; height: 48px; border-radius: 12px; background: var(--flare-color-bg-secondary); display: flex; align-items: center; justify-content: center; color: var(--flare-color-text-secondary); }
.tlbl { font-size: 12px; color: var(--flare-color-text-secondary); }
.sendrow { display: flex; align-items: center; gap: 10px; }
.send { width: 34px; height: 34px; border: none; border-radius: 50%; background: var(--flare-color-primary); color: #fff; display: flex; align-items: center; justify-content: center; cursor: pointer; }
.send.off { background: var(--flare-color-bg-disabled); color: var(--flare-color-text-disabled); }
.note { font-size: 11px; color: var(--flare-color-text-tertiary); }
.echo { margin-top: 12px; font-size: 12px; color: var(--flare-color-text-tertiary); }
</style>
