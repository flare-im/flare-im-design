<script lang="ts">
export type { FlareUserIdentityValue } from "../../shared/contracts/user-identity";
</script>
<script setup lang="ts">
import type { FlareUserIdentityValue } from "../../shared/contracts/user-identity";
import { computed } from "vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareIcon from "../general/FlareIcon.vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
const props = defineProps<{ user: FlareUserIdentityValue }>();
const { t } = useFlareI18nOptional();
const ready = computed(() => !props.user.state || props.user.state === "ready");
const name = computed(() =>
  props.user.state === "loading"
    ? t("userIdentity.loading")
    : (ready.value && props.user.name?.trim()) || t("userIdentity.unavailable"),
);
</script>
<template>
  <span class="flare-user-identity" :aria-busy="user.state === 'loading'">
    <!-- Loading or unavailable: a neutral avatar. The label is not a name, so its first character is not drawn. -->
    <FlareAvatar v-if="ready" :name="name" :avatar-url="user.avatarUrl" :size="36" aria-hidden="true" />
    <span v-else class="flare-user-identity__avatar" aria-hidden="true">
      <FlareIcon name="person" :size="18" />
    </span>
    <span class="flare-user-identity__text">
      <span class="flare-user-identity__name">{{ name }}</span>
      <span class="flare-user-identity__account">{{
        (ready && user.account) || t("userIdentity.accountUnavailable")
      }}</span>
    </span>
  </span>
</template>
<style scoped>
.flare-user-identity {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
  max-width: 100%;
  vertical-align: middle;
}
.flare-user-identity__avatar {
  display: inline-flex;
  flex-shrink: 0;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: var(--flare-color-bg-tertiary);
  color: var(--flare-color-text-tertiary);
}
.flare-user-identity__text {
  display: grid;
  gap: var(--flare-size-spacing-2xs);
  min-width: 0;
}
.flare-user-identity__name,
.flare-user-identity__account {
  overflow-wrap: anywhere;
  white-space: normal;
}
.flare-user-identity__name {
  color: var(--flare-color-text-primary);
  font-weight: 500;
}
.flare-user-identity__account {
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-sm);
}
</style>
