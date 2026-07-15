<script setup lang="ts">
import { ref, computed } from "vue";
import { NIcon } from "naive-ui";
import { TimeOutline } from "@vicons/ionicons5";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareStickerPack, FlareStickerItem } from "../../shared/contracts";

const props = withDefaults(
  defineProps<{
    packs: FlareStickerPack[];
    /** Recently-used stickers, pinned as a first pack. */
    recents?: FlareStickerItem[];
  }>(),
  { recents: () => [] },
);
const emit = defineEmits<{ (e: "select", sticker: FlareStickerItem): void }>();

const { t } = useFlareI18n();
const railPacks = computed<FlareStickerPack[]>(() => {
  const base: FlareStickerPack[] = props.recents.length
    ? [{ key: "__recent", label: t("sticker.recent"), coverEmoji: "🕘", stickers: props.recents }]
    : [];
  return [...base, ...props.packs];
});
const activeKey = ref(railPacks.value[0]?.key ?? "");
const activePack = computed(() => railPacks.value.find((p) => p.key === activeKey.value) ?? railPacks.value[0]);
</script>

<template>
  <div class="flare-sticker-panel">
    <div class="flare-sticker-panel__label">{{ activePack?.label }}</div>
    <div class="flare-sticker-panel__grid">
      <button
        v-for="s in activePack?.stickers ?? []"
        :key="s.id"
        type="button"
        class="flare-sticker-panel__cell"
        @click="emit('select', s)"
      >
        <img v-if="s.url" :src="s.url" :alt="s.id" loading="lazy" />
        <span v-else class="flare-sticker-panel__ph">{{ s.placeholder || "🎨" }}</span>
      </button>
      <div v-if="!(activePack?.stickers.length)" class="flare-sticker-panel__empty">{{ t("sticker.empty") }}</div>
    </div>

    <div class="flare-sticker-panel__rail" role="tablist">
      <button
        v-for="p in railPacks"
        :key="p.key"
        type="button"
        role="tab"
        class="flare-sticker-panel__pack"
        :class="{ 'is-active': p.key === activePack?.key }"
        :aria-selected="p.key === activePack?.key"
        :title="p.label"
        @click="activeKey = p.key"
      >
        <n-icon v-if="p.key === '__recent'" :size="18" :component="TimeOutline" />
        <img v-else-if="p.coverUrl" :src="p.coverUrl" :alt="p.label" />
        <span v-else>{{ p.coverEmoji || p.stickers[0]?.placeholder || "🖼️" }}</span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.flare-sticker-panel {
  width: 320px;
  max-width: 100%;
  display: flex;
  flex-direction: column;
  border-radius: var(--flare-size-radius-xl, 14px);
  background: var(--flare-color-bg-primary, #fff);
  border: 1px solid var(--flare-color-border-primary, #e9e6f1);
  box-shadow: var(--flare-shadow-lg, 0 12px 28px rgba(21, 18, 32, 0.16));
  overflow: hidden;
}
.flare-sticker-panel__label {
  padding: 10px 14px 4px;
  font-size: 12px;
  font-weight: 600;
  color: var(--flare-color-text-tertiary, #a7a2b4);
}
.flare-sticker-panel__grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 6px;
  padding: 6px 12px 12px;
  height: 208px;
  overflow-y: auto;
  align-content: start;
}
.flare-sticker-panel__cell {
  aspect-ratio: 1;
  border: none;
  border-radius: var(--flare-size-radius-lg, 12px);
  background: var(--flare-color-bg-secondary, #f6f5fb);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  overflow: hidden;
  transition: transform var(--flare-transition-fast, 150ms ease);
}
.flare-sticker-panel__cell:hover { transform: scale(1.05); }
.flare-sticker-panel__cell img { width: 100%; height: 100%; object-fit: contain; }
.flare-sticker-panel__ph { font-size: 32px; line-height: 1; }
.flare-sticker-panel__empty {
  grid-column: 1 / -1;
  text-align: center;
  padding: 44px 0;
  font-size: 13px;
  color: var(--flare-color-text-tertiary, #a7a2b4);
}
.flare-sticker-panel__rail {
  display: flex;
  gap: 4px;
  padding: 6px 8px;
  border-top: 1px solid var(--flare-color-border-primary, #e9e6f1);
  overflow-x: auto;
}
.flare-sticker-panel__pack {
  flex: 0 0 auto;
  width: 38px;
  height: 38px;
  border: none;
  border-radius: 10px;
  background: transparent;
  cursor: pointer;
  font-size: 20px;
  line-height: 1;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: var(--flare-color-text-secondary, #6b6780);
}
.flare-sticker-panel__pack.is-active { background: var(--flare-color-bg-selected, #f1eaff); }
.flare-sticker-panel__pack img { width: 26px; height: 26px; object-fit: contain; border-radius: 6px; }
</style>
