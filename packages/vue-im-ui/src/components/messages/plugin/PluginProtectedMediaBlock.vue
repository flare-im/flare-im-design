<script setup lang="ts">
import { computed, ref } from "vue";
import FlareBottomSheet from "../../general/FlareBottomSheet.vue";
import FlareButton from "../../general/FlareButton.vue";
import FlarePluginForm from "../../form/FlarePluginForm.vue";
import { useFlareI18nOptional } from "../../../shared/i18n/useFlareI18n";
import {
  flarePluginProtectedMediaSource,
  type FlarePluginInput,
  type FlarePluginProtectedItem,
  type FlarePluginProtectedMediaBlock,
  type FlarePluginProtectedMediaState,
} from "../../../shared/contracts/plugin-ui";

// Private material, one item at a time: nothing is fetched until the viewer states why. The block only
// collects the reason; the host runs the action, which authorizes and audits the read, and hands the
// fetched address back in `states`. A source that is not one the kit may show stays undrawn.
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
    <ul v-if="block.items.length" class="flare-plugin-media__list">
      <li v-for="item in block.items" :key="item.id" class="flare-plugin-media__item" :data-media-id="item.id">
        <div class="flare-plugin-media__head">
          <span class="flare-plugin-media__name">{{ item.label }}</span>
          <FlareButton
            v-if="block.action && !sourceOf(item)"
            size="sm"
            variant="secondary"
            :label="block.action.label"
            :loading="states[item.id]?.loading"
            :disabled="busy || states[item.id]?.loading"
            data-media-read="true"
            @click="reading = item"
          />
        </div>
        <template v-if="sourceOf(item)">
          <img v-if="isImage(item)" class="flare-plugin-media__image" :src="sourceOf(item)" :alt="item.label" data-media-image="true" />
          <a v-else class="flare-plugin-media__link" :href="sourceOf(item)" target="_blank" rel="noopener noreferrer" data-media-link="true">{{ t("pluginView.protectedMedia.open") }}</a>
        </template>
        <p v-if="states[item.id]?.error" class="flare-plugin-media__error" role="alert" data-media-error="true">{{ states[item.id]?.error }}</p>
      </li>
    </ul>
    <p v-else class="flare-plugin-media__empty" data-media-empty="true">{{ block.emptyText || t("pluginView.empty") }}</p>
    <p class="flare-plugin-media__notice">{{ t("pluginView.protectedMedia.notice") }}</p>
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
.flare-plugin-media__image { display: block; max-width: 100%; max-height: var(--flare-component-rich-card-width); border-radius: var(--flare-size-radius-md); object-fit: contain; }
.flare-plugin-media__link { font-size: var(--flare-size-font-size-md); color: var(--flare-color-primary-text); }
.flare-plugin-media__error { margin: 0; font-size: var(--flare-size-font-size-sm); color: var(--flare-color-error-text); }
.flare-plugin-media__empty,
.flare-plugin-media__notice { margin: 0; font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-secondary); }
</style>
