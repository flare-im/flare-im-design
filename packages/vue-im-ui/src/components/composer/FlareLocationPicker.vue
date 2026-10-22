<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from "vue";
import FlareSearchBar from "../general/FlareSearchBar.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import FlareIcon from "../general/FlareIcon.vue";
import FlareSkeleton from "../general/FlareSkeleton.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import LocationMapSurface from "../messages/standalone/LocationMapSurface.vue";
import { flareIcons } from "../../shared/icons";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { useFlareSheetOwnHeader } from "../../shared/sheetHeader";
import {
  FLARE_LOCATION_CURRENT_ID,
  flareLocationCoordinateLabel,
  flareLocationDistanceLabel,
  flareLocationPreviewSize,
  isValidFlareLocation,
  type FlareLocationAddress,
  type FlareLocationCoordinate,
  type FlareLocationPlace,
  type FlareLocationProvider,
} from "../../shared/contracts/location";

// The content of the "send a location" sheet: a static map of the chosen place, a key that locates the
// device again, a search field and the places around, the first of them the current location. The host
// answers four questions through its callbacks (where am I, what is here, what is around, what does the
// map look like) and gets the chosen place in `send`; the kit owns the states in between. It paints at
// once: the last place the host remembers (`initialLocation`), or skeleton rows, until the device answers.
const props = withDefaults(
  defineProps<{
    /** The device position; rejecting (permission denied, no fix) turns the picker to manual search. */
    requestCurrentLocation: () => Promise<FlareLocationCoordinate>;
    /**
     * The host's permission step, awaited before each locate: the prompt's wait is not counted into
     * `locateTimeoutMs`. false (or a rejection) is denied at once, without asking for the position.
     */
    ensurePermission?: () => Promise<boolean>;
    /** The name and address of a coordinate, for the current-location row. */
    reverseGeocode?: (latitude: number, longitude: number) => Promise<FlareLocationAddress>;
    /**
     * Places around a centre: `query` "" is the nearby list, anything else a search. Latitude and longitude
     * are null when no position is known (denied without a previous place): the host searches without a centre.
     */
    searchNearby: (latitude: number | null, longitude: number | null, query: string) => Promise<FlareLocationPlace[]>;
    /**
     * A static map URL for the map area, in device pixels (logical size × screen scale clamped to 1..2, rounded);
     * null or a rejection draws "map unavailable".
     */
    previewUrl?: (latitude: number, longitude: number, zoom: number, width: number, height: number) => Promise<string | null> | string | null;
    /** The last place the host remembers: painted at once and used when locating times out. */
    initialLocation?: FlareLocationPlace;
    /** Map zoom for the preview. */
    zoom?: number;
    /**
     * How long to wait for the device before falling back to `initialLocation` (or manual search), counted from
     * when `ensurePermission` resolves true.
     */
    locateTimeoutMs?: number;
    /** The tenant's map service: OpenStreetMap's credit is drawn on its static map. */
    provider?: FlareLocationProvider;
    /** The host is sending the chosen place: Send spins and is disabled, so a second tap sends nothing. */
    sending?: boolean;
  }>(),
  { zoom: 16, locateTimeoutMs: 5000, provider: "osm", sending: false, ensurePermission: undefined },
);
const emit = defineEmits<{
  (e: "send", place: FlareLocationPlace): void;
  (e: "cancel"): void;
}>();

const { t } = useFlareI18n();
// The header row (Cancel, the title) is the picker's own: a kit sheet in fill mode draws no second title.
useFlareSheetOwnHeader();

type LocateState = "locating" | "located" | "denied";
type ListState = "idle" | "searching" | "ready" | "noResults";
type MapState = "loading" | "ready" | "unavailable";

