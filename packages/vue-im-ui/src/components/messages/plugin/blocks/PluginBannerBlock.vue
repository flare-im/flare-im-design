<script setup lang="ts">
import FlareStatusBanner from "../../../general/FlareStatusBanner.vue";
import {
  flarePluginBannerTone,
  type FlarePluginAction,
  type FlarePluginBannerBlock,
} from "../../../../shared/contracts/plugin-ui";

// A prominent notice (vocabulary 2) as the kit StatusBanner: its tone, its text and, while the viewer may run it,
// the action it owns (it goes through PluginView's confirm / form / host pipeline like any other action).
const props = defineProps<{ block: FlarePluginBannerBlock; busy?: boolean }>();
const emit = defineEmits<{ action: [action: FlarePluginAction] }>();
function run(): void {
  if (props.block.action && !props.busy) emit("action", props.block.action);
}
</script>

<template>
  <FlareStatusBanner
    class="flare-plugin-banner"
    :text="block.text"
    :tone="flarePluginBannerTone(block.tone)"
    :action-text="block.action?.label"
    :data-banner-tone="flarePluginBannerTone(block.tone)"
    :aria-disabled="busy || undefined"
    @action="run"
  />
</template>
