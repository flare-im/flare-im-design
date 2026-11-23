<script setup lang="ts">
import { computed, ref, watch } from "vue";
import FlareBottomSheet from "../../general/FlareBottomSheet.vue";
import FlareButton from "../../general/FlareButton.vue";
import FlareIcon from "../../general/FlareIcon.vue";
import FlareImagePreview from "../../message-preview/ImagePreviewModal.vue";
import FlarePluginForm from "../../form/FlarePluginForm.vue";
import { useFlareI18nOptional } from "../../../shared/i18n/useFlareI18n";
import {
  flarePluginProtectedMediaSource,
  type FlarePluginInput,
  type FlarePluginProtectedItem,
  type FlarePluginProtectedMediaBlock,
  type FlarePluginProtectedMediaState,
} from "../../../shared/contracts/plugin-ui";

// Private material is fetched by the host after it authorizes and audits the read. A block that declares
// `reasonInput` (a console reviewing someone else's material) first asks why; the owner's own page declares
// none, so one tap reads (spec/capability-ui-vectors.json protectedMediaReason). The host runs the action, which
// authorizes and audits the read, and hands the address back in `states`: the server's short-lived https address
// with its `?grant=`, or what the host fetched. A source that is not one the kit may show stays undrawn. The
// picture is not draggable and has no context menu: the kit offers no way to save or share it.
const props = withDefaults(defineProps<{
  block: FlarePluginProtectedMediaBlock;
  /** What the host has for each item, by item id. */
  states?: Record<string, FlarePluginProtectedMediaState>;
  busy?: boolean;
}>(), { states: () => ({}), busy: false });
const emit = defineEmits<{ (e: "read", item: FlarePluginProtectedItem, reason: string): void }>();
const { t } = useFlareI18nOptional();

const reading = ref<FlarePluginProtectedItem | null>(null);
const reasonInputs = computed<FlarePluginInput[]>(() => [
  { id: "reason", kind: "textarea", label: t("pluginView.protectedMedia.reason"), required: true, maxLength: 160 },
]);
const sourceOf = (item: FlarePluginProtectedItem) => flarePluginProtectedMediaSource(props.states[item.id]?.url);
const isImage = (item: FlarePluginProtectedItem) => !item.mediaType || item.mediaType.startsWith("image/");
const asksReason = computed(() => Boolean(props.block.reasonInput));
const inline = computed(() => props.block.inlinePreview === true);
function request(item: FlarePluginProtectedItem): void {
  if (asksReason.value) reading.value = item;
  else emit("read", item, "");
}
// 6.1: the owner's own page draws its documents as blurred 16:10 thumbnails; a tap reads the item (once) and the
// picture opens full screen as soon as the host hands its address back. The reviewer's console keeps its list.
const thumbnails = computed(() => !asksReason.value && !inline.value);
const opening = ref<string | null>(null);
const previewing = ref<FlarePluginProtectedItem | null>(null);
function tapThumbnail(item: FlarePluginProtectedItem): void {
  if (props.busy || props.states[item.id]?.loading) return;
  if (sourceOf(item)) { previewing.value = item; return; }
  opening.value = item.id;
  request(item);
}
watch(() => props.states, (states) => {
  const item = props.block.items.find((candidate) => candidate.id === opening.value);
  if (!item || states[item.id]?.loading) return;
  opening.value = null;
  if (sourceOf(item)) previewing.value = item;
}, { deep: true });
function submit(values: Record<string, unknown>): void {
  const item = reading.value;
  const reason = typeof values.reason === "string" ? values.reason.trim() : "";
  if (!item || !reason) return;
  reading.value = null;
  emit("read", item, reason);
}
</script>

