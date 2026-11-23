<script setup lang="ts">
import { ref, computed, onMounted, nextTick, watch, useId } from "vue";
import FlareButton from "../general/FlareButton.vue";
import FlareInput from "../general/FlareInput.vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";
import { flareIcons } from "../../shared/icons";
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
    /** Web: edit the host's location label in place, without opening a second surface. */
    locationEditable?: boolean;
    locationPlaceholder?: string;
    /** Host-owned publish failure. Retrying reports the existing submit intent. */
    submitError?: string;
    /** Visibility label, e.g. "公开" / "仅好友". */
    visibility?: string;
    busy?: boolean;
    /** A standalone card, or a full-height editor inside a page/drawer. */
    layout?: "card" | "page";
  }>(),
  { images: () => [], maxImages: 9, layout: "card", locationEditable: false },
);
const emit = defineEmits<{
  (e: "submit", text: string): void;
  (e: "cancel"): void;
  (e: "addImage"): void;
  (e: "removeImage", index: number): void;
  (e: "pickLocation"): void;
  (e: "update:location", value: string): void;
  (e: "pickVisibility"): void;
}>();

const { t } = useFlareI18n();
const text = ref("");
const input = ref<HTMLTextAreaElement | null>(null);
const locationButton = ref<HTMLButtonElement | null>(null);
const locationId = useId();
const locationEditing = ref(false);
const locationDraft = ref("");
function editLocation() {
  if (props.busy) return;
  if (!props.locationEditable) { emit("pickLocation"); return; }
  locationDraft.value = props.location ?? "";
  locationEditing.value = true;
}
function closeLocation() {
  locationEditing.value = false;
  nextTick(() => locationButton.value?.focus({ preventScroll: true }));
}
function preventLocationSubmit(event: KeyboardEvent) {
  // Focus returns to the opener on commit. Consume this Enter so the browser
  // cannot activate that button and reopen the field with the same keystroke.
  if (event.target instanceof HTMLInputElement && !event.isComposing && event.keyCode !== 229) event.preventDefault();
}
function confirmLocation(restoreFocus = true) {
  if (props.busy || !locationEditing.value) return;
  emit("update:location", locationDraft.value.trim());
  if (restoreFocus) closeLocation();
  else locationEditing.value = false;
}
function requestSubmit() {
  if (props.busy || !canPost.value) return;
  confirmLocation(false);
  emit("submit", text.value.trim());
}
// Keep short drafts compact; longer writing grows to eight lines, then scrolls locally.
function resizeText() {
  const node = input.value;
  if (!node) return;
  node.style.height = "auto";
  const style = getComputedStyle(node);
  const line = parseFloat(style.lineHeight) || 24;
  const padding = (parseFloat(style.paddingTop) || 0) + (parseFloat(style.paddingBottom) || 0);
  node.style.height = `${Math.min(node.scrollHeight, line * 8 + padding)}px`;
}
watch(text, () => nextTick(resizeText));
onMounted(async () => {
  await nextTick();
  resizeText();
  if (props.layout === "page") input.value?.focus({ preventScroll: true });
});
const canPost = computed(() => text.value.trim().length > 0 || props.images.length > 0);
</script>

