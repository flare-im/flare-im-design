<script setup>
import C from "flare-core-vue-im-ui/components/messages/standalone/FlareVoteMessage.vue";
const options = [{ text: "周四 15:00", pct: 62 }, { text: "周五 10:00", pct: 38 }];
</script>
<template>
  <C title="周会时间投票" :options="options" />
</template>
