<script setup>
// Dual adaptive preview: renders the SAME slot content twice — once in a desktop
// (pc) context, once inside a phone frame (h5). Adaptive components (Select,
// TimePicker) show their desktop popover on the left and their bottom sheet on
// the right. The phone frame is a CSS containing block (transform) with
// overflow:hidden, and it feeds itself as the overlay container so the h5 sheet
// teleports INTO the frame instead of covering the whole page.
import { ref } from "vue";
import FlareConfigProvider from "flare-core-vue-im-ui/components/general/FlareConfigProvider.vue";
const screenEl = ref(null);
</script>
<template>
  <div class="dual">
    <section class="stage">
      <header class="cap"><span class="dot pc" />PC · 桌面</header>
      <div class="pc-surface">
        <FlareConfigProvider layout-mode="pc">
          <slot />
        </FlareConfigProvider>
      </div>
    </section>

    <section class="stage">
      <header class="cap"><span class="dot app" />App · 移动</header>
      <div class="phone">
        <div class="phone__bezel">
          <div ref="screenEl" class="phone__screen">
            <div class="phone__statusbar"><span>9:41</span><span class="phone__dots">●●●●</span></div>
            <div class="phone__body">
              <FlareConfigProvider layout-mode="h5" :overlay-container="screenEl">
                <slot />
              </FlareConfigProvider>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>
<style scoped>
.dual {
  display: flex;
  flex-wrap: wrap;
  gap: 28px;
  align-items: flex-start;
  padding: 24px;
  border-radius: 14px;
  background: var(--flare-color-bg-secondary);
}
.stage { display: flex; flex-direction: column; gap: 12px; flex: 1 1 260px; min-width: 240px; }
.cap { display: flex; align-items: center; gap: 8px; font-size: 12px; font-weight: 600; letter-spacing: 0.04em; color: var(--flare-color-text-tertiary); text-transform: uppercase; }
.dot { width: 8px; height: 8px; border-radius: 50%; }
.dot.pc { background: var(--flare-color-primary); }
.dot.app { background: #22c55e; }

.pc-surface {
  padding: 22px;
  min-height: 200px;
  border-radius: 12px;
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-primary);
}

.phone { display: flex; justify-content: center; }
.phone__bezel {
  padding: 8px;
  border-radius: 40px;
  background: linear-gradient(160deg, #26232f, #131019);
  box-shadow: 0 18px 40px rgba(21, 18, 32, 0.28), inset 0 0 0 1px rgba(255, 255, 255, 0.05);
}
.phone__screen {
  /* transform → containing block so the teleported fixed sheet is scoped here; overflow clips it to the phone */
  position: relative;
  transform: translateZ(0);
  overflow: hidden;
  width: 268px;
  height: 520px;
  border-radius: 32px;
  background: var(--flare-color-bg-primary);
  display: flex;
  flex-direction: column;
}
.phone__statusbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 22px 4px;
  font-size: 12px;
  font-weight: 600;
  color: var(--flare-color-text-secondary);
}
.phone__dots { letter-spacing: 2px; font-size: 8px; color: var(--flare-color-text-tertiary); }
.phone__body { flex: 1; padding: 20px 18px; overflow-y: auto; }
</style>
