<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { useResolvedMediaUrl } from "../../composables/useMediaResolver";

const props = withDefaults(
  defineProps<{
    userId: string;
    displayName?: string;
    avatarUrl?: string;
    size?: number;
    showStatus?: boolean;
    status?: "online" | "offline" | "busy";
  }>(),
  {
    displayName: "",
    avatarUrl: "",
    size: 40,
    showStatus: false,
    status: "offline",
  },
);

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
  const source = props.displayName || props.userId || "U";
  return source.trim().slice(0, 1).toUpperCase();
});

// Soft pastel identity — matches the reference app (avatarPastelForKey): a
// tinted surface with dark initials reads more premium than a saturated solid
// and stays legible in both themes. Keyed by a stable id.
const tint = computed(() => {
  const pairs = [
    { bg: "#DBEAFE", fg: "#1D4ED8" },
    { bg: "#E9D5FF", fg: "#6D28D9" },
    { bg: "#FBCFE8", fg: "#BE185D" },
    { bg: "#D1FAE5", fg: "#047857" },
    { bg: "#FEF3C7", fg: "#B45309" },
    { bg: "#E5E7EB", fg: "#374151" },
  ];
  let hash = 0;
  for (const char of props.userId || props.displayName || "user") {
    hash = char.charCodeAt(0) + ((hash << 5) - hash);
  }
  return pairs[Math.abs(hash) % pairs.length];
});

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
      :alt="displayName || userId"
      @error="imageFailed = true"
    />
    <span
      v-else
      class="im-avatar__fallback"
      :style="{ backgroundColor: tint.bg, color: tint.fg }"
    >
      {{ initials }}
    </span>
    <i v-if="showStatus" class="im-avatar__status" :class="`im-avatar__status--${status}`" />
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

.im-avatar__status--offline {
  background: var(--im-text-tertiary, var(--flare-color-text-tertiary, #a3a7ae));
}
</style>
