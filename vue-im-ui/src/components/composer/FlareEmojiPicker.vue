<script setup lang="ts">
import { ref, computed } from "vue";
import { NIcon } from "naive-ui";
import { SearchOutline, TimeOutline } from "../../shared/icon-glyphs";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareEmojiCategory } from "../../shared/contracts";

const props = withDefaults(
  defineProps<{
    categories: FlareEmojiCategory[];
    /** Recently-used emoji, shown as a pinned first tab. */
    recents?: string[];
    /** Show the Fitzpatrick skin-tone selector. */
    skinTones?: boolean;
  }>(),
  { recents: () => [], skinTones: false },
);
const emit = defineEmits<{
  (e: "select", emoji: string): void;
  (e: "toneChange", tone: string): void;
}>();

const { t } = useFlareI18n();
const TONES = ["", "\u{1F3FB}", "\u{1F3FC}", "\u{1F3FD}", "\u{1F3FE}", "\u{1F3FF}"];
const tone = ref("");
const query = ref("");
const activeKey = ref(props.recents.length ? "__recent" : (props.categories[0]?.key ?? ""));

const tabs = computed(() => {
  const base = props.recents.length
    ? [{ key: "__recent", label: t("emoji.recent"), symbol: "🕘", emojis: props.recents }]
    : [];
  return [...base, ...props.categories];
});
const activeCat = computed(() => tabs.value.find((c) => c.key === activeKey.value) ?? tabs.value[0]);

const shown = computed(() => {
  const q = query.value.trim();
  if (q) return [...new Set(props.categories.flatMap((c) => c.emojis))].filter((e) => e.includes(q));
  return activeCat.value?.emojis ?? [];
});

function pick(e: string): void {
  emit("select", tone.value ? e + tone.value : e);
}
function setTone(tn: string): void {
  tone.value = tn;
  emit("toneChange", tn);
}
</script>

<template>
  <div class="flare-emoji-picker">
    <div class="flare-emoji-picker__search">
      <n-icon :size="15" :component="SearchOutline" class="flare-emoji-picker__search-ico" />
      <input v-model="query" type="text" :placeholder="t('emoji.search')" class="flare-emoji-picker__input" />
      <span v-if="skinTones" class="flare-emoji-picker__tones">
        <button
          v-for="tn in TONES"
          :key="tn || 'default'"
          type="button"
          class="flare-emoji-picker__tone"
          :class="{ 'is-active': tone === tn, 'is-default': tn === '' }"
          :aria-label="t('emoji.skinTone')"
          @click="setTone(tn)"
        >{{ tn ? "✋" + tn : "✋" }}</button>
      </span>
    </div>

    <div class="flare-emoji-picker__grid">
      <button
        v-for="(e, i) in shown"
        :key="i"
        type="button"
        class="flare-emoji-picker__emoji"
        @click="pick(e)"
      >{{ e }}</button>
      <div v-if="shown.length === 0" class="flare-emoji-picker__empty">{{ t("emoji.empty") }}</div>
    </div>

    <div v-if="!query" class="flare-emoji-picker__rail" role="tablist">
      <button
        v-for="c in tabs"
        :key="c.key"
        type="button"
        role="tab"
        class="flare-emoji-picker__tab"
        :class="{ 'is-active': c.key === activeCat?.key }"
        :aria-selected="c.key === activeCat?.key"
        :title="c.label"
        @click="activeKey = c.key"
      >
        <n-icon v-if="c.key === '__recent'" :size="16" :component="TimeOutline" />
        <template v-else>{{ c.symbol || c.emojis[0] }}</template>
      </button>
    </div>
  </div>
</template>

<style scoped>
.flare-emoji-picker {
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
.flare-emoji-picker__search {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 12px;
  border-bottom: 1px solid var(--flare-color-border-primary, #e9e6f1);
}
.flare-emoji-picker__search-ico { color: var(--flare-color-text-tertiary, #a7a2b4); }
.flare-emoji-picker__input {
  flex: 1;
  min-width: 0;
  border: none;
  outline: none;
  background: transparent;
  font-size: 14px;
  color: var(--flare-color-text-primary, #15131c);
}
.flare-emoji-picker__tones { display: inline-flex; gap: 1px; flex: 0 0 auto; }
.flare-emoji-picker__tone {
  width: 22px;
  height: 22px;
  border: none;
  border-radius: 6px;
  background: transparent;
  font-size: 14px;
  line-height: 1;
  cursor: pointer;
  opacity: 0.55;
  filter: grayscale(0.2);
}
.flare-emoji-picker__tone.is-active { opacity: 1; background: var(--flare-color-bg-selected, #f1eaff); }
.flare-emoji-picker__grid {
  display: grid;
  grid-template-columns: repeat(8, 1fr);
  gap: 2px;
  padding: 8px;
  height: 200px;
  overflow-y: auto;
  align-content: start;
}
.flare-emoji-picker__emoji {
  aspect-ratio: 1;
  border: none;
  background: transparent;
  font-size: 22px;
  line-height: 1;
  border-radius: 8px;
  cursor: pointer;
  transition: background var(--flare-transition-fast, 150ms ease), transform var(--flare-transition-fast, 150ms ease);
}
.flare-emoji-picker__emoji:hover { background: var(--flare-color-bg-secondary, #f6f5fb); transform: scale(1.12); }
.flare-emoji-picker__empty {
  grid-column: 1 / -1;
  text-align: center;
  padding: 40px 0;
  font-size: 13px;
  color: var(--flare-color-text-tertiary, #a7a2b4);
}
.flare-emoji-picker__rail {
  display: flex;
  gap: 2px;
  padding: 6px 8px;
  border-top: 1px solid var(--flare-color-border-primary, #e9e6f1);
  overflow-x: auto;
}
.flare-emoji-picker__tab {
  flex: 0 0 auto;
  width: 32px;
  height: 32px;
  border: none;
  border-radius: 8px;
  background: transparent;
  font-size: 18px;
  line-height: 1;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: var(--flare-color-text-secondary, #6b6780);
}
.flare-emoji-picker__tab.is-active { background: var(--flare-color-bg-selected, #f1eaff); }
</style>
