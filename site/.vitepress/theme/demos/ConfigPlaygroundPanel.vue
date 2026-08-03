<script setup>
// Lives INSIDE a <FlareConfigProvider> so useFlareConfig() injects the live
// api. Shows how one root provider drives size + language + theme for every
// descendant kit component at once.
import { computed } from "vue";
import { useFlareConfig } from "@flare-im/vue-ui/shared/useFlareConfig";
import { useFlareAdaptive } from "@flare-im/vue-ui/composables/useAdaptiveMode";
import FlareButton from "@flare-im/vue-ui/components/general/FlareButton.vue";
import FlareIconButton from "@flare-im/vue-ui/components/general/FlareIconButton.vue";
import FlareSelect from "@flare-im/vue-ui/components/form/FlareSelect.vue";
import { SendOutline } from "@vicons/ionicons5";

const cfg = useFlareConfig();
const adaptive = useFlareAdaptive();
const sizes = ["sm", "md", "lg"];
const zh = computed(() => cfg.locale.value === "zh-CN");
const opts = computed(() =>
  zh.value
    ? [{ value: "a", label: "选项 A" }, { value: "b", label: "选项 B" }]
    : [{ value: "a", label: "Option A" }, { value: "b", label: "Option B" }],
);
const pick = computed(() => (zh.value ? "请选择" : "Select"));
const sendLabel = computed(() => (zh.value ? "发送" : "Send"));
const secondaryLabel = computed(() => (zh.value ? "取消" : "Cancel"));
</script>

<template>
  <div class="panel">
    <div class="toolbar">
      <div class="group">
        <span class="k">{{ zh ? "语言" : "Language" }}</span>
        <button class="seg" :class="{ on: zh }" @click="cfg.setLocale('zh-CN')">中文</button>
        <button class="seg" :class="{ on: !zh }" @click="cfg.setLocale('en-US')">EN</button>
      </div>
      <div class="group">
        <span class="k">{{ zh ? "主题" : "Theme" }}</span>
        <button class="seg wide" @click="cfg.toggleTheme()">
          {{ cfg.isDark.value ? (zh ? "🌙 深色" : "🌙 Dark") : (zh ? "☀️ 浅色" : "☀️ Light") }}
        </button>
      </div>
      <div class="group">
        <span class="k">{{ zh ? "尺寸" : "Size" }}</span>
        <button v-for="s in sizes" :key="s" class="seg" :class="{ on: cfg.size.value === s }" @click="cfg.setSize(s)">{{ s }}</button>
      </div>
      <div class="group">
        <span class="k">{{ zh ? "视口" : "Viewport" }}</span>
        <button class="seg" :class="{ on: !adaptive.isH5.value }" @click="adaptive.setLayoutMode('pc')">PC</button>
        <button class="seg" :class="{ on: adaptive.isH5.value }" @click="adaptive.setLayoutMode('h5')">H5</button>
      </div>
    </div>
    <p class="hint">{{ adaptive.isH5.value ? (zh ? "H5 视口:Select 以底部 Sheet 展示 ↓" : "H5 viewport: Select opens as a bottom sheet ↓") : (zh ? "PC 视口:Select 以下拉展示 ↓" : "PC viewport: Select opens as a dropdown ↓") }}</p>

    <div class="preview">
      <FlareButton :label="sendLabel" :icon="SendOutline" />
      <FlareButton :label="secondaryLabel" variant="secondary" />
      <FlareSelect :options="opts" :placeholder="pick" />
      <FlareIconButton :icon="SendOutline" variant="tinted" :aria-label="sendLabel" />
    </div>

    <p class="readout">
      locale=<code>{{ cfg.locale.value }}</code> · theme=<code>{{ cfg.isDark.value ? "dark" : "light" }}</code> · size=<code>{{ cfg.size.value }}</code>
    </p>
  </div>
</template>

<style scoped>
.panel { display: flex; flex-direction: column; gap: 18px; padding: 22px; border-radius: 14px; background: var(--flare-color-bg-primary); border: 1px solid var(--flare-color-border-primary); }
.toolbar { display: flex; flex-wrap: wrap; gap: 18px; }
.group { display: flex; align-items: center; gap: 6px; }
.k { font-size: 12px; color: var(--flare-color-text-tertiary); margin-right: 2px; }
.hint { margin: 0; font-size: 12px; color: var(--flare-color-primary); }
.seg { min-width: 34px; height: 30px; padding: 0 10px; border-radius: 8px; border: 1px solid var(--flare-color-border-primary); background: var(--flare-color-bg-secondary); color: var(--flare-color-text-secondary); font-size: 13px; cursor: pointer; transition: all 0.15s ease; }
.seg.wide { min-width: 92px; }
.seg:hover { color: var(--flare-color-text-primary); }
.seg.on { background: var(--flare-color-bg-selected); border-color: var(--flare-color-primary); color: var(--flare-color-primary); font-weight: 500; }
.preview { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; padding: 18px; border-radius: 12px; background: var(--flare-color-bg-secondary); }
.readout { margin: 0; font-size: 12px; color: var(--flare-color-text-tertiary); }
.readout code { font-family: var(--vp-font-family-mono); color: var(--flare-color-text-secondary); }
</style>
