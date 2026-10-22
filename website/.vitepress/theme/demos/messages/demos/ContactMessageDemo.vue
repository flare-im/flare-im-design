<script setup>
import { ref } from "vue";
import { FlareContactMessage as C } from "@flare-im/vue-ui/components";
// 监听 open 时名片可点，回传 userId，宿主进入资料页。
const opened = ref("");
</script>
<template>
  <C name="Ivy Chen" subtitle="@ivy_chen · 产品经理" user-id="u_ivy" @open="(id) => (opened = id)" />
  <p v-if="opened" class="note">打开资料页：{{ opened }}</p>
</template>
<style scoped>
.note { margin: 8px 0 0; font-size: 13px; color: var(--flare-color-text-secondary); }
</style>
