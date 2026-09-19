<script setup>
import { computed, defineAsyncComponent, onBeforeUnmount, onMounted, provide, ref, watch } from "vue";
import { useData, useRoute } from "vitepress";
import catalog from "../../../../spec/component-catalog.json";
import { previewContextKey } from "./preview-context";
import { previewDemoName, previewDemoProps } from "./preview-registry.mjs";

const props = defineProps({ name: { type: String, required: true }, embedded: Boolean, initialViewport: { type: String, default: "desktop" } });
const route = useRoute();
const { isDark } = useData();
const en = computed(() => route.path.startsWith("/en"));
const t = (zh, english) => (en.value ? english : zh);

const modules = import.meta.glob(["./*Demo.vue", "./messages/demos/*Demo.vue"]);
const demos = Object.fromEntries(Object.entries(modules).map(([path, loader]) => [
  path.split("/").pop().replace(/\.vue$/, ""),
  defineAsyncComponent(loader),
]));

const entry = computed(() => catalog.components.find((component) => component.name === props.name));
const demoName = computed(() => previewDemoName(props.name));
const demo = computed(() => demos[demoName.value]);
const demoProps = computed(() => previewDemoProps(props.name));
const previewMode = computed(() => entry.value?.previewMode ?? "single");
const presentation = computed(() => entry.value?.previewPresentation ?? "isolated");
const viewports = computed(() => entry.value?.previewViewports ?? ["desktop"]);
const hasViewportControls = computed(() => viewports.value.length > 1);
const viewport = ref(props.embedded ? props.initialViewport : viewports.value[0] ?? "desktop");
const canvas = ref(null);
const frame = ref(null);
const canvasWidth = ref(640);
const logicalWidth = computed(() => viewport.value === "mobile" ? 390 : 1024);
const scale = computed(() => Math.min(1, canvasWidth.value / logicalWidth.value));
const naturalDesktop = computed(() => viewport.value === "desktop" && presentation.value !== "workspace");
const logicalHeight = computed(() => naturalDesktop.value ? Math.max(640, 440 / scale.value) : 640);
const frameSource = computed(() => `${en.value ? "/en" : ""}/embed/component-frame?name=${encodeURIComponent(props.name)}&viewport=${viewport.value}`);
let resizeObserver;
function syncTheme() {
  frame.value?.contentWindow?.postMessage({
    type: "flare-preview-theme", dark: isDark.value,
    contentScale: naturalDesktop.value ? scale.value : 1,
    contentHeight: logicalHeight.value * (naturalDesktop.value ? scale.value : 1),
  }, window.location.origin);
}
function receiveFrameReady(event) {
  if (event.origin === window.location.origin && event.source === frame.value?.contentWindow && event.data?.type === "flare-preview-ready") syncTheme();
}
onMounted(() => {
  window.addEventListener("message", receiveFrameReady);
  if (!canvas.value) return;
  resizeObserver = new ResizeObserver(([entry]) => { canvasWidth.value = entry.contentRect.width; });
  resizeObserver.observe(canvas.value);
});
onBeforeUnmount(() => {
  resizeObserver?.disconnect();
  window.removeEventListener("message", receiveFrameReady);
});
watch(isDark, syncTheme);
watch([scale, logicalHeight], syncTheme, { flush: "post" });

const colorMode = computed(() => (isDark.value ? "dark" : "light"));
const hasContextBar = computed(() => ["chat", "chat-footer", "list"].includes(presentation.value));
const contextTitle = computed(() => presentation.value === "list" ? t("会话", "Conversations") : "Ivy Chen");
const contextDetail = computed(() => presentation.value === "list" ? t("最近消息", "Recent messages") : t("在线", "Online"));

watch(() => props.name, () => { viewport.value = viewports.value[0] ?? "desktop"; });

provide(previewContextKey, { viewport, presentation });
</script>