const locateState = ref<LocateState>("locating");
/** The coordinate the device reported, or the remembered place standing in for it. */
const here = ref<FlareLocationCoordinate | null>(props.initialLocation ? pick(props.initialLocation) : null);
const hereAddress = ref<FlareLocationAddress | null>(
  props.initialLocation ? { title: props.initialLocation.title, address: props.initialLocation.address } : null,
);
const nearby = ref<FlareLocationPlace[]>([]);
const results = ref<FlareLocationPlace[]>([]);
const query = ref("");
// Skeleton rows from the first paint when there is nothing to show yet.
const listState = ref<ListState>(props.initialLocation ? "idle" : "searching");
const selectedId = ref<string>(FLARE_LOCATION_CURRENT_ID);
const mapState = ref<MapState>("loading");
const mapUrl = ref<string>("");
const mapEl = ref<HTMLElement | null>(null);
const search = ref<InstanceType<typeof FlareSearchBar> | null>(null);

let disposed = false;
let locateToken = 0;
let listToken = 0;
let mapToken = 0;

function pick(place: FlareLocationCoordinate): FlareLocationCoordinate {
  return { latitude: place.latitude, longitude: place.longitude };
}

const currentPlace = computed((): FlareLocationPlace | null => {
  if (!here.value) return null;
  const { latitude, longitude } = here.value;
  return {
    id: FLARE_LOCATION_CURRENT_ID,
    latitude,
    longitude,
    title: hereAddress.value?.title.trim() || t("location.current"),
    address: hereAddress.value?.address.trim() || flareLocationCoordinateLabel(latitude, longitude) || "",
  };
});
const searching = computed(() => query.value.trim().length > 0);
/** The rows: the current location first (not while searching), then the places around or the results. */
const rows = computed((): FlareLocationPlace[] => {
  if (searching.value) return results.value;
  const others = nearby.value.filter((place) => place.id !== FLARE_LOCATION_CURRENT_ID);
  return currentPlace.value ? [currentPlace.value, ...others] : others;
});
const selected = computed(() =>
  rows.value.find((place) => place.id === selectedId.value)
  ?? [currentPlace.value, ...nearby.value, ...results.value].find((place) => place?.id === selectedId.value)
  ?? null,
);
const canSend = computed(() => Boolean(selected.value && isValidFlareLocation(selected.value.latitude, selected.value.longitude)));
const mapCoordinate = computed(() => selected.value ?? currentPlace.value);
const coordinateLine = computed(() =>
  mapCoordinate.value ? flareLocationCoordinateLabel(mapCoordinate.value.latitude, mapCoordinate.value.longitude) : null,
);
/** One name for the picker's state, for hosts' tests and the data attribute. */
const state = computed(() => {
  if (locateState.value === "locating" && !here.value) return "locating";
  if (searching.value && listState.value === "searching") return "searching";
  if (searching.value && listState.value === "noResults") return "noResults";
  if (locateState.value === "denied") return "denied";
  if (mapState.value === "unavailable") return "mapUnavailable";
  return "located";
});

async function refreshMap(): Promise<void> {
  const place = mapCoordinate.value;
  const token = ++mapToken;
  if (!place || !props.previewUrl) {
    mapState.value = place ? "unavailable" : "loading";
    mapUrl.value = "";
    return;
  }
  mapState.value = "loading";
  const box = mapEl.value?.getBoundingClientRect();
  const { width, height } = flareLocationPreviewSize(
    box?.width || 360,
    box?.height || 168,
    typeof window === "undefined" ? 1 : window.devicePixelRatio || 1,
  );
  try {
    const url = await props.previewUrl(place.latitude, place.longitude, props.zoom, width, height);
    if (disposed || token !== mapToken) return;
    mapUrl.value = url ?? "";
    mapState.value = url ? "ready" : "unavailable";
  } catch {
    if (disposed || token !== mapToken) return;
    mapUrl.value = "";
    mapState.value = "unavailable";
  }
}

