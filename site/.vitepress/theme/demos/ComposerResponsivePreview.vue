<script setup>
import { ref, onMounted, onBeforeUnmount, nextTick, watch } from "vue";

// PC ⇄ App preview. The composer's responsive layout is viewport-driven
// (@media min-width:900px), so the ONLY way to show the true desktop layout
// is to give it a viewport that wide. The docs column is < 900px, so for PC we
// render a 1024px-logical <iframe> and visually scale it down with transform to
// fit the card — the iframe's own viewport stays 1024 → real desktop composer.
// App renders a 390px iframe unscaled → real mobile composer.
const mode = ref("pc");
const modes = [
  { key: "pc", label: "PC", hint: "桌面 · 单行工具栏" },
  { key: "app", label: "App", hint: "移动 · 堆叠触摸栏" },
];

const PC_LOGICAL_W = 1024;
const PC_VISUAL_H = 468;

const stageRef = ref(null);
const pcScale = ref(0.66);
let ro = null;

function measure() {
  const el = stageRef.value;
  if (!el) return;
  // available width inside the stage padding
  const w = el.clientWidth - 40; // 20px padding each side
  pcScale.value = Math.min(1, Math.max(0.4, w / PC_LOGICAL_W));
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
      <span class="rp__hint">{{ modes.find((m) => m.key === mode).hint }}</span>
    </div>

    <div ref="stageRef" class="rp__stage" :class="`rp__stage--${mode}`">
      <!-- PC: a wide window, scaled to fit; the iframe viewport stays 1024px. -->
      <div
        v-if="mode === 'pc'"
        class="rp__device rp__device--pc"
        :style="{ width: PC_LOGICAL_W * pcScale + 'px', height: PC_VISUAL_H + 'px' }"
      >
        <iframe
          class="rp__frame"
          src="/embed/composer-frame"
          title="Composer PC preview"
          :style="{
            width: PC_LOGICAL_W + 'px',
            height: PC_VISUAL_H / pcScale + 'px',
            transform: `scale(${pcScale})`,
            transformOrigin: 'top left',
          }"
        />
      </div>

      <!-- App: a phone shell, real 390px viewport → mobile composer. -->
      <div v-else class="rp__device rp__device--app">
        <iframe class="rp__frame rp__frame--app" src="/embed/composer-frame" title="Composer App preview" />
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
.rp__seg-dot {
  width: 8px;
  height: 8px;
  border-radius: 2px;
}
.rp__seg-dot--pc { border-radius: 2px; background: currentColor; opacity: 0.6; }
.rp__seg-dot--app { border-radius: 3px; width: 6px; height: 10px; background: currentColor; opacity: 0.6; }
.rp__hint {
  font-size: 12px;
  color: var(--vp-c-text-3);
}
.rp__stage {
  display: flex;
  justify-content: center;
  padding: 20px;
  background:
    radial-gradient(circle at 1px 1px, var(--vp-c-divider) 1px, transparent 0) 0 0 / 22px 22px;
}
.rp__device {
  background: var(--vp-c-bg);
  overflow: hidden;
}
/* PC: window card — dimensions are set inline (scaled). */
.rp__device--pc {
  border: 1px solid var(--vp-c-divider);
  border-radius: 12px;
  box-shadow: 0 12px 40px rgba(15, 23, 42, 0.12);
}
/* App: a phone shell. */
.rp__device--app {
  width: 390px;
  max-width: 100%;
  height: 620px;
  border: 10px solid #1f2430;
  border-radius: 36px;
  box-shadow: 0 18px 50px rgba(15, 23, 42, 0.22);
}
.rp__frame {
  display: block;
  border: 0;
  background: var(--vp-c-bg);
}
.rp__frame--app {
  width: 100%;
  height: 100%;
}
@media (max-width: 640px) {
  .rp__device--app { height: 560px; }
}
</style>
