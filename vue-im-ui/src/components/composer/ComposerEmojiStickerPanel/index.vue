<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { AddCircleOutline, HappyOutline } from "@vicons/ionicons5";
import { NIcon } from "naive-ui";
import { COMPOSER_EMOJI_ITEMS, type ComposerEmojiAssetItem } from "../ComposerEmojiStickerPopover/composerEmojiAssets";
import { emojiPackLabel } from "../../../utils/emojiPackI18n";
import {
  COMPOSER_CLASSIC_STICKER_ITEMS,
  COMPOSER_DEFAULT_STICKER_ITEMS,
  COMPOSER_STICKER_PACK_TAB_ICON_URL,
  resolveStickerUrlByPackageAndId,
  type ComposerStickerItem,
} from "../ComposerEmojiStickerPopover/composerStickers";
import FrozenStickerThumb from "../FrozenStickerThumb/index.vue";

export type ComposerStickerPick = {
  stickerId: string;
  packageId: string;
  url: string;
};

const props = withDefaults(
  defineProps<{
    /** 由父级工具栏决定Open表情还是贴纸 */
    activeTab: "emoji" | "sticker";
    /** 仅表情：隐藏底部贴纸包 / @ 切换条 */
    emojiOnly?: boolean;
    canSend?: boolean;
    sending?: boolean;
  }>(),
  {
    activeTab: "emoji",
    emojiOnly: false,
    canSend: false,
    sending: false,
  },
);

const emit = defineEmits<{
  (event: "insert-emoji", key: string): void;
  (event: "send-sticker", payload: { picks: ComposerStickerPick[] }): void;
  (event: "send-text"): void;
  (event: "update:activeTab", tab: "emoji" | "sticker"): void;
}>();

const RECENT_EMOJI_KEY = "flare-core-web-composer-recent-emoji-keys";
const RECENT_STICKER_KEY = "flare-core-web-composer-recent-sticker-ids";
const MAX_RECENT = 20;

type StickerPackTab = "default" | "classic";

const stickerPackTab = ref<StickerPackTab>("classic");

const recentEmojiKeys = ref<string[]>([]);
const recentStickerIds = ref<string[]>([]);

function loadRecent(key: string): string[] {
  if (typeof localStorage === "undefined") return [];
  try {
    const raw = localStorage.getItem(key);
    const parsed = raw ? (JSON.parse(raw) as unknown) : [];
    return Array.isArray(parsed) ? parsed.filter((u): u is string => typeof u === "string") : [];
  } catch {
    return [];
  }
}

function saveRecent(key: string, values: string[]): void {
  if (typeof localStorage === "undefined") return;
  try {
    localStorage.setItem(key, JSON.stringify(values.slice(0, MAX_RECENT)));
  } catch {
    /* quota */
  }
}

function pushRecentOne(key: string, current: string[], value: string): string[] {
  const next = [value, ...current.filter((u) => u !== value)].slice(0, MAX_RECENT);
  saveRecent(key, next);
  return next;
}

function refreshRecents(): void {
  recentEmojiKeys.value = loadRecent(RECENT_EMOJI_KEY);
  recentStickerIds.value = loadRecent(RECENT_STICKER_KEY);
}

refreshRecents();

watch(
  () => props.activeTab,
  (tab) => {
    if (tab === "sticker") refreshRecents();
    else refreshRecents();
  },
);

const emojiByKey = computed(() => {
  const map = new Map<string, ComposerEmojiAssetItem>();
  for (const item of COMPOSER_EMOJI_ITEMS) map.set(item.key, item);
  return map;
});

function stickerRecentId(item: ComposerStickerItem): string {
  return `${item.packageId}/${item.stickerId}`;
}

const stickerById = computed(() => {
  const map = new Map<string, ComposerStickerItem>();
  for (const item of [...COMPOSER_CLASSIC_STICKER_ITEMS, ...COMPOSER_DEFAULT_STICKER_ITEMS]) {
    map.set(stickerRecentId(item), item);
  }
  return map;
});

const recentEmojiItems = computed(() => {
  const map = emojiByKey.value;
  return recentEmojiKeys.value.map((key) => map.get(key)).filter((x): x is ComposerEmojiAssetItem => Boolean(x));
});

