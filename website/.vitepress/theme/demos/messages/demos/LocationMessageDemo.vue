<script setup>
import { ref } from "vue";
import { FlareLocationMessage as C } from "@flare-im/vue-ui/components";
// 不监听 open 时卡片按服务商链接到网页地图（OpenStreetMap / 高德）；监听后由宿主打开。
const opened = ref("");
</script>
<template>
  <div class="row">
    <C :latitude="39.9349" :longitude="116.4551" title="三里屯太古里" address="北京市朝阳区三里屯路 19 号" />
    <C :latitude="31.2304" :longitude="121.4737" title="人民广场" provider="amap" @open="opened = '人民广场'" />
  </div>
  <p v-if="opened" class="note">宿主打开：{{ opened }}</p>
</template>
<style scoped>
.row { display: flex; flex-wrap: wrap; gap: 12px; }
.note { margin: 8px 0 0; font-size: 13px; color: var(--flare-color-text-secondary); }
</style>