async function loadNearby(): Promise<void> {
  const token = ++listToken;
  const center = here.value;
  if (!searching.value) listState.value = nearby.value.length ? "ready" : "searching";
  try {
    const places = await props.searchNearby(center?.latitude ?? null, center?.longitude ?? null, "");
    if (disposed || token !== listToken || searching.value) return;
    nearby.value = places;
    listState.value = "ready";
  } catch {
    if (disposed || token !== listToken || searching.value) return;
    nearby.value = [];
    listState.value = "ready";
  }
}

async function runSearch(text: string): Promise<void> {
  const value = text.trim();
  const token = ++listToken;
  if (!value) {
    results.value = [];
    listState.value = "ready";
    if (!rows.value.some((place) => place.id === selectedId.value)) selectedId.value = FLARE_LOCATION_CURRENT_ID;
    void refreshMap();
    if (!nearby.value.length) void loadNearby();
    return;
  }
  listState.value = "searching";
  const center = selected.value ?? here.value;
  try {
    const places = await props.searchNearby(center?.latitude ?? null, center?.longitude ?? null, value);
    if (disposed || token !== listToken) return;
    results.value = places;
    listState.value = places.length ? "ready" : "noResults";
  } catch {
    if (disposed || token !== listToken) return;
    results.value = [];
    listState.value = "noResults";
  }
}

async function describeHere(): Promise<void> {
  const point = here.value;
  if (!point || !props.reverseGeocode) return;
  try {
    const address = await props.reverseGeocode(point.latitude, point.longitude);
    if (disposed || here.value !== point) return;
    hereAddress.value = address;
  } catch {
    /* the row keeps the coordinate as its address */
  }
}

function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T | "timeout"> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => resolve("timeout"), ms);
    promise.then(
      (value) => { clearTimeout(timer); resolve(value); },
      (error) => { clearTimeout(timer); reject(error); },
    );
  });
}

/** Nothing to centre on: the search field is the way in. */
function deny(): void {
  locateState.value = "denied";
  if (!here.value) {
    mapState.value = "unavailable";
    if (!searching.value) listState.value = "ready";
  }
}

/** Ask the device where it is. A late answer still lands while the person has not moved on. */
async function locate(): Promise<void> {
  const token = ++locateToken;
  locateState.value = "locating";
  // The system prompt's wait is the host's: the timeout starts once permission is there.
  if (props.ensurePermission) {
    let granted = false;
    try {
      granted = await props.ensurePermission();
    } catch {
      granted = false;
    }
    if (disposed || token !== locateToken) return;
    if (!granted) {
      deny();
      return;
    }
  }
  const request = Promise.resolve().then(() => props.requestCurrentLocation());
  try {
    const first = await withTimeout(request, props.locateTimeoutMs);
    if (disposed || token !== locateToken) return;
    if (first === "timeout") {
      locateState.value = here.value ? "located" : "denied";
      const late = await request;
      if (disposed || token !== locateToken) return;
      arrive(late);
      return;
    }
    arrive(first);
  } catch {
    if (disposed || token !== locateToken) return;
    deny();
  }
}

function arrive(point: FlareLocationCoordinate): void {
  if (!isValidFlareLocation(point.latitude, point.longitude)) {
    locateState.value = here.value ? "located" : "denied";
    return;
  }
  here.value = pick(point);
  hereAddress.value = null;
  locateState.value = "located";
  if (!searching.value) selectedId.value = FLARE_LOCATION_CURRENT_ID;
  void describeHere();
  void loadNearby();
  void refreshMap();
}

function choose(place: FlareLocationPlace): void {
  selectedId.value = place.id;
  void refreshMap();
}

function send(): void {
  if (props.sending) return;
  if (selected.value && canSend.value) emit("send", selected.value);
}

function locateAgain(): void {
  query.value = "";
  results.value = [];
  void locate();
}

onMounted(() => {
  if (here.value) {
    void refreshMap();
    void loadNearby();
  }
  void locate();
});
onBeforeUnmount(() => { disposed = true; });

const locateIcon = flareIcons.locate;
</script>

