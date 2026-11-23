<script lang="ts">
/** Presence shown as the avatar's status dot (shared lexicon with the native kits). */
export type FlarePresence = "online" | "offline" | "busy" | "away";
</script>
<script setup lang="ts">
import { computed, getCurrentInstance, ref, watch } from "vue";
import { useResolvedMediaUrl } from "../../composables/useMediaResolver";
import { avatarTint } from "../../shared/avatar-tint";
import { translateFlare } from "../../shared/i18n/messages";
import FlareIcon from "../general/FlareIcon.vue";

/**
 * Identity avatar. Accepts the shared `FlareIdentity` shape (`id` / `name` /
 * `avatarUrl`) as well as the original `userId` / `displayName` names — either
 * pair works, `userId` / `displayName` win when both are given.
 *
 * With a `click` listener it is a button (Flutter's `onTap`): named by `ariaLabel`, else by the person (and the
 * presence, when shown), keyboard reachable, and with a hit area that reaches the touch target however small it is
 * drawn. Without one it only shows the person, as before; a host no longer wraps it in a button to make it open.
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
    /** A group's avatar: a people mark in the corner (instead of the presence dot) tells it from a person at a glance. */
    group?: boolean;
    /**
     * The button's accessible name while the avatar is tappable (what it opens, e.g. "林夏的个人资料"). Defaults to the
     * person's name. Ignored while the avatar only shows the person.
     */
    ariaLabel?: string;
  }>(),
  {
    userId: "",
    id: "",
    displayName: "",
    name: "",
    avatarUrl: "",
    size: 40,
    presence: undefined,
    group: false,
    ariaLabel: undefined,
  },
);
const emit = defineEmits<{
  /** The avatar was activated (click, tap, Enter or Space): the host opens what it stands for. */
  (event: "click", nativeEvent: MouseEvent): void;
}>();

const identityId = computed(() => props.userId || props.id || "");
const identityName = computed(() => props.displayName || props.name || "");
/** What the corner mark says: a group (which has no presence), else the person's presence, else nothing. */
const presenceLabel = computed(() =>
  props.group ? translateFlare("displayName.group") : props.presence ? translateFlare(`chat.${props.presence}`) : "",
);
const groupMarkSize = computed(() => Math.round(props.size * 0.45));

const instance = getCurrentInstance();
/** A button only while the host takes the click; read at render time so a listener bound later counts. */
const tappable = (): boolean => Boolean(instance?.vnode.props?.onClick);
/** The button's name: the host's words, else the person, with the presence the dot shows. */
const buttonLabel = computed(() => {
  if (props.ariaLabel) return props.ariaLabel;
  const person = identityName.value || identityId.value;
  return presenceLabel.value ? `${person}, ${presenceLabel.value}` : person;
});
function onClick(event: MouseEvent): void {
  if (tappable()) emit("click", event);
}

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
  <component
    :is="tappable() ? 'button' : 'span'"
    :type="tappable() ? 'button' : undefined"
    class="im-avatar"
    :class="{ 'im-avatar--interactive': tappable() }"
    :style="style"
    :aria-label="tappable() ? buttonLabel : undefined"
    @click="onClick"
  >
    <img
      v-if="displaySrc && !imageFailed"
      class="im-avatar__image"
      :src="displaySrc"
      :alt="tappable() ? '' : identityName || identityId"
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
      v-if="group"
      class="im-avatar__group"
      role="img"
      :aria-label="presenceLabel"
      :title="presenceLabel"
      :style="{ width: `${groupMarkSize}px`, height: `${groupMarkSize}px`, backgroundColor: tint.fg, color: tint.bg }"
    >
      <FlareIcon name="group" :size="Math.round(groupMarkSize * 0.56)" />
    </i>
    <i
      v-else-if="presence"
      class="im-avatar__status"
      :class="`im-avatar__status--${presence}`"
      role="img"
      :aria-label="presenceLabel"
      :title="presenceLabel"
      :data-presence="presence"
    />
  </component>
</template>

<style scoped>
.im-avatar {
  position: relative;
  display: inline-flex;
  flex-shrink: 0;
  border-radius: 50%;
  overflow: visible;
}

/* Tappable: a bare button the size of the avatar, whose hit area reaches the touch target around it (::after, the
   same as FlareButton) so a 28px header avatar is still easy to hit; the layout keeps the drawn size. */
.im-avatar--interactive {
  /* accessibility.css gives every button a 44px floor on a coarse pointer; that would draw a 28px avatar at 44.
     The ::after below is what reaches the touch target, so the avatar keeps its own size (as FlareButton does). */
  min-width: 0;
  min-height: 0;
  margin: 0;
  padding: 0;
  border: 0;
  background: transparent;
  color: inherit;
  font: inherit;
  cursor: pointer;
}
.im-avatar--interactive::after {
  content: "";
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: max(100%, var(--flare-size-layout-touch-target));
  height: max(100%, var(--flare-size-layout-touch-target));
  border-radius: 50%;
}
.im-avatar--interactive:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: 2px;
}
@media (hover: hover) {
  .im-avatar--interactive:hover { filter: brightness(0.96); }
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
  border: 2px solid var(--flare-color-bg-primary);
  border-radius: 50%;
}

/* The avatar's own palette inverted (its initials colour as the fill), ringed in the surface colour so it stands
   off the avatar and reads on any tint or photo. Strokes are thickened: at this size the default ones vanish. */
.im-avatar__group {
  position: absolute;
  right: -3px;
  bottom: -3px;
  display: grid;
  place-items: center;
  box-sizing: border-box;
  border: 2px solid var(--flare-color-bg-primary);
  border-radius: 50%;
}
.im-avatar__group :deep(svg) {
  stroke-width: 3;
}

.im-avatar__status--online {
  background: var(--flare-color-success);
}

.im-avatar__status--busy {
  background: var(--flare-color-error);
}

.im-avatar__status--away {
  background: var(--flare-color-warning);
}

.im-avatar__status--offline {
  background: var(--flare-color-text-tertiary);
}
</style>
