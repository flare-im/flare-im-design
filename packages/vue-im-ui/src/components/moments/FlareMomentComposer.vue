<script setup lang="ts">
import { ref, computed } from "vue";
import { NIcon } from "naive-ui";
import { AddOutline, CloseOutline, LocationOutline, EarthOutline } from "../../shared/icon-glyphs";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    /** Thumbnails already picked by the host (URLs). */
    images?: string[];
    /** Max images before the add tile hides. */
    maxImages?: number;
    location?: string;
    /** Visibility label, e.g. "公开" / "仅好友". */
    visibility?: string;
    busy?: boolean;
  }>(),
  { images: () => [], maxImages: 9 },
);
const emit = defineEmits<{
  (e: "submit", text: string): void;
  (e: "cancel"): void;
  (e: "addImage"): void;
  (e: "removeImage", index: number): void;
  (e: "pickLocation"): void;
  (e: "pickVisibility"): void;
}>();

const { t } = useFlareI18n();
const text = ref("");
const canPost = computed(() => text.value.trim().length > 0 || props.images.length > 0);
</script>

<template>
  <div class="flare-moment-composer">
    <header class="flare-moment-composer__head">
      <button type="button" class="flare-moment-composer__cancel" @click="emit('cancel')">{{ t("moment.cancel") }}</button>
      <button
        type="button"
        class="flare-moment-composer__post"
        :disabled="!canPost || busy"
        @click="emit('submit', text.trim())"
      >{{ t("moment.post") }}</button>
    </header>

    <textarea
      v-model="text"
      class="flare-moment-composer__text"
      :placeholder="t('moment.placeholder')"
      rows="4"
    />

    <div class="flare-moment-composer__grid">
      <div v-for="(img, i) in images" :key="i" class="flare-moment-composer__thumb">
        <img :src="img" alt="" />
        <button type="button" class="flare-moment-composer__remove" :aria-label="t('media.removeImage')" @click="emit('removeImage', i)">
          <n-icon aria-hidden="true" :size="13" :component="CloseOutline" />
        </button>
      </div>
      <button
        v-if="images.length < maxImages"
        type="button"
        class="flare-moment-composer__add"
        :aria-label="t('moment.addImage')"
        @click="emit('addImage')"
      >
        <n-icon aria-hidden="true" :size="26" :component="AddOutline" />
      </button>
    </div>

    <div class="flare-moment-composer__rows">
      <button type="button" class="flare-moment-composer__row" @click="emit('pickLocation')">
        <n-icon aria-hidden="true" :size="18" :component="LocationOutline" />
        <span>{{ location || t("moment.addLocation") }}</span>
      </button>
      <button type="button" class="flare-moment-composer__row" @click="emit('pickVisibility')">
        <n-icon aria-hidden="true" :size="18" :component="EarthOutline" />
        <span>{{ visibility || t("moment.whoCanSee") }}</span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.flare-moment-composer {
  width: 360px;
  max-width: 100%;
  background: var(--flare-color-bg-primary);
  border-radius: var(--flare-size-radius-xl);
  border: 1px solid var(--flare-color-border-primary);
  box-shadow: var(--flare-shadow-lg);
  overflow: hidden;
}
.flare-moment-composer__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px var(--flare-size-spacing-2md);
  border-bottom: 1px solid var(--flare-color-border-primary);
}
.flare-moment-composer__cancel {
  border: none;
  background: none;
  color: var(--flare-color-text-secondary);
  font-size: 14px;
  cursor: pointer;
}
.flare-moment-composer__post {
  border: none;
  border-radius: 999px;
  padding: 6px 18px;
  background: var(--flare-component-brand-primary);
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.15s ease, filter 0.15s ease;
}
.flare-moment-composer__post:disabled { opacity: 0.45; cursor: not-allowed; }
.flare-moment-composer__post:hover:not(:disabled) { filter: brightness(0.97); }
/* 同 FlareMentionPicker:一条整宽的写作区,框不住 —— 2px 实色 outline 在它四周画出的是一个
   巨大的紫色矩形。改成底边加重,仍然是同一个实色 token(对比度达标),但不是一个框。
   小尺寸的输入(如 FlareEmojiPicker 的搜索)保留那圈 outline:那里框得住。 */
.flare-moment-composer__text:focus-visible {
  outline: none;
  box-shadow: inset 0 -2px 0 var(--flare-color-border-selected);
}
.flare-moment-composer__text {
  width: 100%;
  border: none;
  outline: none;
  resize: none;
  padding: var(--flare-size-spacing-2md);
  font-size: 15px;
  line-height: 1.55;
  color: var(--flare-color-text-primary);
  background: transparent;
  font-family: inherit;
}
.flare-moment-composer__grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 6px;
  padding: 0 var(--flare-size-spacing-2md) 12px;
}
.flare-moment-composer__thumb {
  position: relative;
  aspect-ratio: 1;
  border-radius: 8px;
  overflow: hidden;
  background: var(--flare-color-bg-secondary);
}
.flare-moment-composer__thumb img { width: 100%; height: 100%; object-fit: cover; }
.flare-moment-composer__remove {
  position: absolute;
  top: 2px;
  right: 2px;
  width: 18px;
  height: 18px;
  border: none;
  border-radius: 50%;
  background: rgba(17, 19, 24, 0.55);
  color: #fff;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}
.flare-moment-composer__add {
  aspect-ratio: 1;
  border: 1px dashed var(--flare-color-border-hover);
  border-radius: 8px;
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-tertiary);
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  transition: border-color 0.15s ease, color 0.15s ease;
}
.flare-moment-composer__add:hover { border-color: var(--flare-color-primary); color: var(--flare-color-primary-text); }
.flare-moment-composer__rows { border-top: 1px solid var(--flare-color-border-primary); }
.flare-moment-composer__row {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-2sm);
  width: 100%;
  padding: 13px var(--flare-size-spacing-2md);
  border: none;
  border-bottom: 1px solid var(--flare-color-border-primary);
  background: none;
  color: var(--flare-color-text-secondary);
  font-size: 14px;
  cursor: pointer;
  text-align: left;
}
.flare-moment-composer__row:last-child { border-bottom: none; }
.flare-moment-composer__row:hover { background: var(--flare-color-bg-secondary); }
</style>
