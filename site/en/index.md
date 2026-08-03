---
layout: home
hero:
  name: Flare IM Design
  text: Cross-platform IM UI kit
  tagline: A standalone, cross-platform IM UI kit — Vue · Flutter · iOS · Android. Pure presentational components — props in, events out, drop onto any IM backend. Optionally wire Flare core for batteries-included send & multi-device sync.
  actions:
    - theme: brand
      text: Get started
      link: /en/guide/getting-started
    - theme: alt
      text: Browse components
      link: /en/components/
    - theme: alt
      text: Design tokens
      link: /en/guide/tokens
features:
  - icon: '<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3 3 7.5l9 4.5 9-4.5z"/><path d="M3 12l9 4.5 9-4.5"/><path d="M3 16.5 12 21l9-4.5"/></svg>'
    title: 107 components · 11 categories
    details: General / Conversation / Message / Composer / Media / Contacts / Profile / Call / Layout. One framework-neutral contract per component, natively implemented on Vue, Flutter, iOS and Android — same name, same semantics.
  - icon: '<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="1.6"><circle cx="9" cy="9.8" r="4.6"/><circle cx="15" cy="9.8" r="4.6"/><circle cx="12" cy="15" r="4.6"/></svg>'
    title: One set of design tokens
    details: A neutral tokens.json single source generates Web CSS/TS, Dart, Swift and Kotlin — identical color, spacing, type and radius across platforms, light + dark, re-themeable at runtime.
  - icon: '<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"><rect x="6" y="6" width="12" height="12" rx="2.5"/><rect x="9.8" y="9.8" width="4.4" height="4.4" rx="1"/><path d="M9.5 6V3M14.5 6V3M9.5 21v-3M14.5 21v-3M6 9.5H3M6 14.5H3M21 9.5h-3M21 14.5h-3"/></svg>'
    title: Standalone · any backend
    details: Components are pure presentation — pass data via props, get interactions back as events, with no SDK lock-in, so they drop straight onto your existing IM backend. Want batteries included? Optionally wire the Flare core for reliable send, multi-device sync and optimistic UI.
  - icon: '<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M13 2.5 4.8 13.4H11l-.9 8.1 9.1-11.2H13z"/></svg>'
    title: Performance & smoothness first
    details: Optimistic UI paints next frame (< 16 ms), lists virtualise O(visible), media stays off the main thread, caches evict with bounds — budgets are the design.
  - icon: '<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"><rect x="4" y="4" width="7" height="7" rx="1.4"/><rect x="13" y="4" width="7" height="7" rx="1.4"/><rect x="4" y="13" width="7" height="7" rx="1.4"/><rect x="13" y="13" width="7" height="7" rx="1.4" stroke-dasharray="2.6 2.6"/></svg>'
    title: Complete, extensible message types
    details: Text/image/video/file/location/card/link/vote/task/sticker… 17 built-in message bodies, each its own component; compose custom types too — covering the full mainstream-IM surface — conversations, chat, composer, media, calls.
  - icon: '<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M6 3h8l4 4v14H6z"/><path d="M14 3v4h4"/><path d="M9 14.2l2 2 4-4.2"/></svg>'
    title: Contract as the source of truth
    details: components.json describes each component's props/states/events + the data it takes; validate checks the four platforms' reference symbols really exist, preventing drift.
---

<div class="flare-home">

<div class="flare-stats">
  <div><b>82</b><span>components</span></div>
  <div><b>9</b><span>categories</span></div>
  <div><b>4</b><span>native platforms</span></div>
  <div><b>1</b><span>token source</span></div>
</div>

## One interface, four native platforms

<HomeShowcase />

</div>
