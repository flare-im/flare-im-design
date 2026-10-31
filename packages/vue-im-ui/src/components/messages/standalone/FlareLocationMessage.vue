<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import LocationMapSurface from "./LocationMapSurface.vue";
import { useFlareI18nOptional } from "../../../shared/i18n/useFlareI18n";
import {
  FLARE_LOCATION_CARD_MAP,
  flareLocationCardLines,
  flareLocationMapLinks,
  type FlareLocationProvider,
} from "../../../shared/contracts/location";

// A location card: the static map (or a drawn map with a centre pin), then the place and its address
// (spec/location-vectors.json `cardLines`; the map area is `cardMap`). With an `open` listener the card is a
// button and the host opens the place; without one it is a link to the web map of the tenant's provider
// (spec/location-vectors.json `web`). A card without a valid coordinate opens nothing.
const props = withDefaults(
  defineProps<{
    /** WGS-84 latitude, -90..90. */
    latitude?: number;
    /** WGS-84 longitude, -180..180. */
    longitude?: number;
    title: string;
    address?: string;
    /** Signed static map from the host (the geo proxy); without it, or when it fails, the drawn map shows. */
    snapshotUrl?: string;
    /** The tenant's map service: which web map the default link opens. */
    provider?: FlareLocationProvider;
  }>(),
  { latitude: Number.NaN, longitude: Number.NaN, address: "", snapshotUrl: "", provider: "osm" },
);
const emit = defineEmits<{ (e: "open"): void }>();

const { t } = useFlareI18nOptional();
const instance = getCurrentInstance();
const hostOpens = computed(() => Boolean(instance?.vnode.props?.onOpen));
const links = computed(() => flareLocationMapLinks({
  latitude: props.latitude,
  longitude: props.longitude,
  title: props.title,
  provider: props.provider,
}));
// Never a blank line: without a title the address moves up, the coordinate stands in for what is missing, and
// without any of them the card reads 「位置」.
const lines = computed(() => flareLocationCardLines(props, t("location.place")));
const label = computed(() => [lines.value.primary, lines.value.secondary].filter(Boolean).join(", "));
const cardStyle = { width: `${FLARE_LOCATION_CARD_MAP.width}px` };
const mapStyle = { height: `${FLARE_LOCATION_CARD_MAP.height}px` };
const tag = computed(() => (hostOpens.value ? "button" : links.value ? "a" : "div"));
// OpenStreetMap's licence (ODbL) asks for its credit wherever its map shows; AMap's static map carries its own.
const attribution = computed(() => (props.provider === "osm" ? t("location.osmAttribution") : undefined));
</script>

<template>
  <component
    :is="tag"
    class="fm-loc"
    :class="{ 'is-interactive': tag !== 'div' }"
    :style="cardStyle"
    :type="tag === 'button' ? 'button' : undefined"
    :href="tag === 'a' ? links?.web : undefined"
    :target="tag === 'a' ? '_blank' : undefined"
    :rel="tag === 'a' ? 'noopener noreferrer' : undefined"
    :role="tag === 'div' ? 'group' : undefined"
    :aria-label="label"
    :title="tag === 'div' ? undefined : t('location.openInMaps')"
    @click="hostOpens && emit('open')"
  >
    <LocationMapSurface class="fm-loc__map" :style="mapStyle" :src="snapshotUrl || undefined" :attribution="attribution" />
    <span class="fm-loc__meta">
      <b class="fm-loc__title">{{ lines.primary }}</b>
      <small v-if="lines.secondary" class="fm-loc__address">{{ lines.secondary }}</small>
    </span>
  </component>
</template>

<style scoped>
.fm-loc {
  display: flex;
  flex-direction: column;
  max-width: 100%;
  padding: 0;
  overflow: hidden;
  text-align: start;
  text-decoration: none;
  color: inherit;
  font: inherit;
  border-radius: var(--flare-size-radius-bubble) var(--flare-size-radius-bubble) var(--flare-size-radius-bubble) var(--flare-size-radius-bubble-tail);
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-secondary);
  box-shadow: var(--flare-component-bubble-shadow);
}
.fm-loc.is-interactive { cursor: pointer; }
.fm-loc.is-interactive:hover { border-color: var(--flare-color-border-hover); }
.fm-loc.is-interactive:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.fm-loc__map { flex: none; }
.fm-loc__meta {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-3xs);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  min-width: 0;
}
.fm-loc__title,
.fm-loc__address {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.fm-loc__title { font-size: var(--flare-size-font-size-lg); font-weight: var(--flare-size-font-weight-medium); color: var(--flare-color-text-primary); }
.fm-loc__address { font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-tertiary); }
</style>