const recentStickerItems = computed(() => {
  const map = stickerById.value;
  return recentStickerIds.value.map((id) => map.get(id)).filter((x): x is ComposerStickerItem => Boolean(x));
});

const currentStickerPackItems = computed((): ComposerStickerItem[] =>
  stickerPackTab.value === "classic" ? COMPOSER_CLASSIC_STICKER_ITEMS : COMPOSER_DEFAULT_STICKER_ITEMS,
);

const recentStickerItemsInPack = computed(() => {
  const allowed = new Set(currentStickerPackItems.value.map((item) => stickerRecentId(item)));
  return recentStickerItems.value.filter((item) => allowed.has(stickerRecentId(item)));
});

const stickerPackSectionTitle = computed(() =>
  stickerPackTab.value === "classic" ? "Avatar stickers" : "Default stickers",
);

const defaultPackTabIconSrc = computed(() => COMPOSER_STICKER_PACK_TAB_ICON_URL.default?.trim() ?? "");

const classicPackTabIconSrc = computed(() => COMPOSER_STICKER_PACK_TAB_ICON_URL.classic?.trim() ?? "");

const defaultPackTabIconLoadSrc = computed(() => {
  const custom = COMPOSER_STICKER_PACK_TAB_ICON_URL.default?.trim();
  if (custom) return undefined;
  return COMPOSER_DEFAULT_STICKER_ITEMS[0]?.loadUrl;
});

const classicPackTabIconLoadSrc = computed(() => {
  const custom = COMPOSER_STICKER_PACK_TAB_ICON_URL.classic?.trim();
  if (custom) return undefined;
  return COMPOSER_CLASSIC_STICKER_ITEMS[0]?.loadUrl;
});

function onPickEmoji(item: ComposerEmojiAssetItem): void {
  recentEmojiKeys.value = pushRecentOne(RECENT_EMOJI_KEY, recentEmojiKeys.value, item.key);
  emit("insert-emoji", item.key);
}

async function onPickSticker(item: ComposerStickerItem): Promise<void> {
  const url = await resolveStickerUrlByPackageAndId(item.packageId, item.stickerId);
  recentStickerIds.value = pushRecentOne(RECENT_STICKER_KEY, recentStickerIds.value, stickerRecentId(item));
  emit("send-sticker", {
    picks: [{ stickerId: item.stickerId, packageId: item.packageId, url: url ?? "" }],
  });
}

function setTab(tab: "emoji" | "sticker"): void {
  emit("update:activeTab", tab);
}

function setStickerPack(tab: StickerPackTab): void {
  stickerPackTab.value = tab;
  emit("update:activeTab", "sticker");
}

function onPanelSendClick(): void {
  if (!props.canSend || props.sending) return;
  emit("send-text");
}
</script>

