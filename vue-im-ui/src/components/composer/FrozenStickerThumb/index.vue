<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from "vue";
import { freezeStickerToStaticDataUrl, peekFrozenStickerDataUrl } from "./freezeStickerFrame";

type AssetUrlLoader = () => Promise<string | undefined>;

const props = withDefaults(
  defineProps<{
    src?: string;
    loadSrc?: AssetUrlLoader;
    alt?: string;
    emSize?: number;
    playAnimatedOnHover?: boolean;
    objectFit?: "contain" | "cover";
    lazy?: boolean;
  }>(),
  {
    playAnimatedOnHover: false,
    objectFit: "contain",
    lazy: true,
  },
);

const rootRef = ref<HTMLElement | null>(null);
const displaySrc = ref("");
const resolvedSrc = ref("");
const hovered = ref(false);
const visible = ref(false);
let gen = 0;
let observer: IntersectionObserver | null = null;

const rootStyle = computed(() => {
  if (props.emSize == null || Number.isNaN(props.emSize)) return undefined;
  return { width: `${props.emSize}em`, height: `${props.emSize}em` };
});

const imgStyle = computed(() => ({
  objectFit: props.objectFit,
}));

async function resolveSource(): Promise<string> {
  const direct = props.src?.trim() ?? "";
  if (direct) return direct;
  return (await props.loadSrc?.())?.trim() ?? "";
}

async function load(): Promise<void> {
  if (!props.src && !props.loadSrc) {
    displaySrc.value = "";
    resolvedSrc.value = "";
    return;
  }
  if (props.lazy && !visible.value) {
    const direct = props.src?.trim() ?? "";
    displaySrc.value = direct ? (peekFrozenStickerDataUrl(direct) ?? "") : "";
    return;
  }
  const my = ++gen;
  const u = await resolveSource();
  if (my !== gen) return;
  if (!u) {
    displaySrc.value = "";
    resolvedSrc.value = "";
    return;
  }
  resolvedSrc.value = u;
  const next = await freezeStickerToStaticDataUrl(u);
  if (my !== gen) return;
  displaySrc.value = next;
}

watch([() => props.src, () => props.loadSrc, visible], load, { immediate: true });

onMounted(() => {
  if (!props.lazy) {
    visible.value = true;
    return;
  }
  if (typeof IntersectionObserver === "undefined") {
    visible.value = true;
    return;
  }
  const el = rootRef.value;
  if (!el) {
    visible.value = true;
    return;
  }
  observer = new IntersectionObserver(
    (entries) => {
      if (entries.some((entry) => entry.isIntersecting)) {
        visible.value = true;
        observer?.disconnect();
        observer = null;
      }
    },
    { rootMargin: "160px" },
  );
  observer.observe(el);
});

function onHoverEnter(): void {
  visible.value = true;
  if (props.playAnimatedOnHover) hovered.value = true;
}

function onHoverLeave(): void {
  if (props.playAnimatedOnHover) hovered.value = false;
}

onBeforeUnmount(() => {
  gen += 1;
  observer?.disconnect();
  observer = null;
});
</script>

<template>
  <span
    ref="rootRef"
    class="frozen-sticker-thumb-root"
    :class="{
      'frozen-sticker-thumb-root--fill': emSize == null,
      'frozen-sticker-thumb-root--hoverable': playAnimatedOnHover,
    }"
    :style="rootStyle"
    @mouseenter="onHoverEnter"
    @mouseleave="onHoverLeave"
  >
    <template v-if="playAnimatedOnHover">
      <span class="frozen-sticker-thumb-stack">
        <img
          v-if="displaySrc"
          class="frozen-sticker-thumb frozen-sticker-thumb--static"
          :class="{ 'frozen-sticker-thumb--hidden': hovered }"
          :src="displaySrc"
          :alt="alt ?? ''"
          loading="lazy"
          decoding="async"
          :style="imgStyle"
        />
        <img
          v-if="hovered && resolvedSrc"
          class="frozen-sticker-thumb frozen-sticker-thumb--animated"
          :src="resolvedSrc"
          :alt="alt ?? ''"
          decoding="async"
          :style="imgStyle"
        />
      </span>
    </template>
    <img
      v-else-if="displaySrc"
      class="frozen-sticker-thumb"
      :src="displaySrc"
      :alt="alt ?? ''"
      loading="lazy"
      decoding="async"
      :style="imgStyle"
    />
  </span>
</template>

<style scoped>
.frozen-sticker-thumb-root {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  vertical-align: middle;
  box-sizing: border-box;
}

.frozen-sticker-thumb-root--fill {
  width: 100%;
  height: 100%;
  min-width: 0;
  min-height: 0;
}

.frozen-sticker-thumb-root--hoverable {
  position: relative;
}

.frozen-sticker-thumb-stack {
  position: relative;
  display: block;
  width: 100%;
  height: 100%;
  min-width: 0;
  min-height: 0;
}

.frozen-sticker-thumb {
  width: 100%;
  height: 100%;
  display: block;
  pointer-events: none;
}

.frozen-sticker-thumb-stack .frozen-sticker-thumb {
  position: absolute;
  inset: 0;
}

.frozen-sticker-thumb--static {
  transition: opacity 0.12s ease;
  opacity: 1;
}

.frozen-sticker-thumb--static.frozen-sticker-thumb--hidden {
  opacity: 0;
}

.frozen-sticker-thumb--animated {
  opacity: 1;
}
</style>
