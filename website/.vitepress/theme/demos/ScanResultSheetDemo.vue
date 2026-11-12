<script setup>
import { ref } from "vue";
import { FlareScanResultSheet, FlareButton, FlareFilterTabs } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
const open = ref(false), phase = ref("ready"), last = ref("");
const options = ["ready", "acting", "pending", "offlineWaiting", "unknown"].map(value => ({ value, label: value }));
const actions = [{ id: "add", label: "Add friend", primary: true, inputs: [{ id: "remark", kind: "text", label: "Message", maxLen: 80 }] }];
</script>
<template><DemoStage><div class="scan-result-demo"><FlareFilterTabs v-model="phase" :options="options" /><FlareButton label="Open scan result" @click="open = true" /><p role="status">{{ last }}</p><FlareScanResultSheet :open="open" :phase="phase" :busy="phase === 'acting'" :header="{ title: 'Ivy Chen', subtitle: 'Personal code' }" :facts="[{ label: 'Source', value: 'QR code' }]" :actions="actions" @action="(id, values) => { last = `${id}: ${values.remark || ''}`; open = false; }" @dismiss="open = false" @retry="phase = 'ready'" /></div></DemoStage></template>
<style scoped>.scan-result-demo { width: 100%; display: grid; gap: var(--flare-size-spacing-md); }</style>