<template>
  <section
    class="flare-location-picker"
    :aria-label="t('location.title')"
    :data-state="state"
    :aria-busy="locateState === 'locating' || listState === 'searching'"
  >
    <header class="flare-location-picker__head">
      <button type="button" class="flare-location-picker__cancel" @click="emit('cancel')">{{ t("location.cancel") }}</button>
      <h2 class="flare-location-picker__title">{{ t("location.title") }}</h2>
      <span class="flare-location-picker__head-end" aria-hidden="true" />
    </header>

    <div ref="mapEl" class="flare-location-picker__map" role="img" :aria-label="[t('location.map'), mapCoordinate?.title].filter(Boolean).join(' · ')">
      <LocationMapSurface
        class="flare-location-picker__surface"
        :src="mapState !== 'unavailable' ? mapUrl || undefined : undefined"
        :loading="mapState === 'loading'"
        :attribution="provider === 'osm' ? t('location.osmAttribution') : undefined"
        @error="mapState = 'unavailable'"
      />
      <p v-if="mapState === 'unavailable' && mapCoordinate" class="flare-location-picker__map-note" data-map-unavailable="true">
        <span>{{ t("location.mapUnavailable") }}</span>
        <span v-if="coordinateLine" class="flare-location-picker__coordinate">{{ coordinateLine }}</span>
      </p>
      <FlareIconButton
        class="flare-location-picker__locate"
        :icon="locateIcon"
        :ariaLabel="t('location.locateMe')"
        variant="plain"
        background="var(--flare-color-bg-elevated)"
        :disabled="locateState === 'locating'"
        @click="locateAgain"
      />
    </div>

    <div class="flare-location-picker__search">
      <FlareSearchBar
        ref="search"
        v-model="query"
        :placeholder="t('location.searchPlaceholder')"
        :loading="listState === 'searching' && searching"
        @search="runSearch"
      />
    </div>

    <p v-if="locateState === 'denied'" class="flare-location-picker__notice" role="status">{{ t("location.denied") }}</p>

    <div class="flare-location-picker__list" role="radiogroup" :aria-label="t('location.places')">
      <p v-if="locateState === 'locating' && !here" class="flare-location-picker__status" role="status">
        <FlareIcon name="locate" :size="16" />{{ t("location.locating") }}
      </p>
      <FlareSkeleton v-if="listState === 'searching' && !rows.length" variant="text" :rows="4" class="flare-location-picker__skeleton" />
      <FlareEmptyState v-else-if="listState === 'noResults'" :title="t('location.noResults')" icon="location" />
      <template v-else>
        <button
          v-for="place in rows"
          :key="place.id"
          type="button"
          role="radio"
          class="flare-location-picker__row"
          :class="{ 'is-selected': place.id === selectedId, 'is-current': place.id === 'current' }"
          :aria-checked="place.id === selectedId"
          :data-place-id="place.id"
          @click="choose(place)"
        >
          <span class="flare-location-picker__row-icon" aria-hidden="true">
            <FlareIcon :name="place.id === 'current' ? 'locate' : 'location'" :size="16" />
          </span>
          <span class="flare-location-picker__row-body">
            <span class="flare-location-picker__row-title">{{ place.title }}</span>
            <span v-if="place.address" class="flare-location-picker__row-address">{{ place.address }}</span>
          </span>
          <span v-if="flareLocationDistanceLabel(place.distanceM)" class="flare-location-picker__row-distance">
            {{ flareLocationDistanceLabel(place.distanceM) }}
          </span>
          <span class="flare-location-picker__row-check" aria-hidden="true">
            <FlareIcon v-if="place.id === selectedId" name="check" :size="16" />
          </span>
        </button>
      </template>
    </div>

    <footer class="flare-location-picker__foot">
      <FlareButton block :label="t('location.send')" :loading="sending" :disabled="!canSend || sending" data-location-send="true" @click="send" />
    </footer>
  </section>
</template>

