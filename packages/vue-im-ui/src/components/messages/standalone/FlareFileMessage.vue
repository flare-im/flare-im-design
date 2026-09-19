<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import MsgIcon from "./MsgIcon.vue";
import { useFlareI18nOptional } from "../../../shared/i18n/useFlareI18n";

// Presentational — the host owns the file URL and does the actual fetch on
// `download` (and `open` for the card); the component never touches the URL.
// Override the leading icon via the `icon` slot. `state` mirrors the host's
// download lifecycle so the trailing action and the meta line reflect it, and
// `embedded` drops the card chrome when the body sits inside a message bubble
// (how the timeline dispatcher renders it). Without an `open` / `download`
// listener the matching affordance is not rendered.
type FileState = "idle" | "downloading" | "downloaded" | "openFolder" | "unavailable";

const props = withDefaults(
  defineProps<{
    name?: string;
    size?: string;
    ext?: string;
    description?: string;
    state?: FileState;
    downloadLabel?: string;
    embedded?: boolean;
  }>(),
  { name: "file", size: "", ext: "", description: "", state: "idle", downloadLabel: "", embedded: false },
);
const emit = defineEmits<{ (e: "open"): void; (e: "download"): void }>();
const { t } = useFlareI18nOptional();
const instance = getCurrentInstance();
// Read from the vnode at render time so a host that wires `download` later
// (once its media action resolves) gets the affordance.
const hasListener = (name: "onOpen" | "onDownload") => Boolean(instance?.vnode.props?.[name]);

const subline = computed(() => {
  switch (props.state) {
    case "downloading":
      return t("messageMenu.downloadingMedia");
    case "downloaded":
      return t("messageMenu.downloadedMedia");
    case "openFolder":
      return t("mediaMessage.savedToDevice");
    case "unavailable":
      return t("mediaMessage.noDownloadUrl");
    default:
      return [props.size, props.ext].filter(Boolean).join(" · ");
  }
});
const actionLabel = computed(() => {
  switch (props.state) {
    case "downloading":
      return t("messageMenu.downloadingMedia");
    case "downloaded":
      return t("messageMenu.downloadedMedia");
    case "openFolder":
      return t("messageMenu.openMediaFolder");
    case "unavailable":
      return t("mediaMessage.noDownloadUrl");
    default:
      return props.downloadLabel || t("messageMenu.downloadMedia");
  }
});
const actionIcon = computed(() =>
  props.state === "downloaded" ? "check" : props.state === "openFolder" ? "folder" : "download",
);
const actionDisabled = computed(
  () => props.state === "downloading" || props.state === "downloaded" || props.state === "unavailable",
);
</script>
<template>
  <div class="fm-file" :class="{ 'fm-file--embedded': embedded, [`fm-file--${state}`]: true }">
    <component
      :is="hasListener('onOpen') ? 'button' : 'div'"
      :type="hasListener('onOpen') ? 'button' : undefined"
      class="main"
      @click="hasListener('onOpen') && emit('open')"
    >
      <span class="ic"><slot name="icon"><MsgIcon name="file" :size="22" /></slot></span>
      <span class="meta">
        <b>{{ name }}</b>
        <small v-if="description" class="desc">{{ description }}</small>
        <small v-if="subline" class="sub">{{ subline }}</small>
      </span>
    </component>
    <button
      v-if="hasListener('onDownload')"
      type="button"
      class="dl"
      :disabled="actionDisabled"
      :aria-label="actionLabel"
      :title="actionLabel"
      @click.stop="emit('download')"
    >
      <MsgIcon :name="actionIcon" :size="17" />
    </button>
    <span v-if="state === 'downloading'" class="bar" aria-hidden="true"><span /></span>
  </div>
</template>
<style scoped>
.fm-file {
  position: relative;
  display: inline-flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
  max-width: 300px;
  padding: 9px 14px;
  border-radius: 16px 16px 16px 4px;
  color: var(--flare-color-text-primary);
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-secondary);
  box-shadow: var(--flare-component-bubble-shadow);
}
.fm-file--embedded {
  max-width: min(300px, 100%);
  padding: 0;
  border: 0;
  border-radius: 0;
  color: inherit;
  background: transparent;
  box-shadow: none;
}
.main {
  display: inline-flex;
  flex: 1;
  align-items: center;
  gap: 10px;
  min-width: 0;
  padding: 0;
  border: 0;
  color: inherit;
  font: inherit;
  text-align: left;
  background: none;
  cursor: default;
}
button.main { cursor: pointer; }
button.main:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; border-radius: var(--flare-size-radius-sm); }
.ic { display: flex; flex: none; color: var(--flare-color-primary-text); }
.fm-file--embedded .ic { color: inherit; }
.meta { display: flex; flex: 1; flex-direction: column; gap: 1px; min-width: 0; }
.meta b,
.meta small { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; line-height: 1.35; }
.meta b { font-size: var(--flare-size-font-size-lg); font-weight: 500; }
.meta small { font-size: var(--flare-size-font-size-xs); color: var(--flare-color-text-tertiary); }
.fm-file--embedded .meta small { color: color-mix(in srgb, currentColor 72%, transparent); }
.dl {
  display: grid;
  flex: none;
  place-items: center;
  width: 32px;
  height: 32px;
  padding: 0;
  border: 0;
  border-radius: var(--flare-size-radius-md);
  color: var(--flare-color-text-tertiary);
  background: none;
  cursor: pointer;
  transition: background-color var(--flare-component-motion-fast), color var(--flare-component-motion-fast);
}
.fm-file--embedded .dl { color: inherit; }
.dl:hover:not(:disabled) { background: color-mix(in srgb, currentColor 10%, transparent); }
.dl:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.dl:disabled { cursor: default; }
.fm-file--unavailable .dl { opacity: 0.42; }
.fm-file--unavailable .meta { opacity: 0.72; }
.fm-file--downloaded .dl { color: var(--flare-color-success-text); }
.fm-file--embedded.fm-file--downloaded .dl { color: inherit; }
.bar {
  flex: 1 0 100%;
  height: 3px;
  margin-top: -4px;
  overflow: hidden;
  border-radius: var(--flare-size-radius-full);
  background: color-mix(in srgb, currentColor 16%, transparent);
}
.bar > span {
  display: block;
  width: 38%;
  height: 100%;
  border-radius: inherit;
  background: currentColor;
  animation: fm-file-progress 1.1s ease-in-out infinite;
}
@keyframes fm-file-progress {
  0% { transform: translateX(-110%); }
  50% { transform: translateX(85%); }
  100% { transform: translateX(240%); }
}
@media (prefers-reduced-motion: reduce) {
  .bar > span { width: 100%; opacity: 0.5; animation: none; }
}
</style>