<template>
  <div class="flare-moment-composer" :class="{ 'is-page': layout === 'page' }" :aria-busy="busy">
    <header class="flare-moment-composer__head" data-flare-overlay-chrome>
      <FlareButton size="sm" variant="ghost" class="flare-moment-composer__cancel" :label="t('moment.cancel')" :disabled="busy" @click="emit('cancel')" />
      <button v-if="layout === 'page'" type="button" class="flare-moment-composer__audience" :disabled="busy" @click="emit('pickVisibility')">
        <n-icon aria-hidden="true" size="var(--flare-size-icon-size-md)" :component="EarthOutline" />
        <span>{{ visibility || t("moment.whoCanSee") }}</span>
      </button>
      <FlareButton size="sm" class="flare-moment-composer__post" :label="t('moment.post')" :loading="busy" :disabled="!canPost || busy" @click="requestSubmit" />
    </header>

    <div v-if="submitError && !busy" class="flare-moment-composer__error">
      <FlareStatusBanner tone="danger" :dot="false" :text="submitError" :action-text="canPost ? t('common.retry') : undefined" @action="requestSubmit" />
    </div>

    <textarea
      ref="input"
      v-model="text"
      class="flare-moment-composer__text"
      :placeholder="t('moment.placeholder')"
      :aria-label="t('moment.placeholder')"
      :disabled="busy"
      rows="3"
    />

    <div class="flare-moment-composer__media" :class="{ 'is-custom': !!$slots.images }">
    <slot name="images" :images="images" :busy="busy">
    <div class="flare-moment-composer__grid">
      <div v-for="(img, i) in images" :key="i" class="flare-moment-composer__thumb">
        <img :src="img" alt="" />
        <button type="button" class="flare-moment-composer__remove" :disabled="busy" :aria-label="t('media.removeImage')" @click="emit('removeImage', i)">
          <n-icon aria-hidden="true" size="var(--flare-size-icon-size-sm)" :component="CloseOutline" />
        </button>
      </div>
      <button
        v-if="images.length < maxImages"
        type="button"
        class="flare-moment-composer__add"
        :disabled="busy"
        :aria-label="t('moment.addImage')"
        @click="emit('addImage')"
      >
        <n-icon aria-hidden="true" size="var(--flare-size-icon-size-lg)" :component="AddOutline" />
      </button>
    </div>

    </slot>
    </div>

    <div class="flare-moment-composer__rows">
      <div v-if="locationEditing" class="flare-moment-composer__location" @keydown.enter.capture="preventLocationSubmit" @keydown.esc.stop.prevent="closeLocation">
        <label :for="locationId" class="flare-moment-composer__sr">{{ t('moment.addLocation') }}</label>
        <FlareInput :id="locationId" v-model="locationDraft" size="sm" clearable autofocus :disabled="busy" :placeholder="locationPlaceholder || t('moment.addLocation')" @submit="confirmLocation()" />
        <FlareIconButton size="sm" :icon="flareIcons.check" :ariaLabel="t('common.confirm')" :disabled="busy" @click="confirmLocation()" />
        <FlareIconButton size="sm" :icon="flareIcons.close" :ariaLabel="t('common.cancel')" :disabled="busy" @click="closeLocation" />
      </div>
      <button v-else ref="locationButton" type="button" class="flare-moment-composer__row" :disabled="busy" @click="editLocation">
        <n-icon aria-hidden="true" size="var(--flare-size-icon-size-md)" :component="LocationOutline" />
        <span>{{ location || t("moment.addLocation") }}</span>
      </button>
      <button v-if="layout !== 'page'" type="button" class="flare-moment-composer__row" :disabled="busy" @click="emit('pickVisibility')">
        <n-icon aria-hidden="true" size="var(--flare-size-icon-size-md)" :component="EarthOutline" />
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
  gap: var(--flare-size-spacing-sm);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-2md);
  border-bottom: 1px solid var(--flare-color-border-primary);
}
.flare-moment-composer__audience {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-2xs);
  min-width: 0;
  min-height: var(--flare-size-layout-touch-target-min);
  padding: 0 var(--flare-size-spacing-sm);
  border: 0;
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-secondary);
  font: inherit;
  font-size: var(--flare-size-font-size-sm);
  cursor: pointer;
}
.flare-moment-composer__audience > :first-child { flex: none; }
.flare-moment-composer__audience > span { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.flare-moment-composer__audience:focus-visible { outline: 2px solid var(--flare-color-border-selected); }
/* 同 FlareMentionPicker:一条整宽的写作区,框不住 —— 2px 实色 outline 在它四周画出的是一个
   巨大的紫色矩形。改成底边加重,仍然是同一个实色 token(对比度达标),但不是一个框。
   小尺寸的输入(如 FlareEmojiPicker 的搜索)保留那圈 outline:那里框得住。 */
.flare-moment-composer__text:focus-visible {
  outline: none;
  box-shadow: inset 0 -2px 0 var(--flare-color-border-selected);
}
.flare-moment-composer__text {
  box-sizing: border-box;
  display: block;
  flex: none;
  width: 100%;
  min-height: calc(3 * 1.55em + 2 * var(--flare-size-spacing-2md));
  overflow-y: auto;
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
.flare-moment-composer__media { flex: none; min-width: 0; }
.flare-moment-composer__error { flex: none; padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-2md) 0; }
.flare-moment-composer__location { display: flex; align-items: center; gap: var(--flare-size-spacing-sm); min-width: 0; min-height: var(--flare-size-layout-touch-target); padding-inline: var(--flare-size-spacing-2md); border-bottom: 1px solid var(--flare-color-border-primary); }
.flare-moment-composer__location > .flare-input { flex: 1; min-width: 0; }
.flare-moment-composer__sr { position: absolute; width: 1px; height: 1px; margin: -1px; overflow: hidden; clip: rect(0, 0, 0, 0); white-space: nowrap; }
.flare-moment-composer__row > span { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.flare-moment-composer__media.is-custom { padding: 0 var(--flare-size-spacing-2md) var(--flare-size-spacing-md); }
.flare-moment-composer__grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  max-width: var(--flare-size-component-media-image-max-width);
  gap: var(--flare-size-spacing-sm);
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
.flare-moment-composer.is-page {
  display: flex;
  flex-direction: column;
  width: 100%;
  height: 100%;
  min-height: 0;
  border: 0;
  border-radius: 0;
  box-shadow: none;
  overflow-y: auto;
}
.is-page .flare-moment-composer__head {
  position: sticky;
  top: 0;
  z-index: 1;
  flex: none;
  background: var(--flare-color-bg-primary);
}
.is-page .flare-moment-composer__grid,
.is-page .flare-moment-composer__rows { flex: none; }
.flare-moment-composer button:disabled,
.flare-moment-composer textarea:disabled { cursor: not-allowed; opacity: .45; }
</style>
