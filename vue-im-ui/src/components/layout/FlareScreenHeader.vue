<script setup lang="ts">
// Screen-level large-title header — the quiet top bar for a tab surface
// (inbox / directory / me). Distinct from ChatHeader (conversation chrome).
defineProps<{ title: string }>();
</script>

<template>
  <header class="flare-screen-header">
    <h1 class="flare-screen-header__title">{{ title }}</h1>
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
  background: var(--flare-color-bg-primary, #fff);
}
.flare-screen-header__title {
  flex: 1;
  min-width: 0;
  margin: 0;
  font-size: 24px;
  font-weight: 700;
  line-height: 1.2;
  color: var(--flare-color-text-primary, #15131c);
  overflow: hidden;
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
