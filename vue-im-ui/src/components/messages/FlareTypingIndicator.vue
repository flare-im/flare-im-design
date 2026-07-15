<script setup lang="ts">
import { computed } from "vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    /** Who is typing. Empty = a generic single typer. */
    names?: string[];
    /** Avatar shown in the `bubble` variant (single typer). */
    userId?: string;
    avatarUrl?: string;
    /** `bubble` = a received-style bubble with dots (timeline); `inline` = dots + text only. */
    variant?: "bubble" | "inline";
  }>(),
  { names: () => [], variant: "bubble" },
);

const { t } = useFlareI18n();
const label = computed(() => {
  const names = props.names.filter(Boolean);
  if (names.length === 0) return t("typing.single");
  if (names.length === 1) return t("typing.named", { name: names[0] });
  return t("typing.multi", { count: names.length });
});
const bubbleUser = computed(() => props.names[0] || props.userId || "typing");
</script>

<template>
  <div class="flare-typing" :class="`flare-typing--${variant}`" role="status" :aria-label="label">
    <FlareAvatar
      v-if="variant === 'bubble'"
      :user-id="bubbleUser"
      :display-name="bubbleUser"
      :avatar-url="avatarUrl"
      :size="32"
    />
    <div class="flare-typing__body">
      <span v-if="variant === 'inline' || names.length" class="flare-typing__label">{{ label }}</span>
      <span class="flare-typing__dots" aria-hidden="true">
        <i /><i /><i />
      </span>
    </div>
  </div>
</template>

<style scoped>
.flare-typing {
  display: inline-flex;
  align-items: flex-end;
  gap: 8px;
}
.flare-typing__body {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}
.flare-typing--bubble .flare-typing__body {
  padding: 10px 14px;
  border-radius: 4px 16px 16px 16px;
  background: var(--flare-color-bg-primary, #fff);
  border: 1px solid var(--flare-color-border-primary, #e9e6f1);
  box-shadow: var(--flare-shadow-sm, 0 1px 2px rgba(21, 18, 32, 0.05));
}
.flare-typing__label {
  font-size: 13px;
  color: var(--flare-color-text-tertiary, #a7a2b4);
}
.flare-typing__dots {
  display: inline-flex;
  align-items: center;
  gap: 4px;
}
.flare-typing__dots i {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--flare-color-text-tertiary, #a7a2b4);
  animation: flare-typing-bounce 1.3s ease-in-out infinite;
}
.flare-typing__dots i:nth-child(2) { animation-delay: 0.18s; }
.flare-typing__dots i:nth-child(3) { animation-delay: 0.36s; }
.flare-typing--bubble .flare-typing__dots i {
  background: var(--flare-color-primary, #7c3aed);
  opacity: 0.65;
}
@keyframes flare-typing-bounce {
  0%, 60%, 100% { transform: translateY(0); opacity: 0.55; }
  30% { transform: translateY(-4px); opacity: 1; }
}
@media (prefers-reduced-motion: reduce) {
  .flare-typing__dots i { animation: none; }
}
</style>