<template>
  <section class="flare-plugin-media" :aria-label="block.label">
    <h4 v-if="block.label" class="flare-plugin-media__label">{{ block.label }}</h4>
    <ul v-if="block.items.length && thumbnails" class="flare-plugin-media__grid" data-media-thumbnails="true">
      <li v-for="item in block.items" :key="item.id" class="flare-plugin-media__cell" :data-media-id="item.id">
        <a
          v-if="sourceOf(item) && !isImage(item)"
          class="flare-plugin-media__thumb"
          :href="sourceOf(item)"
          target="_blank"
          rel="noopener noreferrer"
          :aria-label="`${t('pluginView.protectedMedia.open')} ${item.label}`"
          data-media-link="true"
        ><FlareIcon name="file" size="lg" aria-hidden="true" /></a>
        <button
          v-else
          type="button"
          class="flare-plugin-media__thumb"
          :class="{ 'is-loading': states[item.id]?.loading }"
          :aria-label="t('pluginView.protectedMedia.tapToView', { label: item.label })"
          :aria-busy="states[item.id]?.loading || undefined"
          :disabled="busy || (!block.action && !sourceOf(item))"
          data-media-read="true"
          @click="tapThumbnail(item)"
        >
          <img
            v-if="sourceOf(item)"
            class="flare-plugin-media__thumb-image"
            :src="sourceOf(item)"
            alt=""
            draggable="false"
            referrerpolicy="no-referrer"
            data-media-image="true"
            @contextmenu.prevent
            @dragstart.prevent
          />
          <FlareIcon class="flare-plugin-media__eye" name="eye" size="md" aria-hidden="true" />
        </button>
        <span class="flare-plugin-media__caption" aria-hidden="true">{{ item.label }}</span>
        <p v-if="states[item.id]?.error" class="flare-plugin-media__error" role="alert" data-media-error="true">{{ states[item.id]?.error }}</p>
      </li>
    </ul>
    <ul v-else-if="block.items.length" class="flare-plugin-media__list">
      <li v-for="item in block.items" :key="item.id" class="flare-plugin-media__item" :data-media-id="item.id">
        <div class="flare-plugin-media__head">
          <span class="flare-plugin-media__name">{{ item.label }}</span>
          <FlareButton
            v-if="!inline && block.action && !sourceOf(item)"
            size="sm"
            variant="secondary"
            :label="block.action.label"
            :loading="states[item.id]?.loading"
            :disabled="busy || states[item.id]?.loading"
            data-media-read="true"
            @click="request(item)"
          />
        </div>
        <p v-if="inline && states[item.id]?.loading" class="flare-plugin-media__notice" role="status">
          {{ t("pluginView.loading") }}
        </p>
        <template v-if="sourceOf(item)">
          <img
            v-if="isImage(item)"
            class="flare-plugin-media__image"
            :src="sourceOf(item)"
            :alt="item.label"
            draggable="false"
            referrerpolicy="no-referrer"
            data-media-image="true"
            @contextmenu.prevent
            @dragstart.prevent
          />
          <a v-else class="flare-plugin-media__link" :href="sourceOf(item)" target="_blank" rel="noopener noreferrer" data-media-link="true">{{ t("pluginView.protectedMedia.open") }}</a>
        </template>
        <p v-if="states[item.id]?.error" class="flare-plugin-media__error" role="alert" data-media-error="true">{{ states[item.id]?.error }}</p>
      </li>
    </ul>
    <p v-else class="flare-plugin-media__empty" data-media-empty="true">{{ block.emptyText || t("pluginView.empty") }}</p>
    <p v-if="!inline" class="flare-plugin-media__notice">{{ asksReason ? t("pluginView.protectedMedia.notice") : t("pluginView.protectedMedia.ownNotice") }}</p>
    <FlareImagePreview
      v-if="thumbnails"
      :show="Boolean(previewing && sourceOf(previewing))"
      :image-src="previewing ? sourceOf(previewing) ?? '' : ''"
      :alt="previewing?.label"
      @update:show="(show: boolean) => { if (!show) previewing = null; }"
    />
    <FlareBottomSheet :open="Boolean(reading)" :title="block.action?.label" @close="reading = null">
      <FlarePluginForm v-if="reading" :inputs="reasonInputs" :submit-label="block.action?.label" @submit="submit" @cancel="reading = null" />
    </FlareBottomSheet>
  </section>
</template>

<style scoped>
.flare-plugin-media { display: grid; gap: var(--flare-size-spacing-xs); min-width: 0; }
.flare-plugin-media__label { margin: 0; font-size: var(--flare-size-font-size-md); font-weight: var(--flare-size-font-weight-medium); color: var(--flare-color-text-primary); }
.flare-plugin-media__list { display: grid; gap: var(--flare-size-spacing-sm); margin: 0; padding: 0; list-style: none; }
.flare-plugin-media__item { display: grid; gap: var(--flare-size-spacing-xs); min-width: 0; }
.flare-plugin-media__head { display: flex; align-items: center; justify-content: space-between; gap: var(--flare-size-spacing-sm); min-width: 0; }
.flare-plugin-media__name { min-width: 0; font-size: var(--flare-size-font-size-md); color: var(--flare-color-text-primary); overflow-wrap: anywhere; }
.flare-plugin-media__image { display: block; user-select: none; -webkit-user-select: none; -webkit-touch-callout: none; max-width: 100%; max-height: var(--flare-component-rich-card-width); border-radius: var(--flare-size-radius-md); object-fit: contain; }
/* 6.1 thumbnails: 3 across, 16:10, at most component.documentThumbHeight (72) high, blurred until opened full screen. */
.flare-plugin-media__grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, calc(var(--flare-size-component-document-thumb-height) * 1.6)));
  gap: var(--flare-size-spacing-sm);
  margin: 0;
  padding: 0;
  list-style: none;
}
.flare-plugin-media__cell { display: grid; gap: var(--flare-size-spacing-2xs); min-width: 0; }
.flare-plugin-media__thumb {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  aspect-ratio: 16 / 10;
  padding: 0;
  overflow: hidden;
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-secondary);
  cursor: pointer;
}
.flare-plugin-media__thumb::after {
  content: "";
  position: absolute;
  top: 50%;
  left: 50%;
  width: max(100%, var(--flare-size-layout-touch-target));
  height: max(100%, var(--flare-size-layout-touch-target));
  transform: translate(-50%, -50%);
}
.flare-plugin-media__thumb:disabled { cursor: not-allowed; opacity: var(--flare-opacity-disabled); }
.flare-plugin-media__thumb.is-loading { opacity: var(--flare-opacity-muted); }
.flare-plugin-media__thumb:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-plugin-media__thumb-image {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
  filter: blur(var(--flare-size-spacing-sm));
  transform: scale(1.1);
  user-select: none;
  -webkit-user-select: none;
  -webkit-touch-callout: none;
}
.flare-plugin-media__eye { position: relative; }
.flare-plugin-media__caption {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-secondary);
}
.flare-plugin-media__link { font-size: var(--flare-size-font-size-md); color: var(--flare-color-primary-text); }
.flare-plugin-media__error { margin: 0; font-size: var(--flare-size-font-size-sm); color: var(--flare-color-error-text); }
.flare-plugin-media__empty,
.flare-plugin-media__notice { margin: 0; font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-secondary); }
</style>
