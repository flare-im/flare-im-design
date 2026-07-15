<script setup>
import { ref, onMounted, onBeforeUnmount, nextTick, watch } from "vue";

// Generic PC ⇄ App preview. Viewport-driven components (@media / useViewport)
// only reveal their true desktop form at a wide viewport, which the < 900px docs
// column can't give — so PC renders a wide (default 1024px) <iframe> scaled to
// fit, and App renders a narrow phone-shell iframe. Point `embed` at a blank
// full-bleed page that mounts the component.
const props = defineProps({
  embed: { type: String, required: true },
  pcHint: { type: String, default: "桌面" },
  appHint: { type: String, default: "移动" },
  pcLogicalWidth: { type: Number, default: 1024 },
  pcHeight: { type: Number, default: 468 },
  appWidth: { type: Number, default: 390 },
  appHeight: { type: Number, default: 620 },
});

const mode = ref("pc");
const modes = [
  { key: "pc", label: "PC" },
  { key: "app", label: "App" },
];
const hintFor = (k) => (k === "pc" ? props.pcHint : props.appHint);

const stageRef = ref(null);
const pcScale = ref(0.66);
let ro = null;
function measure() {
  const el = stageRef.value;
  if (!el) return;
  const w = el.clientWidth - 40;
  pcScale.value = Math.min(1, Math.max(0.4, w / props.pcLogicalWidth));
}
onMounted(() => {
  measure();
  ro = new ResizeObserver(measure);
  if (stageRef.value) ro.observe(stageRef.value);
});
onBeforeUnmount(() => ro?.disconnect());
watch(mode, () => nextTick(measure));
</script>

<template>
  <div class="rp">
    <div class="rp__bar">
      <div class="rp__seg" role="tablist" aria-label="预览尺寸">
        <button
          v-for="m in modes"
          :key="m.key"
          type="button"
          role="tab"
          class="rp__seg-btn"
          :class="{ 'is-active': mode === m.key }"
          :aria-selected="mode === m.key"
          @click="mode = m.key"
        >
          <span class="rp__seg-dot" :class="`rp__seg-dot--${m.key}`" aria-hidden="true" />
          {{ m.label }}
        </button>
      </div>
      <span class="rp__hint">{{ hintFor(mode) }}</span>
    </div>

    <div ref="stageRef" class="rp__stage">
      <div
        v-if="mode === 'pc'"
        class="rp__device rp__device--pc"
        :style="{ width: pcLogicalWidth * pcScale + 'px', height: pcHeight + 'px' }"
      >
        <iframe
          class="rp__frame"
          :src="embed"
          title="PC preview"
          :style="{
            width: pcLogicalWidth + 'px',
            height: pcHeight / pcScale + 'px',
            transform: `scale(${pcScale})`,
            transformOrigin: 'top left',
          }"
        />
      </div>

      <div
        v-else
        class="rp__device rp__device--app"
        :style="{ width: appWidth + 'px', height: appHeight + 'px' }"
      >
        <iframe class="rp__frame rp__frame--app" :src="embed" title="App preview" />
      </div>
    </div>
  </div>
</template>

<style scoped>
.rp {
  width: 100%;
  border: 1px solid var(--vp-c-divider);
  border-radius: 14px;
  overflow: hidden;
  background: var(--vp-c-bg-soft);
}
.rp__bar {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 12px;
  border-bottom: 1px solid var(--vp-c-divider);
}
.rp__seg {
  display: inline-flex;
  padding: 3px;
  border-radius: 999px;
  background: var(--vp-c-bg-alt);
  border: 1px solid var(--vp-c-divider);
}
.rp__seg-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 5px 16px;
  border: 0;
  border-radius: 999px;
  background: transparent;
  color: var(--vp-c-text-2);
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: color 0.15s, background 0.15s, box-shadow 0.15s;
}
.rp__seg-btn.is-active {
  color: #fff;
  background: #7c3aed;
  box-shadow: 0 1px 4px rgba(124, 58, 237, 0.35);
}
.rp__seg-dot { width: 8px; height: 8px; border-radius: 2px; background: currentColor; opacity: 0.6; }
.rp__seg-dot--app { border-radius: 3px; width: 6px; height: 10px; }
.rp__hint { font-size: 12px; color: var(--vp-c-text-3); }
.rp__stage {
  display: flex;
  justify-content: center;
  padding: 20px;
  background: radial-gradient(circle at 1px 1px, var(--vp-c-divider) 1px, transparent 0) 0 0 / 22px 22px;
}
.rp__device { background: var(--vp-c-bg); overflow: hidden; }
.rp__device--pc {
  border: 1px solid var(--vp-c-divider);
  border-radius: 12px;
  box-shadow: 0 12px 40px rgba(15, 23, 42, 0.12);
}
.rp__device--app {
  max-width: 100%;
  border: 10px solid #1f2430;
  border-radius: 36px;
  box-shadow: 0 18px 50px rgba(15, 23, 42, 0.22);
}
.rp__frame { display: block; border: 0; background: var(--vp-c-bg); }
.rp__frame--app { width: 100%; height: 100%; }
</style>
