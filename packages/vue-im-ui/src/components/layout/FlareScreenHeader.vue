<script setup lang="ts">
// Screen-level large-title header — the quiet top bar for a tab surface
// (inbox / directory / me). Distinct from ChatHeader (conversation chrome).
defineProps<{ title: string; eyebrow?: string; meta?: string }>();
</script>

<template>
  <header class="flare-screen-header">
    <!-- Back, a profile avatar, a picker: what the screen is reached through, before its title. -->
    <div v-if="$slots.leading" class="flare-screen-header__leading"><slot name="leading" /></div>
    <div class="flare-screen-header__heading">
      <span v-if="eyebrow" class="flare-screen-header__eyebrow">{{ eyebrow }}</span>
      <h1 class="flare-screen-header__title">{{ title }}</h1>
      <span v-if="meta" class="flare-screen-header__meta">{{ meta }}</span>
    </div>
    <div class="flare-screen-header__actions">
      <slot name="actions" />
    </div>
  </header>
</template>

<style scoped>
.flare-screen-header {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  background: var(--flare-color-bg-primary);
}
.flare-screen-header__leading {
  display: flex;
  flex: 0 0 auto;
  align-items: center;
}
.flare-screen-header__heading {
  flex: 1;
  display: grid;
  gap: 2px;
  min-width: 0;
}
.flare-screen-header__eyebrow {
  color: var(--flare-color-text-tertiary);
  font-size: 11px;
  font-weight: 700;
  line-height: 1.2;
  text-transform: uppercase;
}
.flare-screen-header__title {
  margin: 0;
  font-size: 24px;
  font-weight: 700;
  line-height: 1.2;
  color: var(--flare-color-text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-screen-header__meta {
  overflow: hidden;
  color: var(--flare-color-text-tertiary);
  font-size: 12px;
  font-weight: 500;
  line-height: 1.35;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-screen-header__actions {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  flex: 0 0 auto;
}
</style>
