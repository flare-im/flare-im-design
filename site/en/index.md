---
layout: home
hero:
  name: Flare IM Design
  text: Cross-platform IM UI kit
  tagline: One contract, four native implementations — Vue · Flutter · iOS · Android. Behavior lives in the Rust core; each platform only renders.
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
    title: 51 components · 9 categories
    details: General / Conversation / Message / Composer / Media / Contacts / Profile / Call / Layout. One framework-neutral contract per component, natively implemented on Vue, Flutter, iOS and Android — same name, same semantics.
  - icon: '<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="1.6"><circle cx="9" cy="9.8" r="4.6"/><circle cx="15" cy="9.8" r="4.6"/><circle cx="12" cy="15" r="4.6"/></svg>'
    title: One set of design tokens
    details: A neutral tokens.json single source generates Web CSS/TS, Dart, Swift and Kotlin — identical color, spacing, type and radius across platforms, light + dark, re-themeable at runtime.
  - icon: '<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"><rect x="6" y="6" width="12" height="12" rx="2.5"/><rect x="9.8" y="9.8" width="4.4" height="4.4" rx="1"/><path d="M9.5 6V3M14.5 6V3M9.5 21v-3M14.5 21v-3M6 9.5H3M6 14.5H3M21 9.5h-3M21 14.5h-3"/></svg>'
    title: Behavior in the core
    details: Reliable send, sync convergence, ordering, optimistic UI and content dispatch all live in the Rust core's observable views. Components are pure presentation — props in, callbacks out.
  - icon: '<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M13 2.5 4.8 13.4H11l-.9 8.1 9.1-11.2H13z"/></svg>'
    title: Performance & smoothness first
    details: Optimistic UI paints next frame (< 16 ms), lists virtualise O(visible), media stays off the main thread, caches evict with bounds — budgets are the design.
  - icon: '<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"><rect x="4" y="4" width="7" height="7" rx="1.4"/><rect x="13" y="4" width="7" height="7" rx="1.4"/><rect x="4" y="13" width="7" height="7" rx="1.4"/><rect x="13" y="13" width="7" height="7" rx="1.4" stroke-dasharray="2.6 2.6"/></svg>'
    title: Extensible content types
    details: Text/image/video/file/location/card/sticker… 17 built in; products register custom types (vote/task/…) through the content registry.
  - icon: '<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M6 3h8l4 4v14H6z"/><path d="M14 3v4h4"/><path d="M9 14.2l2 2 4-4.2"/></svg>'
    title: Contract as the source of truth
    details: components.json describes each component's props/states/events + core data source; validate checks the four platforms' reference symbols really exist, preventing drift.
---

<div class="flare-home">

<div class="flare-stats">
  <div><b>51</b><span>components</span></div>
  <div><b>9</b><span>categories</span></div>
  <div><b>4</b><span>native platforms</span></div>
  <div><b>1</b><span>token source</span></div>
</div>

## One interface, four native platforms

<HomeShowcase />

</div>
