<script setup lang="ts">
import { computed } from "vue";
import { LocationOutline } from "../../../../shared/icon-glyphs";
import { NIcon } from "naive-ui";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { readNumber, readString } from "../../../../utils/contentData";

const props = defineProps<{ content: ContentElem; isSelf: boolean }>();

const payload = computed(() => {
  const nested = pickNestedPayload(props.content, "location");
  return Object.keys(nested).length ? nested : (props.content as Record<string, unknown>);
});

const latitude = computed(() => readNumber(payload.value, 0, "latitude", "lat"));
const longitude = computed(() => readNumber(payload.value, 0, "longitude", "lng"));
const title = computed(() => readString(payload.value, "title", "name") || readString(payload.value, "address", "subtitle") || "Location");
const address = computed(() => readString(payload.value, "address", "subtitle"));
const snapshotUrl = computed(() => readString(payload.value, "snapshotUrl", "snapshot_url", "url"));
const mapHref = computed(() => {
  const lat = latitude.value;
  const lng = longitude.value;
  if (!lat && !lng) return "#";
  return `https://maps.google.com/?q=${lat},${lng}`;
});
const canOpen = computed(() => mapHref.value !== "#");
const rootTag = computed(() => (canOpen.value ? "a" : "div"));
const rootAttrs = computed(() =>
  canOpen.value
    ? { href: mapHref.value, target: "_blank", rel: "noopener", title: `${title.value} ${address.value}`.trim() }
    : { role: "group", "aria-label": `${title.value} ${address.value}`.trim() },
);
const coordText = computed(() => {
  if (!canOpen.value) return "";
  return `${latitude.value.toFixed(5)}, ${longitude.value.toFixed(5)}`;
});
</script>

<template>
  <component
    :is="rootTag"
    class="im-rich-message-card im-location-card"
    v-bind="rootAttrs"
  >
    <div class="im-rich-message-card__media">
      <img v-if="snapshotUrl" :src="snapshotUrl" alt="" loading="lazy" />
      <n-icon v-else :component="LocationOutline" />
    </div>
    <div class="im-rich-message-card__body">
      <span class="im-rich-message-card__kicker">Location</span>
      <strong class="im-rich-message-card__title">{{ title }}</strong>
      <p v-if="address" class="im-rich-message-card__subtitle">{{ address }}</p>
    </div>
    <footer class="im-rich-message-card__footer">
      <span>{{ coordText || "Map location" }}</span>
      <span v-if="canOpen" class="im-rich-message-card__footer-action">Open map</span>
    </footer>
  </component>
</template>