<template>
  <section
    class="composer-emoji-sticker-panel"
    :class="{ 'composer-emoji-sticker-panel--emoji-only': emojiOnly }"
    aria-label="Emoji"
  >
    <div class="panel-scroll">
      <template v-if="activeTab === 'emoji'">
        <section v-if="recentEmojiItems.length > 0" class="panel-section">
          <h3 class="section-heading">Frequently used</h3>
          <div class="asset-grid asset-grid--emoji">
            <button
              v-for="item in recentEmojiItems"
              :key="'r-' + item.id"
              type="button"
              class="asset-cell"
              :title="emojiPackLabel(item.key)"
              @click="onPickEmoji(item)"
            >
              <FrozenStickerThumb :load-src="item.loadUrl" :alt="item.key" />
            </button>
          </div>
        </section>
        <section class="panel-section">
          <h3 class="section-heading">Default emoji</h3>
          <div class="asset-grid asset-grid--emoji">
            <button
              v-for="item in COMPOSER_EMOJI_ITEMS"
              :key="item.id"
              type="button"
              class="asset-cell"
              :title="emojiPackLabel(item.key)"
              @click="onPickEmoji(item)"
            >
              <FrozenStickerThumb :load-src="item.loadUrl" :alt="item.key" />
            </button>
          </div>
        </section>
      </template>
      <template v-else>
        <section v-if="recentStickerItemsInPack.length > 0" class="panel-section">
          <h3 class="section-heading">Frequently used</h3>
          <div class="asset-grid asset-grid--sticker">
            <button
              v-for="item in recentStickerItemsInPack"
              :key="'rs-' + item.id"
              type="button"
              class="asset-cell asset-cell--sticker"
              :title="item.alt"
              @click="onPickSticker(item)"
            >
              <FrozenStickerThumb
                :load-src="item.loadUrl"
                :alt="item.alt"
                play-animated-on-hover
                object-fit="cover"
              />
            </button>
          </div>
        </section>
        <section v-if="currentStickerPackItems.length > 0" class="panel-section">
          <h3 class="section-heading">{{ stickerPackSectionTitle }}</h3>
          <div class="asset-grid asset-grid--sticker">
            <button
              v-for="item in currentStickerPackItems"
              :key="'p-' + item.id"
              type="button"
              class="asset-cell asset-cell--sticker"
              :title="item.alt"
              @click="onPickSticker(item)"
            >
              <FrozenStickerThumb
                :load-src="item.loadUrl"
                :alt="item.alt"
                play-animated-on-hover
                object-fit="cover"
              />
            </button>
          </div>
        </section>
        <section v-else class="panel-section">
          <p class="section-empty">No stickers in this pack</p>
        </section>
      </template>
    </div>

    <div v-if="!emojiOnly" class="panel-tabbar" aria-label="Toggle emoji / stickers">
      <div class="tabbar-row tabbar-row--main">
        <button type="button" class="tab-btn tab-btn--plus" title="More emoji">
          <n-icon :size="22">
            <AddCircleOutline />
          </n-icon>
        </button>
        <button
          type="button"
          class="tab-btn"
          :class="{ 'tab-btn--active': activeTab === 'emoji' }"
          title="Emoji"
          @click="setTab('emoji')"
        >
          <n-icon :size="22">
            <HappyOutline />
          </n-icon>
        </button>
        <div
          v-if="defaultPackTabIconSrc || classicPackTabIconSrc || defaultPackTabIconLoadSrc || classicPackTabIconLoadSrc"
          class="sticker-pack-tabs"
          aria-label="Sticker packs"
        >
          <button
            v-if="classicPackTabIconSrc || classicPackTabIconLoadSrc"
            type="button"
            class="pack-tab pack-tab--thumb"
            :class="{ 'pack-tab--active': activeTab === 'sticker' && stickerPackTab === 'classic' }"
            aria-label="Avatar stickers"
            title="Avatar stickers"
            @click="setStickerPack('classic')"
          >
            <span class="pack-tab-thumb-shell">
              <FrozenStickerThumb
                class="pack-tab-frozen-thumb"
                :src="classicPackTabIconSrc"
                :load-src="classicPackTabIconLoadSrc"
                alt=""
              />
            </span>
          </button>
          <button
            v-if="defaultPackTabIconSrc || defaultPackTabIconLoadSrc"
            type="button"
            class="pack-tab pack-tab--thumb"
            :class="{ 'pack-tab--active': activeTab === 'sticker' && stickerPackTab === 'default' }"
            aria-label="Default stickers"
            title="Default stickers"
            @click="setStickerPack('default')"
          >
            <span class="pack-tab-thumb-shell">
              <FrozenStickerThumb
                class="pack-tab-frozen-thumb"
                :src="defaultPackTabIconSrc"
                :load-src="defaultPackTabIconLoadSrc"
                alt=""
              />
            </span>
          </button>
        </div>
        <div class="tabbar-spacer" />
        <button
          type="button"
          class="panel-send-btn"
          :disabled="!canSend || sending"
          @click.stop="onPanelSendClick"
        >
          {{ sending ? "Sending" : "Send" }}
        </button>
      </div>
    </div>
  </section>
</template>

