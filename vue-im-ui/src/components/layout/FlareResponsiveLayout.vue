<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from "vue";
import { FLARE_BREAKPOINT_H5_MAX, FLARE_BREAKPOINT_IPAD_MAX } from "../../shared/contracts";

type Pane = "list" | "chat" | "detail";
const props = withDefaults(
  defineProps<{ hasDetail?: boolean; activePane?: Pane }>(),
  { hasDetail: false, activePane: "list" },
);
const emit = defineEmits<{ (e: "paneChange", pane: Pane): void }>();

const width = ref(1280);
function onResize() {
  width.value = window.innerWidth;
}
onMounted(() => {
  onResize();
  window.addEventListener("resize", onResize);
});
onUnmounted(() => window.removeEventListener("resize", onResize));

const kind = computed(() =>
  width.value <= FLARE_BREAKPOINT_H5_MAX ? "h5" : width.value <= FLARE_BREAKPOINT_IPAD_MAX ? "ipad" : "pc",
);
const triple = computed(() => kind.value === "pc" && props.hasDetail);
</script>

<template>
  <!-- desktop: three columns (list + chat + detail) -->
  <div v-if="triple" class="flare-rl flare-rl--triple">
    <div class="flare-rl__list"><slot name="list" /></div>
    <div class="flare-rl__chat"><slot name="chat" /></div>
    <div class="flare-rl__detail"><slot name="detail" /></div>
  </div>
  <!-- tablet / desktop-no-detail: two columns (list + chat) -->
  <div v-else-if="kind !== 'h5'" class="flare-rl flare-rl--dual">
    <div class="flare-rl__list"><slot name="list" /></div>
    <div class="flare-rl__chat"><slot name="chat" /></div>
  </div>
  <!-- phone: single column by active pane -->
  <div v-else class="flare-rl flare-rl--single">
    <slot v-if="activePane === 'list'" name="list" />
    <template v-else>
      <div class="flare-rl__bar">
        <button class="flare-rl__back" @click="emit('paneChange', 'list')">‹ Back</button>
      </div>
      <slot v-if="activePane === 'detail'" name="detail" />
      <slot v-else name="chat" />
    </template>
  </div>
</template>

<style scoped>
.flare-rl { display: flex; width: 100%; height: 100%; }
.flare-rl--single { flex-direction: column; }
.flare-rl__list { width: 300px; flex: none; border-right: 1px solid var(--flare-color-border-primary); overflow: hidden; }
.flare-rl__chat { flex: 1; min-width: 0; }
.flare-rl__detail { width: 320px; flex: none; border-left: 1px solid var(--flare-color-border-primary); overflow: hidden; }
.flare-rl--single .flare-rl__list { width: 100%; border: none; }
.flare-rl__bar { border-bottom: 1px solid var(--flare-color-border-primary); }
.flare-rl__back {
  border: none; background: none; padding: 10px 14px;
  color: var(--flare-color-primary); font-size: 14px; cursor: pointer;
}
</style>
