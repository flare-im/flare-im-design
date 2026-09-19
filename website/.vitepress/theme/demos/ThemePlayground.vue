<script setup>
import { ref, onMounted, watch } from "vue";
import { useData } from "vitepress";
import {
  applyFlareTheme,
  createFlareCustomTheme,
  flareBuiltInThemes,
  flareThemeNames,
} from "../../../../tokens/theme.js";

const primary = ref("#7C3AED");
const stage = ref(null);
const active = ref("custom");
const { isDark } = useData();

function foreground(color) {
  const [r, g, b] = color.slice(1).match(/.{2}/g).map((part) => parseInt(part, 16));
  return (r * 299 + g * 587 + b * 114) / 1000 > 150 ? "#111827" : "#FFFFFF";
}
function customTheme() {
  const build = (mode) => {
    const base = structuredClone(flareBuiltInThemes.violet[mode]);
    const accent = primary.value.toUpperCase();
    base.colors.primary = accent;
    base.colors.primaryHover = accent;
    base.colors.primaryActive = accent;
    base.colors.primaryText = accent;
    base.colors.focusRing = `${accent}55`;
    base.colors.border.selected = accent;
    base.colors.text.link = accent;
    base.colors.message.outgoing = { background: accent, foreground: foreground(accent), border: accent };
    base.colors.message.selected.border = accent;
    base.colors.message.status.read = accent;
    base.colors.message.reply.border = accent;
    base.colors.message.reaction.selected = `${accent}2E`;
    return base;
  };
  return createFlareCustomTheme({ name: "custom", light: build("light"), dark: build("dark") });
}
function applyCustom() {
  active.value = "custom";
  if (stage.value) applyFlareTheme(customTheme(), isDark.value ? "dark" : "light", stage.value);
}
function usePreset(name) {
  if (!stage.value) return;
  active.value = name;
  primary.value = flareBuiltInThemes[name].light.colors.primary;
  applyFlareTheme(name, isDark.value ? "dark" : "light", stage.value);
}
function reapply() {
  if (active.value === "custom") applyCustom();
  else usePreset(active.value);
}
onMounted(applyCustom);
watch(isDark, reapply);
</script>

<template>
  <div class="tp">
    <div class="ctrl">
      <label class="pick">
        <span>主色</span>
        <input type="color" v-model="primary" @input="applyCustom" />
        <code>{{ primary.toUpperCase() }}</code>
      </label>
      <div class="presets">
        <button v-for="name in flareThemeNames" :key="name" class="chip" :class="{ active: active === name }" @click="usePreset(name)">
          <span class="dot" :style="{ background: flareBuiltInThemes[name].light.colors.primary }" />{{ name }}
        </button>
      </div>
    </div>
    <div ref="stage" class="stage">
      <ConversationHeaderDemo />
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
.chip { display: inline-flex; align-items: center; gap: 6px; padding: 5px 10px; border: 1px solid var(--vp-c-divider); border-radius: 5px; background: var(--vp-c-bg-soft); font-size: 13px; cursor: pointer; text-transform: capitalize; }
.chip:hover { border-color: var(--vp-c-brand-1); }
.chip.active { border-color: var(--vp-c-brand-1); color: var(--vp-c-text-1); }
.dot { width: 12px; height: 12px; border-radius: 50%; }
.stage { display: flex; flex-direction: column; gap: 18px; align-items: center; padding: 28px 20px; border: 1px solid var(--flare-color-border-primary); border-radius: 6px; background: var(--flare-color-bg-secondary); }
</style>