<style scoped>
.flare-location-picker {
  display: flex;
  flex-direction: column;
  width: 100%;
  height: 100%;
  min-height: 0;
  max-height: 100%;
  background: var(--flare-color-bg-primary);
  color: var(--flare-color-text-primary);
}
.flare-location-picker__head {
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  align-items: center;
  min-height: var(--flare-size-layout-control-height-lg);
  padding: 0 var(--flare-size-spacing-md);
  flex: none;
}
.flare-location-picker__cancel {
  justify-self: start;
  min-height: var(--flare-size-layout-touch-target-min);
  padding: 0 var(--flare-size-spacing-xs);
  border: 0;
  background: transparent;
  color: var(--flare-color-text-secondary);
  font: inherit;
  font-size: var(--flare-size-font-size-xl);
  cursor: pointer;
}
.flare-location-picker__cancel:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; border-radius: var(--flare-size-radius-sm); }
.flare-location-picker__title {
  margin: 0;
  font-size: var(--flare-size-font-size-2xl);
  font-weight: var(--flare-size-font-weight-bold);
}
.flare-location-picker__map {
  position: relative;
  flex: none;
  height: 168px;
}
.flare-location-picker__surface { position: absolute; inset: 0; }
.flare-location-picker__map-note {
  position: absolute;
  left: var(--flare-size-spacing-md);
  bottom: var(--flare-size-spacing-md);
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-3xs);
  max-width: calc(100% - 96px);
  margin: 0;
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-sm);
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-elevated);
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-sm);
  box-shadow: var(--flare-shadow-sm);
}
.flare-location-picker__coordinate { color: var(--flare-color-text-tertiary); font-variant-numeric: tabular-nums; }
.flare-location-picker__locate {
  position: absolute;
  right: var(--flare-size-spacing-md);
  bottom: var(--flare-size-spacing-md);
  box-shadow: var(--flare-shadow-md);
}
.flare-location-picker__search { padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md) var(--flare-size-spacing-xs); flex: none; }
.flare-location-picker__notice {
  margin: 0 var(--flare-size-spacing-md) var(--flare-size-spacing-xs);
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-md);
}
.flare-location-picker__list {
  flex: 1 1 auto;
  min-height: 120px;
  overflow-y: auto;
  overscroll-behavior: contain;
}
.flare-location-picker__status {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
  margin: 0;
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg);
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-md);
}
.flare-location-picker__skeleton { padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg); }
.flare-location-picker__row {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-md);
  width: 100%;
  min-height: 56px;
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg);
  border: 0;
  border-bottom: 1px solid var(--flare-color-border-secondary);
  background: transparent;
  color: inherit;
  font: inherit;
  text-align: start;
  cursor: pointer;
}
.flare-location-picker__row:hover { background: var(--flare-color-bg-hover); }
.flare-location-picker__row:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
.flare-location-picker__row-icon { flex: none; display: inline-flex; color: var(--flare-color-text-tertiary); }
.flare-location-picker__row.is-current .flare-location-picker__row-icon { color: var(--flare-color-primary-text); }
.flare-location-picker__row-body { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: var(--flare-size-spacing-3xs); }
.flare-location-picker__row-title,
.flare-location-picker__row-address { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.flare-location-picker__row-title { font-size: var(--flare-size-font-size-xl); color: var(--flare-color-text-primary); }
.flare-location-picker__row-address { font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-tertiary); }
.flare-location-picker__row-distance { flex: none; font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-tertiary); font-variant-numeric: tabular-nums; }
.flare-location-picker__row-check { flex: none; display: inline-flex; width: var(--flare-size-icon-size-sm); color: var(--flare-color-primary-text); }
.flare-location-picker__row.is-selected .flare-location-picker__row-title { color: var(--flare-color-primary-text); font-weight: var(--flare-size-font-weight-medium); }
.flare-location-picker__foot {
  flex: none;
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md) calc(var(--flare-size-spacing-sm) + env(safe-area-inset-bottom, 0px));
  border-top: 1px solid var(--flare-color-border-secondary);
}
</style>
