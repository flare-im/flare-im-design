<script setup lang="ts">
import { computed } from "vue";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { readNumber, readString } from "../../../../utils/contentData";
import { useFlareI18n } from "../../../../shared/i18n/useFlareI18n";
import FlareLocationMessage from "../../standalone/FlareLocationMessage.vue";

// Timeline adapter: content elem → the contract body. The kit still links out to a map when the
// payload carries coordinates (previous behaviour); the body itself only emits `open`.
const props = defineProps<{ content: ContentElem; isSelf: boolean }>();
const { t } = useFlareI18n();

const payload = computed(() => {
  const nested = pickNestedPayload(props.content, "location");
  return Object.keys(nested).length ? nested : (props.content as Record<string, unknown>);
});

const latitude = computed(() => readNumber(payload.value, 0, "latitude", "lat"));
const longitude = computed(() => readNumber(payload.value, 0, "longitude", "lng"));
const coordText = computed(() => (latitude.value || longitude.value ? `${latitude.value.toFixed(5)}, ${longitude.value.toFixed(5)}` : ""));
const title = computed(() => readString(payload.value, "title", "name") || readString(payload.value, "address", "subtitle") || t("composer.location"));
const address = computed(() => readString(payload.value, "address", "subtitle") || coordText.value);
const snapshotUrl = computed(() => readString(payload.value, "snapshotUrl", "snapshot_url", "url"));
const mapHref = computed(() => (coordText.value ? `https://maps.google.com/?q=${latitude.value},${longitude.value}` : ""));
</script>

<template>
  <a v-if="mapHref" class="im-location" :href="mapHref" target="_blank" rel="noopener noreferrer" :title="`${title} ${address}`.trim()">
    <FlareLocationMessage :title="title" :address="address" :map-image="snapshotUrl" />
  </a>
  <div v-else class="im-location" role="group" :aria-label="`${title} ${address}`.trim()">
    <FlareLocationMessage :title="title" :address="address" :map-image="snapshotUrl" />
  </div>
</template>

<style scoped>
.im-location { display: inline-block; max-width: 100%; text-decoration: none; color: inherit; }
</style>
