<script setup lang="ts">
import { computed } from "vue";
import { safeExternalUrl } from "../../../../shared/contracts/url-safety";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { readString } from "../../../../utils/contentData";
import { useFlareI18n } from "../../../../shared/i18n/useFlareI18n";
import FlareLinkCardMessage from "../../standalone/FlareLinkCardMessage.vue";

// Timeline adapter: link_card payload → the contract body. Only http(s) links become anchors
// (javascript:/data: and unparsable URLs render as an inert card) — the security boundary stays here.
const props = defineProps<{ content: ContentElem; isSelf: boolean }>();
const { t } = useFlareI18n();

const payload = computed(() => {
  const nested = pickNestedPayload(props.content, "link_card");
  return Object.keys(nested).length ? nested : (props.content as Record<string, unknown>);
});

const rawUrl = computed(() => readString(payload.value, "url"));
const description = computed(() => readString(payload.value, "description", "subtitle"));
const siteName = computed(() => readString(payload.value, "siteName", "site_name"));
const thumbnailUrl = computed(() => readString(payload.value, "thumbnailUrl", "thumbnail_url"));

const parsedUrl = computed(() => {
  const url = rawUrl.value;
  if (!url) return null;
  try {
    return new URL(url.includes("://") ? url : `https://${url}`);
  } catch {
    return null;
  }
});
// One rule for "may this open", shared with the host's own link handler.
const safeHref = computed(() => safeExternalUrl(rawUrl.value));
const canOpen = computed(() => safeHref.value !== null);
const host = computed(() => parsedUrl.value?.hostname.replace(/^www\./i, "") ?? "");
const title = computed(() => readString(payload.value, "title") || siteName.value || host.value || rawUrl.value || t("composer.link"));
const subtitle = computed(() => description.value || (siteName.value && siteName.value !== title.value ? siteName.value : ""));
const domain = computed(() => {
  if (!parsedUrl.value) return siteName.value || rawUrl.value.slice(0, 48);
  const path = parsedUrl.value.pathname === "/" ? "" : parsedUrl.value.pathname;
  const full = `${host.value}${path}${parsedUrl.value.search}`;
  return full.length > 54 ? `${full.slice(0, 52)}…` : full;
});
const label = computed(() => [title.value, subtitle.value, rawUrl.value].filter(Boolean).join("，"));
</script>

<template>
  <a v-if="safeHref" class="im-link-card" :href="safeHref" target="_blank" rel="noopener noreferrer" :title="title">
    <FlareLinkCardMessage :title="title" :domain="domain" :thumb="thumbnailUrl" :description="subtitle" />
  </a>
  <div v-else class="im-link-card" role="group" :aria-label="label">
    <FlareLinkCardMessage :title="title" :domain="domain" :thumb="thumbnailUrl" :description="subtitle" />
  </div>
</template>

<style scoped>
.im-link-card { display: inline-block; max-width: 100%; text-decoration: none; color: inherit; }
</style>
