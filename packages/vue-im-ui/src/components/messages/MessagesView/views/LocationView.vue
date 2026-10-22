<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { readNumber, readString } from "../../../../utils/contentData";
import { useFlareI18n } from "../../../../shared/i18n/useFlareI18n";
import {
  flareLocationProviderFrom,
  type FlareLocationProvider,
  type FlareLocationValue,
} from "../../../../shared/contracts/location";
import FlareLocationMessage from "../../standalone/FlareLocationMessage.vue";

// Timeline adapter: location payload → the card. A host that listens to `locationOpen` opens the place
// itself (the tenant's provider, an in-app map); otherwise the card links to the web map of the
// payload's provider, OpenStreetMap when it names none.
const props = defineProps<{ content: ContentElem; isSelf: boolean }>();
const emit = defineEmits<{ (event: "locationOpen", location: FlareLocationValue): void }>();
const { t } = useFlareI18n();
const instance = getCurrentInstance();

const payload = computed(() => {
  const nested = pickNestedPayload(props.content, "location");
  return Object.keys(nested).length ? nested : (props.content as Record<string, unknown>);
});

// The wire writes an absent coordinate as 0, 0: that pair is "no coordinate" here, not a place to open.
const rawLatitude = computed(() => readNumber(payload.value, Number.NaN, "latitude", "lat"));
const rawLongitude = computed(() => readNumber(payload.value, Number.NaN, "longitude", "lng"));
const unset = computed(() => rawLatitude.value === 0 && rawLongitude.value === 0);
const latitude = computed(() => (unset.value ? Number.NaN : rawLatitude.value));
const longitude = computed(() => (unset.value ? Number.NaN : rawLongitude.value));
const address = computed(() => readString(payload.value, "address", "subtitle"));
const title = computed(() => readString(payload.value, "title", "name") || address.value || t("composer.location"));
const snapshotUrl = computed(() => readString(payload.value, "snapshotUrl", "snapshot_url"));
const provider = computed((): FlareLocationProvider => flareLocationProviderFrom(payload.value.provider));

const location = computed((): FlareLocationValue => ({
  latitude: latitude.value,
  longitude: longitude.value,
  title: title.value,
  address: address.value,
  ...(snapshotUrl.value ? { snapshotUrl: snapshotUrl.value } : {}),
  provider: provider.value,
}));
const listeners = computed(() =>
  instance?.vnode.props?.onLocationOpen ? { open: () => emit("locationOpen", location.value) } : {},
);
</script>

<template>
  <FlareLocationMessage
    :latitude="latitude"
    :longitude="longitude"
    :title="title"
    :address="address === title ? '' : address"
    :snapshot-url="snapshotUrl"
    :provider="provider"
    v-on="listeners"
  />
</template>