<template>
  <div class="component-preview" :class="{ 'is-embedded': embedded }" :data-component="name" :data-preview-mode="previewMode">
    <div v-if="hasViewportControls && !embedded" class="component-preview__controls">
      <div class="component-preview__viewports" role="group" :aria-label="t('预览尺寸', 'Preview size')">
        <button
          v-for="item in viewports"
          :key="item"
          type="button"
          :aria-pressed="viewport === item"
          @click="viewport = item"
        >{{ item === "desktop" ? t("桌面", "Desktop") : t("移动端", "Mobile") }}</button>
      </div>
    </div>

    <div ref="canvas" class="component-preview__canvas">
      <div v-if="hasViewportControls && !embedded" class="component-preview__frame-slot" :style="{ width: `${logicalWidth * scale}px`, height: `${logicalHeight * scale}px` }">
        <iframe :key="`${name}-${viewport}`" ref="frame" class="component-preview__frame" :class="`is-${viewport}`" :src="frameSource" :title="`${name} ${viewport} preview`" :style="{ width: `${logicalWidth}px`, height: `${logicalHeight}px`, transform: `scale(${scale})` }" @load="syncTheme" />
      </div>
      <div
        v-else
        class="component-preview__viewport"
        :class="[`is-${viewport}`, `is-${presentation}`]"
        :data-flare-theme="colorMode"
      >
        <div v-if="hasContextBar" class="component-preview__context-bar">
          <span class="component-preview__context-avatar" aria-hidden="true">IC</span>
          <span><strong>{{ contextTitle }}</strong><small>{{ contextDetail }}</small></span>
        </div>
        <div class="component-preview__live">
          <component
            :is="demo"
            v-if="demo"
            :key="`${name}-${viewport}`"
            v-bind="demoProps"
            :preview-presentation="presentation"
          />
          <p v-else class="component-preview__missing" role="status">
            {{ t("此组件的实时预览适配器缺失。", "The live preview adapter is missing for this component.") }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.component-preview { border: 1px solid var(--vp-c-divider); border-radius: 6px; overflow: hidden; background: var(--vp-c-bg); }
.component-preview__controls { display: flex; align-items: center; padding: 9px 12px; border-bottom: 1px solid var(--vp-c-divider); background: var(--vp-c-bg-soft); }
.component-preview__viewports { display: inline-flex; min-height: 34px; border: 1px solid var(--vp-c-divider); border-radius: 5px; overflow: hidden; }
.component-preview__viewports button { min-width: 84px; padding: 7px 12px; border: 0; color: var(--vp-c-text-2); background: var(--vp-c-bg); font: inherit; font-size: 12px; cursor: pointer; }
.component-preview__viewports button + button { border-inline-start: 1px solid var(--vp-c-divider); }
.component-preview__viewports button[aria-pressed="true"] { color: var(--vp-c-brand-1); background: var(--vp-c-brand-soft); font-weight: 650; }
.component-preview__viewports button:focus-visible { outline: 2px solid var(--vp-c-brand-1); outline-offset: -2px; }
.component-preview__canvas { width: 100%; min-height: 320px; overflow: auto; padding: 18px; background: var(--vp-c-bg-alt); box-sizing: border-box; }
.component-preview__viewport { width: 100%; min-height: 300px; margin-inline: auto; overflow: hidden; color: var(--flare-color-text-primary); background: var(--flare-color-bg-primary); border: 1px solid var(--flare-color-border-primary); box-sizing: border-box; transition: width 160ms ease; }
.component-preview__viewport.is-mobile { width: 100%; max-width: 390px !important; min-height: 420px; }
.component-preview__viewport.is-workspace { min-height: 420px; }
.component-preview__context-bar { display: flex; align-items: center; gap: 9px; height: 52px; padding: 0 14px; border-bottom: 1px solid var(--flare-color-border-primary); background: var(--flare-color-bg-primary); }
.component-preview__context-avatar { display: grid; place-items: center; width: 30px; height: 30px; border-radius: 50%; color: var(--flare-color-primary-text); background: var(--flare-color-bg-selected); font-size: 11px; font-weight: 700; }
.component-preview__context-bar > span:last-child { display: grid; gap: 1px; }
.component-preview__context-bar strong { color: var(--flare-color-text-primary); font-size: 13px; }
.component-preview__context-bar small { color: var(--flare-color-text-tertiary); font-size: 11px; }
.component-preview__live { display: grid; align-content: center; min-height: 298px; padding: 14px; box-sizing: border-box; background: var(--flare-color-bg-secondary); }
.component-preview__viewport.is-chat-footer .component-preview__live { align-content: end; }
.component-preview__viewport.is-chat .component-preview__live { background: var(--flare-color-bg-tertiary); }
.component-preview__viewport.is-list .component-preview__live { align-content: start; }
.component-preview__viewport.is-overlay .component-preview__live { background: var(--flare-color-bg-tertiary); }
.component-preview__viewport.is-workspace .component-preview__live { align-content: stretch; min-height: 418px; padding: 0; }
.component-preview__missing { margin: auto; color: var(--flare-color-error-text); }
.component-preview__frame-slot { position: relative; margin-inline: auto; }
.component-preview__frame { display: block; border: 0; transform-origin: top left; background: var(--flare-color-bg-primary); }
.component-preview.is-embedded { border: 0; border-radius: 0; min-height: var(--component-preview-height, 100dvh); }
.is-embedded .component-preview__canvas { padding: 0; min-height: var(--component-preview-height, 100dvh); }
.is-embedded .component-preview__viewport { border: 0; min-height: var(--component-preview-height, 100dvh); transition: none; }
.is-embedded .component-preview__live { min-height: var(--component-preview-height, 100dvh); }
.is-embedded .component-preview__context-bar + .component-preview__live { min-height: calc(var(--component-preview-height, 100dvh) - 52px); }
@media (max-width: 700px) {
  .component-preview__canvas { padding: 10px; }
}
</style>
