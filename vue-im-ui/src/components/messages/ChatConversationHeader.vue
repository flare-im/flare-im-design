<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import { NIcon } from "naive-ui";
import { CallOutline, ChevronBackOutline, EllipsisHorizontalOutline, SearchOutline } from "../../shared/icon-glyphs";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import Avatar from "../conversation/FlareAvatar.vue";
import type { FlarePresence } from "../conversation/FlareAvatar.vue";

/**
 * Chat header — a transparent bar (no filled surface) that blends into the chat
 * canvas. Same surface as the three native kits: `title / subtitle / presence /
 * avatarUserId / avatarUrl` render a default identity block, and the trailing
 * `search / call / details` buttons only appear when the host listens for the
 * matching event. Both the `identity` and `actions` slots still override the
 * defaults wholesale. When `showBack` is set, a leading back button sits to the
 * LEFT of the avatar; hosts wire `@back` to their navigation.
 */
const props = withDefaults(
  defineProps<{
    title?: string;
    subtitle?: string;
    /** Presence dot on the avatar; also tints the subtitle when online. */
    presence?: FlarePresence;
    /** Renders the default avatar when set (initials fall back to `title`). */
    avatarUserId?: string;
    avatarUrl?: string;
    /** Show the leading back button. */
    showBack?: boolean;
    /** @deprecated Use `showBack`. Still honoured. */
    back?: boolean;
  }>(),
  {
    title: "",
    subtitle: "",
    presence: undefined,
    avatarUserId: "",
    avatarUrl: "",
    showBack: false,
    back: false,
  },
);
const emit = defineEmits<{
  (event: "back"): void;
  (event: "search"): void;
  (event: "call"): void;
  (event: "details"): void;
}>();
const { t } = useFlareI18n();

const instance = getCurrentInstance();
const hasSearch = computed(() => !!instance?.vnode.props?.onSearch);
const hasCall = computed(() => !!instance?.vnode.props?.onCall);
const hasDetails = computed(() => !!instance?.vnode.props?.onDetails);

const backVisible = computed(() => props.showBack || props.back);
const hasIdentity = computed(() => Boolean(props.title || props.avatarUserId));
const presenceText = computed(() => (props.presence ? t(`chat.${props.presence}`) : ""));
</script>

<template>
  <header class="im-chat-header">
    <button
      v-if="backVisible"
      type="button"
      class="im-chat-header__back"
      :title="t('common.back')"
      :aria-label="t('common.back')"
      @click="emit('back')"
    >
      <n-icon :size="22" :component="ChevronBackOutline" />
    </button>
    <div class="im-chat-header__identity">
      <slot name="identity">
        <div v-if="hasIdentity" class="im-chat-header__default-identity">
          <Avatar
            v-if="avatarUserId"
            :user-id="avatarUserId"
            :display-name="title"
            :avatar-url="avatarUrl"
            :presence="presence"
            :size="36"
          />
          <div class="im-chat-header__text">
            <h2 class="im-chat-header__title">{{ title }}</h2>
            <p
              v-if="subtitle"
              class="im-chat-header__subtitle"
              :class="{ 'im-chat-header__subtitle--online': presence === 'online' }"
              :title="presenceText || undefined"
            >
              {{ subtitle }}
            </p>
          </div>
        </div>
      </slot>
    </div>
    <div class="im-chat-header__actions">
      <slot name="actions">
        <button
          v-if="hasSearch"
          type="button"
          class="im-chat-header__action"
          :title="t('chat.searchMessages')"
          :aria-label="t('chat.searchMessages')"
          @click="emit('search')"
        >
          <n-icon :size="20" :component="SearchOutline" />
        </button>
        <button
          v-if="hasCall"
          type="button"
          class="im-chat-header__action"
          :title="t('chat.call')"
          :aria-label="t('chat.call')"
          @click="emit('call')"
        >
          <n-icon :size="20" :component="CallOutline" />
        </button>
        <button
          v-if="hasDetails"
          type="button"
          class="im-chat-header__action"
          :title="t('chat.details')"
          :aria-label="t('chat.details')"
          @click="emit('details')"
        >
          <n-icon :size="20" :component="EllipsisHorizontalOutline" />
        </button>
      </slot>
    </div>
  </header>
</template>

<style scoped>
.im-chat-header {
  display: flex;
  align-items: center;
  gap: 8px;
  min-height: var(--layout-header, 60px);
  min-width: 0;
  padding: 8px 12px;
  /* No filled surface — the header blends into the chat canvas (no white bar). */
  background: transparent;
  border-bottom: none;
  box-shadow: none;
}

.im-chat-header__back,
.im-chat-header__action {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex: 0 0 auto;
  width: 36px;
  height: 36px;
  padding: 0;
  border: 0;
  border-radius: 10px;
  color: var(--im-chat-hdr-title, var(--flare-color-text-primary, #20232D));
  background: transparent;
  cursor: pointer;
  transition: background var(--im-motion-fast, 140ms ease), color var(--im-motion-fast, 140ms ease);
}

.im-chat-header__back {
  margin: 0 -2px 0 -4px;
}

.im-chat-header__action {
  color: var(--flare-color-text-secondary, #626978);
}

.im-chat-header__back:hover,
.im-chat-header__action:hover {
  color: var(--im-brand-primary, var(--flare-color-primary, #7047D6));
  background: color-mix(in srgb, var(--im-brand-primary) 10%, transparent);
}

.im-chat-header__identity {
  display: flex;
  align-items: center;
  min-width: 0;
  flex: 1;
}

.im-chat-header__default-identity {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
}

.im-chat-header__text {
  display: flex;
  flex-direction: column;
  gap: 1px;
  min-width: 0;
}

.im-chat-header__title {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  line-height: 1.25;
  color: var(--im-chat-hdr-title, var(--flare-color-text-primary, #20232D));
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.im-chat-header__subtitle {
  margin: 0;
  font-size: 12px;
  line-height: 1.3;
  color: var(--flare-color-text-tertiary, #687182);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.im-chat-header__subtitle--online {
  color: var(--im-presence-online, var(--flare-color-success, #22C55E));
}

.im-chat-header__actions {
  display: flex;
  align-items: center;
  gap: 4px;
  flex-shrink: 0;
}

@media (min-width: 900px) {
  .im-chat-header {
    min-height: 62px;
    padding-inline: 16px;
  }
}
</style>
