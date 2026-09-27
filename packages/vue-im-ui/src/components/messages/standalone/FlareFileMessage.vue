<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import MsgIcon from "./MsgIcon.vue";
import { useFlareI18nOptional } from "../../../shared/i18n/useFlareI18n";

// Presentational — the host owns the file URL and does the actual fetch on
// `download` (and `open` for the card); the component never touches the URL.
// Override the leading icon via the `icon` slot. `state` mirrors the host's
// download lifecycle so the trailing key and the meta line reflect it, and
// `embedded` drops the card chrome when the body sits inside a message bubble
// (how the timeline dispatcher renders it). The trailing key is a download
// until the file is saved (`openFolder`, or `downloaded` right after the save),
// then a folder that emits `reveal` — the host shows the file in its folder, or
// passes `idle` again when the file is gone. Without an `open` / `download`
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
const emit = defineEmits<{ (e: "open"): void; (e: "download"): void; (e: "reveal"): void }>();
const { t } = useFlareI18nOptional();
const instance = getCurrentInstance();
// Read from the vnode at render time so a host that wires `download` later
// (once its media action resolves) gets the affordance.
const hasListener = (name: "onOpen" | "onDownload") => Boolean(instance?.vnode.props?.[name]);
const saved = computed(() => props.state === "openFolder" || props.state === "downloaded");

// Size and type stay on the line whatever the state; the state is said after them.
const subline = computed(() => {
  if (props.state === "unavailable") return t("mediaMessage.noDownloadUrl");
  const facts = [props.size, props.ext].filter(Boolean);
  if (props.state === "downloading") facts.push(t("messageMenu.downloadingMedia"));
  else if (saved.value) facts.push(t("messageMenu.downloadedMedia"));
  return facts.join(" · ");
});
const actionLabel = computed(() => {
  if (saved.value) return t("messageMenu.openMediaFolder");
  switch (props.state) {
    case "downloading":
      return t("messageMenu.downloadingMedia");
    case "unavailable":
      return t("mediaMessage.noDownloadUrl");
    default:
      return props.downloadLabel || t("messageMenu.downloadMedia");
  }
});
const actionIcon = computed(() => (saved.value ? "folder" : "download"));
const actionDisabled = computed(() => props.state === "downloading" || props.state === "unavailable");

function onAction(): void {
  if (actionDisabled.value) return;
  if (saved.value) emit("reveal");
  else emit("download");
}
</script>
<template>
  <div class="fm-file" :class="{ 'fm-file--embedded': embedded, 'fm-file--saved': saved, [`fm-file--${state}`]: true }">
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
      @click.stop="onAction"
    >
      <span v-if="state === 'downloading'" class="spin" aria-hidden="true" />
      <MsgIcon v-else :name="actionIcon" :size="18" />
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
  gap: var(--flare-size-spacing-2sm);
  max-width: 300px;
  padding: 9px var(--flare-size-spacing-2md);
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
  gap: var(--flare-size-spacing-2sm);
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
/* A saved file's key is the folder, in the accent: the one thing on the card that goes somewhere else. */
.fm-file--saved .dl { color: var(--flare-color-primary-text); }
.fm-file--embedded.fm-file--saved .dl {
  color: inherit;
  background: color-mix(in srgb, currentColor 12%, transparent);
}
.spin {
  width: var(--flare-size-icon-size-sm);
  height: var(--flare-size-icon-size-sm);
  border: 2px solid color-mix(in srgb, currentColor 26%, transparent);
  border-top-color: currentColor;
  border-radius: 50%;
  animation: fm-file-spin 0.9s linear infinite;
}
@keyframes fm-file-spin { to { transform: rotate(360deg); } }
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
  .spin { animation: none; }
}
</style>