<style scoped>
.composer-emoji-sticker-panel {
  display: flex;
  flex-direction: column;
  background: var(--composer-emoji-panel-bg, var(--flare-color-bg-tertiary, #f2f3f5));
  border-top: 1px solid var(--im-border, #dfe3ea);
}

.panel-scroll {
  max-height: min(36dvh, 320px);
  overflow-y: auto;
  overflow-x: hidden;
  padding: 10px 12px 6px;
}

.composer-emoji-sticker-panel--emoji-only .panel-scroll {
  max-height: min(32dvh, 280px);
  padding-bottom: 10px;
}

.panel-section + .panel-section {
  margin-top: 4px;
}

.section-heading {
  margin: 0 0 8px;
  padding: 0 2px;
  font-size: 12px;
  font-weight: 600;
  color: var(--composer-emoji-section-muted, #8f9399);
  line-height: 1.3;
}

.section-empty {
  margin: 0;
  padding: 8px 2px;
  font-size: 12px;
  color: var(--composer-emoji-section-muted, #8f9399);
}

.asset-grid {
  display: grid;
  align-items: start;
  justify-content: start;
  gap: 8px 10px;
}

.asset-grid--emoji {
  grid-template-columns: repeat(auto-fill, minmax(52px, 52px));
}

.asset-grid--sticker {
  grid-template-columns: repeat(auto-fill, minmax(72px, 72px));
}

.asset-cell {
  width: 52px;
  height: 52px;
  min-width: 0;
  min-height: 0;
  padding: 4px;
  border: none;
  border-radius: 10px;
  background: transparent;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.12s ease;
}

.asset-cell :deep(.frozen-sticker-thumb-root--fill) {
  width: 36px;
  height: 36px;
}

.asset-cell:hover {
  background: rgba(255, 255, 255, 0.72);
}

.asset-cell--sticker {
  width: 72px;
  height: 72px;
  border-radius: 12px;
  background: #ffffff;
  padding: 6px;
}

.asset-cell--sticker :deep(.frozen-sticker-thumb-root--fill) {
  width: 60px;
  height: 60px;
  border-radius: 8px;
  overflow: hidden;
}

.panel-tabbar {
  padding: 6px 10px calc(8px + env(safe-area-inset-bottom, 0px));
  background: var(--composer-emoji-tabbar-bg, var(--flare-color-bg-primary, #ffffff));
  border-top: 1px solid var(--composer-emoji-tabbar-border, var(--flare-color-border-primary, #e7e9ee));
}

.tabbar-row--main {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 6px;
}

.tabbar-spacer {
  flex: 1 1 auto;
  min-width: 8px;
}

.sticker-pack-tabs {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 6px;
}

.pack-tab {
  flex: 0 0 auto;
  border: none;
  border-radius: 50%;
  padding: 0;
  background: transparent;
  cursor: pointer;
}

.pack-tab--thumb {
  width: 40px;
  height: 40px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.pack-tab-thumb-shell {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(124, 77, 255, 0.08);
  border: 2px solid transparent;
  transition: border-color 0.15s ease, background 0.15s ease, box-shadow 0.15s ease;
}

.pack-tab--thumb.pack-tab--active .pack-tab-thumb-shell {
  background: rgba(124, 77, 255, 0.14);
  border-color: rgba(124, 77, 255, 0.45);
  box-shadow: 0 0 0 2px rgba(124, 77, 255, 0.12);
}

.pack-tab-frozen-thumb :deep(.frozen-sticker-thumb-root--fill) {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  overflow: hidden;
}

.tab-btn {
  flex: 0 0 auto;
  width: 40px;
  height: 40px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  border-radius: 50%;
  background: transparent;
  color: var(--composer-icon-default, rgba(0, 0, 0, 0.45));
  cursor: pointer;
  transition: background 0.12s ease, color 0.12s ease;
}

.tab-btn:hover {
  background: rgba(0, 0, 0, 0.05);
}

.tab-btn--active {
  background: rgba(124, 77, 255, 0.12);
  color: var(--im-primary, #7c4dff);
}

.tab-btn--plus {
  color: var(--composer-icon-default, rgba(0, 0, 0, 0.5));
}

.panel-send-btn {
  flex: 0 0 auto;
  min-width: 64px;
  height: 36px;
  padding: 0 16px;
  border: none;
  border-radius: 18px;
  background: var(--im-primary, #7c4dff);
  color: #ffffff;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.12s ease, background 0.12s ease;
}

.panel-send-btn:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}

.panel-send-btn:not(:disabled):hover {
  background: var(--im-primary-hover, #6d3ef2);
}
</style>
