<script setup>
import { ref } from "vue";
import { FlareScanDropZone } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
const last = ref("");
</script>
<template><DemoStage><div><FlareScanDropZone paste-available @pick-image="last = 'pick image'" @paste="last = 'paste'" @drop="files => last = files.map(file => file.name).join(', ')" /><p role="status">{{ last }}</p></div></DemoStage></template>
