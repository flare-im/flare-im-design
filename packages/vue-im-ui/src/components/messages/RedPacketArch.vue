<script setup lang="ts">
/** Decorative packet family mark; never carries text or hides an action. */
defineProps<{
  /** 32 high (composer, review) instead of component.redPacketDetailHeaderHeight (detail). */
  compact?: boolean;
}>();
</script>

<template>
  <div class="flare-packet-arch" :class="{ 'is-compact': compact }" aria-hidden="true" />
</template>

<style scoped>
.flare-packet-arch {
  flex: none;
  height: var(--flare-size-component-red-packet-detail-header-height);
  width: 100%;
  background: var(--flare-color-red-packet-end);
  /* A full-width band: straight sides 60% high, the bottom bowed across the whole width by the other 40% (Compose's flap). */
  border-radius: 0 0 50% 50% / 0 0 40% 40%;
  pointer-events: none;
}
/* 32 high in the composer and the review (§4.2); it spans its container and is never clipped by a card. */
.flare-packet-arch.is-compact { height: var(--flare-size-component-red-packet-arch-compact-height); }
</style>
