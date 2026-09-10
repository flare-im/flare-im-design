<script lang="ts">
/** Presence shown as the avatar's status dot (shared lexicon with the native kits). */
export type FlarePresence = "online" | "offline" | "busy" | "away";
</script>
<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { useResolvedMediaUrl } from "../../composables/useMediaResolver";
import { avatarTint } from "../../shared/avatar-tint";
import { translateFlare } from "../../shared/i18n/messages";

/**
 * Identity avatar. Accepts the shared `FlareIdentity` shape (`id` / `name` /
 * `avatarUrl`) as well as the original `userId` / `displayName` names — either
 * pair works, `userId` / `displayName` win when both are given.
 */
const props = withDefaults(
  defineProps<{
    userId?: string;
    /** Alias of `userId` (FlareIdentity.id). */
    id?: string;
    displayName?: string;
    /** Alias of `displayName` (FlareIdentity.name). */
    name?: string;
    avatarUrl?: string;
    size?: number;
    /** Presence dot; omit (or `undefined`) to hide the dot. */
    presence?: FlarePresence;
    /** @deprecated Use `presence`; still honoured (`showStatus && status` maps to `presence`). */
    showStatus?: boolean;
    /** @deprecated Use `presence`; still honoured together with `showStatus`. */
    status?: FlarePresence;
  }>(),
  {
    userId: "",
    id: "",
    displayName: "",
    name: "",
    avatarUrl: "",
    size: 40,
    presence: undefined,
    showStatus: false,
    status: "offline",
  },
);

const identityId = computed(() => props.userId || props.id || "");
const identityName = computed(() => props.displayName || props.name || "");
/** Effective presence: the new prop wins; the deprecated pair only applies when `showStatus` is set. */
const resolvedPresence = computed<FlarePresence | null>(
  () => props.presence ?? (props.showStatus ? props.status : null),
);
const presenceLabel = computed(() => (resolvedPresence.value ? translateFlare(`chat.${resolvedPresence.value}`) : ""));

const imageFailed = ref(false);

// `avatarUrl` may be a ready URL/path OR an opaque media fileId. If it has no scheme
// or slash, resolve it as a fileId through the host's media resolver (a no-op default
// when none is provided → falls back to initials).
const rawAvatar = computed(() => (props.avatarUrl ?? "").trim());
const looksLikeUrl = (u: string) => /^[a-z][a-z0-9+.-]*:/i.test(u) || u.includes("/");
const mediaRequest = computed(() =>
  rawAvatar.value && !looksLikeUrl(rawAvatar.value)
    ? { kind: "image" as const, fileId: rawAvatar.value }
    : null,
);
const { url: resolvedAvatar } = useResolvedMediaUrl(mediaRequest);
const displaySrc = computed(() =>
  !rawAvatar.value ? "" : looksLikeUrl(rawAvatar.value) ? rawAvatar.value : resolvedAvatar.value,
);

const initials = computed(() => {
  const source = identityName.value || identityId.value || "U";
  return source.trim().slice(0, 1).toUpperCase();
});

// Soft pastel identity — a tinted surface with dark initials reads more premium
// than a saturated solid and stays legible in both themes. Seeded by the stable
// display name (via the shared util) so the same person is the same colour on
// every surface — list, chat header, message bubbles.
const tint = computed(() => avatarTint(identityName.value || identityId.value));

const style = computed(() => ({
  width: `${props.size}px`,
  height: `${props.size}px`,
  "--avatar-size": `${props.size}px`,
}));

watch(displaySrc, () => {
  imageFailed.value = false;
});
</script>

<template>
  <span class="im-avatar" :style="style">
    <img
      v-if="displaySrc && !imageFailed"
      class="im-avatar__image"
      :src="displaySrc"
      :alt="identityName || identityId"
      @error="imageFailed = true"
    />
    <span
      v-else
      class="im-avatar__fallback"
      :style="{ backgroundColor: tint.bg, color: tint.fg }"
    >
      {{ initials }}
    </span>
    <i
      v-if="resolvedPresence"
      class="im-avatar__status"
      :class="`im-avatar__status--${resolvedPresence}`"
      role="img"
      :aria-label="presenceLabel"
      :title="presenceLabel"
      :data-presence="resolvedPresence"
    />
  </span>
</template>

<style scoped>
.im-avatar {
  position: relative;
  display: inline-flex;
  flex-shrink: 0;
  border-radius: 50%;
  overflow: visible;
}

.im-avatar__image,
.im-avatar__fallback {
  display: grid;
  place-items: center;
  width: 100%;
  height: 100%;
  border-radius: 50%;
}

.im-avatar__image {
  object-fit: cover;
}

.im-avatar__fallback {
  /* color is set inline (pastel pair); initials weight kept a touch lighter */
  font-size: calc(var(--avatar-size) * 0.4);
  font-weight: 600;
  line-height: 1;
}

.im-avatar__status {
  position: absolute;
  right: 0;
  bottom: 0;
  width: 9px;
  height: 9px;
  border: 2px solid var(--im-bg-surface, var(--flare-color-bg-primary, #ffffff));
  border-radius: 50%;
}

.im-avatar__status--online {
  background: var(--im-presence-online, #12b76a);
}

.im-avatar__status--busy {
  background: var(--im-danger, var(--flare-color-error, #ef4444));
}

.im-avatar__status--away {
  background: var(--im-warning, var(--flare-color-warning, #f59e0b));
}

.im-avatar__status--offline {
  background: var(--im-text-tertiary, var(--flare-color-text-tertiary, #687182));
}
</style>
