<script setup>
import { computed, ref } from "vue";
import { FlareReauthSheet, FlareButton, FlareFilterTabs } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
const open = ref(false), mode = ref("ready"), selectedId = ref("email-demo"), code = ref(""), last = ref("");
const options = ["ready", "cooldown", "error", "busy"].map(value => ({ value, label: value }));
const destinations = [{ id: "email-demo", label: "a•••@example.test" }, { id: "phone-demo", label: "+86 •••• 1234" }];
const busy = computed(() => mode.value === "busy");
function cancel() { open.value = false; code.value = ""; last.value = "Cancelled"; }
function send() { mode.value = "cooldown"; last.value = `Requested code for ${selectedId.value}`; }
function submit() { open.value = false; code.value = ""; last.value = "Demo verification submitted"; }
</script>
<template>
  <DemoStage><div class="reauth-demo">
    <FlareFilterTabs v-model="mode" :options="options" />
    <FlareButton label="Open verification" @click="open = true" />
    <p role="status">{{ last }}</p>
    <FlareReauthSheet :open="open" title="Verify identity" subtitle="Choose a masked destination and enter the example code." :destinations="destinations" :selected-id="selectedId" :code="code" :sending="busy" :submitting="false" :can-send="mode !== 'cooldown' && !busy" :can-submit="code.length === 6 && !busy" :resend-in-seconds="mode === 'cooldown' ? 30 : 0" :error="mode === 'error' ? 'The example code was not accepted.' : undefined" @select-destination="id => selectedId = id" @change-code="value => code = value" @send="send" @submit="submit" @cancel="cancel" />
  </div></DemoStage>
</template>
<style scoped>.reauth-demo { width: 100%; display: grid; gap: var(--flare-size-spacing-md); }</style>
