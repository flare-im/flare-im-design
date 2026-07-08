<script setup>
import { ref, onMounted, watch } from "vue";
import { deriveFlareTheme, flarePresets, applyFlareTheme } from "../../../../tokens/theme.js";

const presets = flarePresets;
const primary = ref("#7C3AED");
const stage = ref(null);

function apply() {
  if (stage.value) applyFlareTheme(deriveFlareTheme({ primary: primary.value }), stage.value);
}
function usePreset(name) {
  if (!stage.value) return;
  applyFlareTheme(presets[name], stage.value);
  primary.value = presets[name].primary;
}
onMounted(apply);
watch(primary, apply);
</script>

<template>
  <div class="tp">
    <div class="ctrl">
      <label class="pick">
        <span>主色</span>
        <input type="color" v-model="primary" />
        <code>{{ primary.toUpperCase() }}</code>
      </label>
      <div class="presets">
        <button v-for="(_, name) in presets" :key="name" class="chip" @click="usePreset(name)">
          <span class="dot" :style="{ background: presets[name].primary }" />{{ name }}
        </button>
      </div>
    </div>
    <div ref="stage" class="stage">
      <ChatHeaderDemo />
      <MessageBubbleDemo />
      <ConversationRowDemo />
      <ComposerDemo />
    </div>
  </div>
</template>

<style scoped>
.tp { width: 100%; display: flex; flex-direction: column; gap: 20px; }
.ctrl { display: flex; flex-wrap: wrap; gap: 16px; align-items: center; }
.pick { display: flex; align-items: center; gap: 8px; font-size: 14px; color: var(--vp-c-text-1); }
.pick input[type="color"] { width: 40px; height: 28px; border: 1px solid var(--vp-c-divider); border-radius: 6px; background: none; cursor: pointer; }
.presets { display: flex; flex-wrap: wrap; gap: 8px; }
.chip { display: inline-flex; align-items: center; gap: 6px; padding: 4px 12px; border: 1px solid var(--vp-c-divider); border-radius: 999px; background: var(--vp-c-bg-soft); font-size: 13px; cursor: pointer; text-transform: capitalize; }
.chip:hover { border-color: var(--vp-c-brand-1); }
.dot { width: 12px; height: 12px; border-radius: 50%; }
.stage { display: flex; flex-direction: column; gap: 18px; align-items: center; padding: 28px 20px; border: 1px solid var(--vp-c-divider); border-radius: 14px; background:
  radial-gradient(circle at 1px 1px, var(--vp-c-divider) 1px, transparent 0) 0 0 / 16px 16px; }
</style>
