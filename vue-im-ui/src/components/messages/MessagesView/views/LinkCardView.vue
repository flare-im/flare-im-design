<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { LinkOutline } from "@vicons/ionicons5";
import { NIcon } from "naive-ui";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { readString } from "../../../../utils/contentData";

const props = defineProps<{ content: ContentElem; isSelf: boolean }>();

const payload = computed(() => {
  const nested = pickNestedPayload(props.content, "link_card");
  return Object.keys(nested).length ? nested : (props.content as Record<string, unknown>);
});

const rawUrl = computed(() => readString(payload.value, "url"));
const rawTitle = computed(() => readString(payload.value, "title"));
const description = computed(() => readString(payload.value, "description", "subtitle"));
const siteName = computed(() => readString(payload.value, "siteName", "site_name"));
const thumbnailUrl = computed(() => readString(payload.value, "thumbnailUrl", "thumbnail_url"));
const thumbFailed = ref(false);

watch(thumbnailUrl, () => {
  thumbFailed.value = false;
});

const parsedUrl = computed(() => {
  const url = rawUrl.value;
  if (!url) return null;
  try {
    return new URL(url.includes("://") ? url : `https://${url}`);
  } catch {
    return null;
  }
});

const canOpen = computed(() => {
  const protocol = parsedUrl.value?.protocol;
  return protocol === "http:" || protocol === "https:";
});
const host = computed(() => parsedUrl.value?.hostname.replace(/^www\./i, "") ?? "");
const title = computed(() => rawTitle.value || siteName.value || host.value || rawUrl.value || "Link");
const subtitle = computed(() => description.value || (siteName.value && siteName.value !== title.value ? siteName.value : ""));
const showThumb = computed(() => Boolean(thumbnailUrl.value) && !thumbFailed.value);
const rootTag = computed(() => (canOpen.value ? "a" : "div"));
const rootAttrs = computed(() =>
  canOpen.value && parsedUrl.value
    ? { href: parsedUrl.value.href, target: "_blank", rel: "noopener noreferrer", title: title.value }
    : { role: "group", "aria-label": [title.value, subtitle.value, rawUrl.value].filter(Boolean).join("，") },
);
const footline = computed(() => {
  if (!rawUrl.value) return siteName.value || "Link";
  if (!parsedUrl.value) return rawUrl.value.length > 48 ? `${rawUrl.value.slice(0, 46)}…` : rawUrl.value;
  const path = parsedUrl.value.pathname === "/" ? "" : parsedUrl.value.pathname;
  const full = `${host.value}${path}${parsedUrl.value.search}`;
  return full.length > 54 ? `${full.slice(0, 52)}…` : full;
});
</script>

<template>
  <component
    :is="rootTag"
    class="im-rich-message-card im-link-card"
    :class="{ 'im-link-card--with-thumb': thumbnailUrl }"
    v-bind="rootAttrs"
  >
    <div v-if="thumbnailUrl" class="im-rich-message-card__media">
      <img
        v-if="showThumb"
        :src="thumbnailUrl"
        :alt="title"
        loading="lazy"
        decoding="async"
        @error="thumbFailed = true"
      />
      <n-icon v-else :component="LinkOutline" />
    </div>
    <header class="im-rich-message-card__header">
      <span v-if="!thumbnailUrl" class="im-rich-message-card__icon" aria-hidden="true">
        <n-icon :component="LinkOutline" />
      </span>
      <div class="im-rich-message-card__main">
        <span class="im-rich-message-card__kicker">{{ siteName || host || "Link" }}</span>
        <strong class="im-rich-message-card__title">{{ title }}</strong>
        <p v-if="subtitle" class="im-rich-message-card__subtitle">{{ subtitle }}</p>
      </div>
    </header>
    <footer class="im-rich-message-card__footer">
      <span>{{ footline }}</span>
      <span v-if="canOpen" class="im-rich-message-card__footer-action">Open</span>
    </footer>
  </component>
</template>
