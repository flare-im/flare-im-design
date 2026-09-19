<script setup>
// Outlined icon set for the docs demos — mirrors the four-platform icon
// vocabulary landed in D-4 (outlined-first, thin, no filled chrome).
// Kept as inline SVG so the demos have zero runtime dependency.
const S = {
  search: '<circle cx="11" cy="11" r="7"/><path d="M16.5 16.5 21 21"/>',
  close: '<path d="M6 6l12 12M18 6L6 18"/>',
  cancel: '<circle cx="12" cy="12" r="9"/><path d="M9.5 9.5l5 5M14.5 9.5l-5 5"/>',
  check: '<path d="M5 12.5l4.5 4.5L19 7"/>',
  checkDouble: '<path d="M2 12.5l4 4L14 8"/><path d="M11 15l1.8 1.8L21 8"/>',
  error: '<circle cx="12" cy="12" r="9"/><path d="M12 7.5v5.5"/><path d="M12 16.4v.2"/>',
  sync: '<path d="M4 12a8 8 0 0 1 13.7-5.7L20 8"/><path d="M20 4v4.5h-4.5"/><path d="M20 12a8 8 0 0 1-13.7 5.7L4 16"/><path d="M4 20v-4.5h4.5"/>',
  send: '<path d="M4.5 19.5 21 12 4.5 4.5v6l8.5 1.5-8.5 1.5z"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  emoji: '<circle cx="12" cy="12" r="9"/><path d="M8.5 14a4.5 4.5 0 0 0 7 0"/><path d="M9 9.5v.2M15 9.5v.2"/>',
  keyboard:
    '<rect x="2.5" y="6" width="19" height="12" rx="2.5"/><path d="M6.5 9.5v.2M10 9.5v.2M13.5 9.5v.2M17 9.5v.2M6.5 12.8v.2M10 12.8v.2M13.5 12.8v.2M17 12.8v.2M8.5 15.8h7"/>',
  mic: '<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5.5 11.5a6.5 6.5 0 0 0 13 0"/><path d="M12 18v3"/>',
  micOff:
    '<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5.5 11.5a6.5 6.5 0 0 0 13 0"/><path d="M12 18v3"/><path d="M4 4l16 16"/>',
  video: '<rect x="3" y="6" width="12.5" height="12" rx="2.5"/><path d="M15.5 10.5 21 7.5v9l-5.5-3z"/>',
  videoOff:
    '<rect x="3" y="6" width="12.5" height="12" rx="2.5"/><path d="M15.5 10.5 21 7.5v9l-5.5-3z"/><path d="M4 4l16 16"/>',
  call: '<path d="M6.6 10.8a15 15 0 0 0 6.6 6.6l2.2-2.2a1 1 0 0 1 1-.25 11 11 0 0 0 3.4.55 1 1 0 0 1 1 1V20a1 1 0 0 1-1 1A17 17 0 0 1 3 4a1 1 0 0 1 1-1h3.5a1 1 0 0 1 1 1 11 11 0 0 0 .55 3.4 1 1 0 0 1-.25 1z"/>',
  callEnd:
    '<g transform="rotate(135 12 12)"><path d="M6.6 10.8a15 15 0 0 0 6.6 6.6l2.2-2.2a1 1 0 0 1 1-.25 11 11 0 0 0 3.4.55 1 1 0 0 1 1 1V20a1 1 0 0 1-1 1A17 17 0 0 1 3 4a1 1 0 0 1 1-1h3.5a1 1 0 0 1 1 1 11 11 0 0 0 .55 3.4 1 1 0 0 1-.25 1z"/></g>',
  volume: '<path d="M4 9.5h3.5L12 5.5v13L7.5 14.5H4z"/><path d="M16 9a4.5 4.5 0 0 1 0 6"/>',
  moreHoriz: '<path d="M5.2 12h.2M11.9 12h.2M18.6 12h.2"/>',
  image:
    '<rect x="3" y="4.5" width="18" height="15" rx="2.5"/><circle cx="8.7" cy="9.5" r="1.4"/><path d="M4 16.5l4.8-4.5 3.7 3.4 2.4-2.2L20 17.5"/>',
  camera:
    '<rect x="3" y="7" width="18" height="13" rx="2.5"/><circle cx="12" cy="13.5" r="3.4"/><path d="M9 7l1.3-2.5h3.4L15 7"/>',
  folder: '<path d="M3 7.5a2 2 0 0 1 2-2h3.8l2 2H19a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>',
  location: '<path d="M12 21s6.8-5.8 6.8-11a6.8 6.8 0 1 0-13.6 0C5.2 15.2 12 21 12 21z"/><circle cx="12" cy="10" r="2.5"/>',
  person: '<circle cx="12" cy="8" r="3.6"/><path d="M5 20a7 7 0 0 1 14 0"/>',
  personAdd: '<circle cx="9.5" cy="8" r="3.4"/><path d="M3 20a6.5 6.5 0 0 1 13 0"/><path d="M19 6.5v6M16 9.5h6"/>',
  poll: '<path d="M6 20V10.5M12 20V4M18 20v-6.5"/>',
  task: '<rect x="4" y="4" width="16" height="16" rx="3.5"/><path d="M8.2 12.2l2.6 2.6 5-5.6"/>',
  calendar: '<rect x="3" y="5.5" width="18" height="15" rx="2.5"/><path d="M8 3v4.5M16 3v4.5M3 10.5h18"/>',
  star: '<path d="M12 3.6l2.6 5.4 5.9.9-4.3 4.1 1 5.9-5.2-2.8-5.2 2.8 1-5.9L3.5 9.9l5.9-.9z"/>',
  collections: '<rect x="7.5" y="3" width="13.5" height="13.5" rx="2.5"/><path d="M3 7.5V19a2 2 0 0 0 2 2h11.5"/>',
  settings: '<path d="M4 7.5h9M17.5 7.5H20M4 16.5h5.5M14 16.5H20"/><circle cx="15" cy="7.5" r="2.2"/><circle cx="11.8" cy="16.5" r="2.2"/>',
  qr: '<rect x="3.5" y="3.5" width="6.5" height="6.5" rx="1"/><rect x="14" y="3.5" width="6.5" height="6.5" rx="1"/><rect x="3.5" y="14" width="6.5" height="6.5" rx="1"/><path d="M14 14h3v3h-3zM20.5 14v3M14 20.5h6.5"/>',
  chevronRight: '<path d="M9.5 5.5 16 12l-6.5 6.5"/>',
  chevronLeft: '<path d="M14.5 5.5 8 12l6.5 6.5"/>',
  arrowLeft: '<path d="M20 12H4.5"/><path d="M11 5.5 4.5 12 11 18.5"/>',
  pin: '<path d="M9.2 3.5h5.6l-.9 5.6 3 3.4H7.1l3-3.4z"/><path d="M12 12.5V21"/>',
  bellOff: '<path d="M18 16.5v-5.2a6 6 0 0 0-12 0v5.2l-2 2h16z"/><path d="M9.8 20.5a2.4 2.4 0 0 0 4.4 0"/><path d="M4 4l16 16"/>',
  inbox: '<rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="M3 13.5h4.8l1.5 2.4h5.4l1.5-2.4H21"/>',
  download: '<path d="M12 4v10.5"/><path d="M8 11l4 4 4-4"/><path d="M5 20h14"/>',
  play: '<circle cx="12" cy="12" r="9"/><path d="M10.2 8.4 16 12l-5.8 3.6z"/>',
  trash: '<path d="M4.5 7h15"/><path d="M9.5 7V4.8h5V7"/><path d="M6.5 7l.9 13h9.2l.9-13"/>',
  edit: '<path d="M4 20h4L19 9l-4-4L4 16z"/><path d="M14.5 5.5 18.5 9.5"/>',
  message: '<path d="M4.5 5.5h15v10.5H9.5L4.5 20z"/>',
  reply: '<path d="M9.5 8 5 12l4.5 4"/><path d="M5 12h8.5a5.5 5.5 0 0 1 5.5 5.5V19"/>',
  forward: '<path d="M14.5 8 19 12l-4.5 4"/><path d="M19 12h-8.5A5.5 5.5 0 0 0 5 17.5V19"/>',
  undo: '<path d="M4 8h10.5a5.5 5.5 0 0 1 0 11H8.5"/><path d="M7.5 4.5 4 8l3.5 3.5"/>',
  flag: '<path d="M6 21V4"/><path d="M6 4.5h11l-2.4 4 2.4 4H6"/>',
  checklist: '<path d="M4 7l1.4 1.4L8 5.8"/><path d="M4 17l1.4 1.4L8 15.8"/><path d="M11 7h9M11 17h9"/>',
  copy: '<rect x="9" y="9" width="11" height="11" rx="2.2"/><path d="M5 15V5.2A2.2 2.2 0 0 1 7.2 3H15"/>',
  pinTop: '<path d="M5 4h14"/><path d="M12 8.5V20"/><path d="M8 12l4-4 4 4"/>',
  users: '<circle cx="9.5" cy="8.5" r="3.2"/><path d="M3.5 19.5a6 6 0 0 1 12 0"/><path d="M16 6.2a3.2 3.2 0 0 1 0 5.9M17.5 14.6a5.5 5.5 0 0 1 3.5 4.9"/>',
  bold: '<path d="M7.5 4.5h5.8a3.7 3.7 0 0 1 0 7.4H7.5z"/><path d="M7.5 11.9h6.6a3.8 3.8 0 0 1 0 7.6H7.5z"/>',
  italic: '<path d="M15.5 4.5h-5M13.5 19.5h-5M14 4.5 10 19.5"/>',
  strike: '<path d="M4.5 12h15"/><path d="M8 8.2A3.5 3.5 0 0 1 11.5 5h1a3.5 3.5 0 0 1 3.4 2.6"/><path d="M16 15.5A3.5 3.5 0 0 1 12.5 19h-1A3.5 3.5 0 0 1 8 16.4"/>',
  code: '<path d="M9 7.5 4.5 12 9 16.5M15 7.5 19.5 12 15 16.5"/>',
  link: '<path d="M10 13.8a3.5 3.5 0 0 0 5 0l2.5-2.6a3.6 3.6 0 0 0-5.1-5.1L11 7.5"/><path d="M14 10.2a3.5 3.5 0 0 0-5 0l-2.5 2.6a3.6 3.6 0 0 0 5.1 5.1L13 16.5"/>',
  list: '<path d="M9 6.5h11M9 12h11M9 17.5h11"/><path d="M4.6 6.5h.2M4.6 12h.2M4.6 17.5h.2"/>',
  zoomIn: '<circle cx="11" cy="11" r="7"/><path d="M16.5 16.5 21 21"/><path d="M11 8.2v5.6M8.2 11h5.6"/>',
  zoomOut: '<circle cx="11" cy="11" r="7"/><path d="M16.5 16.5 21 21"/><path d="M8.2 11h5.6"/>',
};

defineProps({
  name: { type: String, required: true },
  size: { type: [Number, String], default: 20 },
});
</script>

<template>
  <svg
    class="dico"
    :width="size"
    :height="size"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="1.6"
    stroke-linecap="round"
    stroke-linejoin="round"
    aria-hidden="true"
    v-html="S[name]"
  />
</template>

<style scoped>
.dico {
  display: block;
  flex: none;
}
</style>
