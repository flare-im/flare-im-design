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
        <button type="button" class="flare-moment-composer__remove" @click="emit('removeImage', i)">
          <n-icon :size="13" :component="CloseOutline" />
        </button>
      </div>
      <button
        v-if="images.length < maxImages"
        type="button"
        class="flare-moment-composer__add"
        :aria-label="t('moment.addImage')"
        @click="emit('addImage')"
      >
        <n-icon :size="26" :component="AddOutline" />
      </button>
    </div>

    <div class="flare-moment-composer__rows">
      <button type="button" class="flare-moment-composer__row" @click="emit('pickLocation')">
        <n-icon :size="18" :component="LocationOutline" />
        <span>{{ location || t("moment.addLocation") }}</span>
      </button>
      <button type="button" class="flare-moment-composer__row" @click="emit('pickVisibility')">
        <n-icon :size="18" :component="EarthOutline" />
        <span>{{ visibility || t("moment.whoCanSee") }}</span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.flare-moment-composer {
  width: 360px;
  max-width: 100%;
  background: var(--flare-color-bg-primary, #fff);
  border-radius: var(--flare-size-radius-xl, 14px);
  border: 1px solid var(--flare-color-border-primary, #e9e6f1);
  box-shadow: var(--flare-shadow-lg, 0 12px 28px rgba(21, 18, 32, 0.16));
  overflow: hidden;
}
.flare-moment-composer__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 14px;
  border-bottom: 1px solid var(--flare-color-border-primary, #e9e6f1);
}
.flare-moment-composer__cancel {
  border: none;
  background: none;
  color: var(--flare-color-text-secondary, #6b6780);
  font-size: 14px;
  cursor: pointer;
}
.flare-moment-composer__post {
  border: none;
  border-radius: 999px;
  padding: 6px 18px;
  background: var(--im-brand-gradient, var(--flare-color-primary, #7c3aed));
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.15s ease, filter 0.15s ease;
}
.flare-moment-composer__post:disabled { opacity: 0.45; cursor: not-allowed; }
.flare-moment-composer__post:hover:not(:disabled) { filter: brightness(0.97); }
.flare-moment-composer__text {
  width: 100%;
  border: none;
  outline: none;
  resize: none;
  padding: 14px;
  font-size: 15px;
  line-height: 1.55;
  color: var(--flare-color-text-primary, #15131c);
  background: transparent;
  font-family: inherit;
}
.flare-moment-composer__grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 6px;
  padding: 0 14px 12px;
}
.flare-moment-composer__thumb {
  position: relative;
  aspect-ratio: 1;
  border-radius: 8px;
  overflow: hidden;
  background: var(--flare-color-bg-secondary, #f6f5fb);
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
  border: 1px dashed var(--flare-color-border-hover, #d5d1e0);
  border-radius: 8px;
  background: var(--flare-color-bg-secondary, #f6f5fb);
  color: var(--flare-color-text-tertiary, #a7a2b4);
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  transition: border-color 0.15s ease, color 0.15s ease;
}
.flare-moment-composer__add:hover { border-color: var(--flare-color-primary, #7c3aed); color: var(--flare-color-primary, #7c3aed); }
.flare-moment-composer__rows { border-top: 1px solid var(--flare-color-border-primary, #e9e6f1); }
.flare-moment-composer__row {
  display: flex;
  align-items: center;
  gap: 10px;
  width: 100%;
  padding: 13px 14px;
  border: none;
  border-bottom: 1px solid var(--flare-color-border-primary, #e9e6f1);
  background: none;
  color: var(--flare-color-text-secondary, #6b6780);
  font-size: 14px;
  cursor: pointer;
  text-align: left;
}
.flare-moment-composer__row:last-child { border-bottom: none; }
.flare-moment-composer__row:hover { background: var(--flare-color-bg-secondary, #f6f5fb); }
</style>
