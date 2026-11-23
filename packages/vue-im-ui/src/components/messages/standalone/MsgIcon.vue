<script setup lang="ts">
import { computed } from "vue";
import FlareIcon from "../../general/FlareIcon.vue";
import type { FlareIconName } from "../../../shared/icons";
// Internal message aliases share the kit glyphs, size tokens and stroke weight.
const names: Record<string, FlareIconName> = {
  folder: "folder", file: "file", download: "download", error: "error", location: "location", link: "link",
  poll: "poll", check: "check", pause: "pause", volume: "speaker", video: "video", play: "play", image: "image", chevronRight: "chevron-right",
};
const props = withDefaults(defineProps<{ name: string; size?: "sm" | "md" | "lg" | "xl" | number }>(), { size: "md" });
const glyph = computed(() => names[props.name] ?? "file");
</script>
<template><FlareIcon :name="glyph" :size="size" /></template>
