<script setup>
import { computed, ref } from "vue";
import { FlareLocationPicker, FlareSegmentedControl } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// 宿主回调用定时器模拟地图代理：定位、逆地址、周边与搜索、静态图。切换场景看「无权限」「地图不可用」。
const scenario = ref(0);
const sent = ref("");
const wait = (ms, value) => new Promise((resolve) => setTimeout(() => resolve(value), ms));
const places = [
  { id: "p1", title: "三里屯太古里南区", address: "三里屯路 19 号", latitude: 39.9336, longitude: 116.4544, distanceM: 160 },
  { id: "p2", title: "工人体育场", address: "工人体育场北路", latitude: 39.9302, longitude: 116.4473, distanceM: 820 },
  { id: "p3", title: "朝阳公园", address: "朝阳公园南路 1 号", latitude: 39.9405, longitude: 116.4795, distanceM: 2380 },
];
// 示意用的静态图：浅色街区和两条主路，中心点由地图代理绘制。
const snapshot = `data:image/svg+xml;utf8,${encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" width="720" height="336" viewBox="0 0 720 336"><rect width="720" height="336" fill="#eef1ec"/><g fill="#e2e7df"><rect x="30" y="24" width="180" height="110" rx="6"/><rect x="250" y="24" width="200" height="110" rx="6"/><rect x="490" y="24" width="200" height="110" rx="6"/><rect x="30" y="200" width="180" height="110" rx="6"/><rect x="250" y="200" width="200" height="110" rx="6"/><rect x="490" y="200" width="200" height="110" rx="6"/></g><path d="M0 168H720M360 0V336" stroke="#ffffff" stroke-width="22"/><path d="M0 300L720 40" stroke="#f6e7b8" stroke-width="12"/><circle cx="360" cy="168" r="11" fill="#7047d6" stroke="#fff" stroke-width="4"/></svg>`)}`;
const denied = computed(() => scenario.value === 1);
const mapDown = computed(() => scenario.value === 2);
const key = computed(() => scenario.value);
const requestCurrentLocation = () => (denied.value ? wait(400).then(() => { throw new Error("denied"); }) : wait(600, { latitude: 39.9349, longitude: 116.4551 }));
const reverseGeocode = () => wait(200, { title: "三里屯太古里", address: "北京市朝阳区三里屯路 19 号" });
const searchNearby = (lat, lng, query) => wait(250, query ? places.filter((p) => p.title.includes(query) || p.address.includes(query)) : places);
const previewUrl = () => wait(150, mapDown.value ? null : snapshot);
</script>
<template>
  <DemoStage>
    <FlareSegmentedControl v-model="scenario" class="switch" :options="['定位成功', '无权限', '地图不可用']" />
    <div class="frame">
      <FlareLocationPicker
        :key="key"
        :request-current-location="requestCurrentLocation"
        :reverse-geocode="reverseGeocode"
        :search-nearby="searchNearby"
        :preview-url="previewUrl"
        @send="(place) => (sent = place.title)"
        @cancel="sent = ''"
      />
    </div>
    <p v-if="sent" class="note">发送：{{ sent }}</p>
  </DemoStage>
</template>
<style scoped>
.switch { margin-bottom: 12px; }
.frame { max-width: 390px; height: 600px; overflow: hidden; border-radius: 14px; border: 1px solid var(--flare-color-border-secondary); }
.note { margin: 8px 0 0; font-size: 13px; color: var(--flare-color-text-secondary); }
</style>
