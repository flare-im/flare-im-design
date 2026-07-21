<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from "vue";
import { FLARE_BREAKPOINT_H5_MAX } from "../../shared/contracts";
import type { FlareNavItem } from "../../shared/contracts";
import FlareGlyph from "../general/FlareGlyph.vue";

withDefaults(
  defineProps<{
    items: FlareNavItem[];
    activeKey: string;
    /**
     * Hide the phone bottom tab bar (e.g. while a conversation is open, so the
     * chat gets the full height — WeChat/Feishu behaviour). Ignored on the
     * tablet/desktop side rail, which always stays visible.
     */
    hideBottomNav?: boolean;
  }>(),
  { hideBottomNav: false },
);
const emit = defineEmits<{ (e: "navigate", key: string): void }>();

const width = ref(1280);
function onResize() {
  width.value = window.innerWidth;
}
onMounted(() => {
  onResize();
  window.addEventListener("resize", onResize);
});
onUnmounted(() => window.removeEventListener("resize", onResize));

// side rail on tablet/desktop, bottom bar on phone
const rail = computed(() => width.value > FLARE_BREAKPOINT_H5_MAX);
</script>

<template>
  <div class="flare-shell" :class="rail ? 'is-rail' : 'is-bottom'">
    <nav v-if="rail" class="flare-shell__rail">
      <button
        v-for="it in items"
        :key="it.key"
        class="flare-shell__item"
        :class="{ active: it.key === activeKey }"
        @click="emit('navigate', it.key)"
      >
        <span class="flare-shell__ico">
          <FlareGlyph :icon="it.icon || '•'" :size="22" />
          <span v-if="it.badge" class="flare-shell__badge">{{ it.badge > 99 ? "99+" : it.badge }}</span>
        </span>
        <span class="flare-shell__label">{{ it.label }}</span>
      </button>
    </nav>

    <div class="flare-shell__content"><slot /></div>

    <nav v-if="!rail && !hideBottomNav" class="flare-shell__bottom">
      <button
        v-for="it in items"
        :key="it.key"
        class="flare-shell__item"
        :class="{ active: it.key === activeKey }"
        @click="emit('navigate', it.key)"
      >
        <span class="flare-shell__ico">
          <FlareGlyph :icon="it.icon || '•'" :size="22" />
          <span v-if="it.badge" class="flare-shell__badge">{{ it.badge > 99 ? "99+" : it.badge }}</span>
        </span>
        <span class="flare-shell__label">{{ it.label }}</span>
      </button>
    </nav>
  </div>
</template>

<style scoped>
.flare-shell { display: flex; width: 100%; height: 100%; }
.flare-shell.is-bottom { flex-direction: column; }
.flare-shell__content { flex: 1; min-width: 0; min-height: 0; }
.flare-shell__rail {
  display: flex; flex-direction: column; gap: 6px; padding: 12px 6px;
  border-right: 1px solid var(--flare-color-border-primary);
  background: var(--flare-color-bg-secondary);
}
.flare-shell__bottom {
  display: flex; justify-content: space-around;
  border-top: 1px solid var(--flare-color-border-primary);
  background: var(--flare-color-bg-primary);
}
.flare-shell__item {
  display: flex; flex-direction: column; align-items: center; gap: 2px;
  border: none; background: none; cursor: pointer; padding: 8px 12px;
  color: var(--flare-color-text-tertiary); font-size: 11px;
}
.flare-shell__item.active { color: var(--flare-color-primary); }
.flare-shell__ico {
  position: relative; font-size: 20px;
  display: inline-flex; align-items: center; justify-content: center; min-height: 22px;
}
.flare-shell__badge {
  position: absolute; top: -4px; right: -8px;
  background: var(--flare-color-error); color: #fff;
  font-size: 9px; line-height: 1; padding: 2px 4px; border-radius: 999px;
}
</style>
