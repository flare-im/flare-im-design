<script setup lang="ts">
// Minimal inline-SVG icon for the standalone message components, so they carry
// no icon-library dependency. Outlined, matching the kit's icon language.
const S: Record<string, string> = {
  folder: '<path d="M3 7.5a2 2 0 0 1 2-2h3.8l2 2H19a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>',
  download: '<path d="M12 4v10.5"/><path d="M8 11l4 4 4-4"/><path d="M5 20h14"/>',
  location: '<path d="M12 21s6.8-5.8 6.8-11a6.8 6.8 0 1 0-13.6 0C5.2 15.2 12 21 12 21z"/><circle cx="12" cy="10" r="2.5"/>',
  link: '<path d="M10 13.8a3.5 3.5 0 0 0 5 0l2.5-2.6a3.6 3.6 0 0 0-5.1-5.1L11 7.5"/><path d="M14 10.2a3.5 3.5 0 0 0-5 0l-2.5 2.6a3.6 3.6 0 0 0 5.1 5.1L13 16.5"/>',
  poll: '<path d="M6 20V10.5M12 20V4M18 20v-6.5"/>',
  check: '<path d="M5 12.5l4.5 4.5L19 7"/>',
  volume: '<path d="M4 9.5h3.5L12 5.5v13L7.5 14.5H4z"/><path d="M16 9a4.5 4.5 0 0 1 0 6"/>',
  video: '<rect x="3" y="6" width="12.5" height="12" rx="2.5"/><path d="M15.5 10.5 21 7.5v9l-5.5-3z"/>',
  play: '<circle cx="12" cy="12" r="9"/><path d="M10.2 8.4 16 12l-5.8 3.6z"/>',
  image: '<rect x="3" y="4.5" width="18" height="15" rx="2.5"/><circle cx="8.7" cy="9.5" r="1.4"/><path d="M4 16.5l4.8-4.5 3.7 3.4 2.4-2.2L20 17.5"/>',
  chevronRight: '<path d="M9.5 5.5 16 12l-6.5 6.5"/>',
};
defineProps<{ name: string; size?: number }>();
</script>
<template>
  <svg
    :width="size ?? 20" :height="size ?? 20" viewBox="0 0 24 24" fill="none"
    stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"
    aria-hidden="true" style="display:block;flex:none" v-html="S[name]"
  />
</template>
