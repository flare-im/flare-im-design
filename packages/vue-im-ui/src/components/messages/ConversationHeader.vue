<script setup lang="ts">
import {
  computed,
  getCurrentInstance,
  onBeforeUnmount,
  onMounted,
  ref,
} from "vue";
import {
  DefaultDirectConversationHeaderConfig,
  DefaultGroupConversationHeaderConfig,
  resolveConversationHeaderActions,
  type FlareConversationHeaderAction,
  type FlareConversationHeaderCapabilities,
  type FlareConversationHeaderConfiguration,
  type FlareConversationIdentity,
} from "../../shared/contracts/conversation-header";
import { flareIcons, type FlareIconName } from "../../shared/icons";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareIcon from "../general/FlareIcon.vue";
import FlareActionMenu from "../general/FlareActionMenu.vue";
import type { FlareActionItem } from "../../shared/contracts/action-menu";
import { useFlareNativeBack } from "../../shared/platform/useFlareNativeBack";
import { dismissTopFlareContextualLayer } from "../../shared/useContextualLayer";

type HeaderAction = FlareConversationHeaderAction;

const props = defineProps<{
  identity: FlareConversationIdentity;
  capabilities?: FlareConversationHeaderCapabilities;
  configuration?: FlareConversationHeaderConfiguration;
  actions?: readonly HeaderAction[];
  showBack?: boolean;
  label?: string;
}>();

const emit = defineEmits<{
  (event: "back"): void;
  (event: "action", action: HeaderAction): void;
}>();

const { t } = useFlareI18n();
const instance = getCurrentInstance();
const rootRef = ref<HTMLElement | null>(null);
// 返回先退这一页里最上面的上下文层(多选),第二下才离开会话 —— 主流 IM 选择态下头部的前导
// 控件就是「取消选择」。范围限定在页头所在的那个宿主里(页头与时间线是兄弟),详情栏里另一页的
// 返回不会来关这里的多选。busy 的层也算消费:批量进行中不能把人带出会话。
function back(): void {
  if (dismissTopFlareContextualLayer(rootRef.value?.parentElement ?? null)) return;
  emit("back");
}
// The platform back (Android, or a phone browser when the host opts in) does what the back control does.
// 它也先问上下文层:这样认领顺序(跨断点 resize 后页头重新认领、压到工具条上面)就不再要紧。
useFlareNativeBack(() => Boolean(props.showBack && instance?.vnode.props?.onBack), back);
const compact = ref(false);
let observer: ResizeObserver | null = null;

const preset = computed<FlareConversationHeaderConfiguration>(() => {
  const value = props.identity.kind === "group" || props.identity.kind === "channel"
    ? DefaultGroupConversationHeaderConfig
    : DefaultDirectConversationHeaderConfig;
  return {
    maxPrimaryActions: value.maxPrimaryActions,
    compactMaxPrimaryActions: value.compactMaxPrimaryActions,
  };
});

const mergedConfiguration = computed<FlareConversationHeaderConfiguration>(() => ({
  ...preset.value,
  ...props.configuration,
}));

const resolvedActions = computed(() =>
  resolveConversationHeaderActions({
    identity: props.identity,
    capabilities: props.capabilities,
    configuration: mergedConfiguration.value,
    actions: props.actions,
  }),
);
const identityAction = computed(() => {
  const action = props.identity.action;
  if (!action || action.visible === false || mergedConfiguration.value.removeActionIds?.includes(action.id)) return undefined;
  const available = props.capabilities?.availableActionIds;
  if (available && !available.includes(action.capability ?? action.id)) return undefined;
  return action;
});

const addActions = computed(() =>
  resolvedActions.value.filter((action) => action.placement === "add"),
);
const primaryCandidates = computed(() =>
  resolvedActions.value.filter((action) => (action.placement ?? "primary") === "primary"),
);
const maxPrimary = computed(() => Math.max(
  0,
  compact.value
    ? (mergedConfiguration.value.compactMaxPrimaryActions ?? 1)
    : (mergedConfiguration.value.maxPrimaryActions ?? 3),
));
const primaryActions = computed(() => primaryCandidates.value.slice(0, maxPrimary.value));
const overflowActions = computed(() => [
  ...primaryCandidates.value.slice(maxPrimary.value),
  ...resolvedActions.value.filter((action) => action.placement === "overflow"),
]);

const subtitle = computed(() => {
  if (props.identity.typingText?.trim()) return props.identity.typingText.trim();
  if (props.identity.subtitle?.trim()) return props.identity.subtitle.trim();
  if ((props.identity.kind === "group" || props.identity.kind === "channel") && props.identity.memberCount != null) {
    return t("conversationHeader.members", { count: props.identity.memberCount });
  }
  if (props.identity.presence) return t(`chat.${props.identity.presence}`);
  return "";
});

function localizedLabel(action: HeaderAction): string {
  const defaults: Record<string, string> = {
    search: t("chat.searchMessages"),
    audioCall: t("conversationHeader.audioCall"),
    videoCall: t("conversationHeader.videoCall"),
    addMember: t("conversationHeader.addMember"),
    share: t("conversationHeader.share"),
    details: t("chat.details"),
  };
  const defaultEnglish: Record<string, string> = {
    search: "Search messages",
    audioCall: "Start audio call",
    videoCall: "Start video call",
    addMember: "Add member",
    share: props.identity.kind === "single" ? "Share contact" : "Share conversation",
    details: "Conversation details",
  };
  return action.label === defaultEnglish[action.id] ? (defaults[action.id] ?? action.label) : action.label;
}

function actionDescription(action: HeaderAction): string {
  if (action.enabled === false && action.disabledReason) return `${localizedLabel(action)}: ${action.disabledReason}`;
  return action.accessibilityLabel ?? localizedLabel(action);
}

/** The identity block names the conversation and what activating it does. */
const identityActionLabel = computed(() => {
  const action = identityAction.value;
  if (!action) return "";
  return action.accessibilityLabel ?? `${props.identity.title}, ${actionDescription(action)}`;
});

function iconName(action: HeaderAction): FlareIconName {
  const candidate = typeof action.icon === "string" ? action.icon : action.id;
  if (candidate === "task") return "check";
  return candidate in flareIcons ? candidate as FlareIconName : "more";
}

// Header actions reach their menus as the shared action descriptor: a pressed toggle is a
// checked item, an unavailable one keeps its reason.
function menuItems(actions: readonly HeaderAction[]): FlareActionItem[] {
  return actions.map((action) => ({
    id: action.id,
    label: localizedLabel(action),
    icon: iconName(action),
    group: action.group,
    enabled: action.enabled,
    disabledReason: action.disabledReason,
    badge: action.badge,
    accessibilityLabel: actionDescription(action),
    pressed: action.pressed,
  }));
}

const addItems = computed(() => menuItems(addActions.value));
const moreItems = computed(() => menuItems(overflowActions.value));
/** A More menu holding one action is a detour: that action takes the More button itself. */
const soleOverflowAction = computed(() => (overflowActions.value.length === 1 ? overflowActions.value[0] : null));

function selectAction(id: string | number, source: readonly HeaderAction[]): void {
  const action = source.find((item) => item.id === String(id));
  if (action && action.enabled !== false) emit("action", action);
}

function observeWidth(): void {
  if (!rootRef.value || typeof ResizeObserver === "undefined") return;
  observer = new ResizeObserver(([entry]) => {
    // Compact padding changes the content box, so only the outer width is stable.
    const width = entry.borderBoxSize?.[0]?.inlineSize ?? entry.target.getBoundingClientRect().width;
    compact.value = width < 560;
  });
  observer.observe(rootRef.value, { box: "border-box" });
}

onMounted(observeWidth);
onBeforeUnmount(() => observer?.disconnect());
</script>

<template>
  <header
    ref="rootRef"
    class="flare-conversation-header"
    :class="{ 'flare-conversation-header--compact': compact }"
    :aria-label="label || identity.accessibilityLabel || identity.title"
  >
    <button
      v-if="showBack"
      type="button"
      class="flare-conversation-header__icon-button"
      :title="t('common.back')"
      :aria-label="t('common.back')"
      @click="back"
    >
      <FlareIcon name="back" :size="20" />
    </button>

    <div class="flare-conversation-header__identity">
      <slot name="identity" :identity="identity">
        <button
          v-if="identityAction"
          type="button"
          class="flare-conversation-header__identity-action"
          :disabled="identityAction.enabled === false"
          :title="actionDescription(identityAction)"
          :aria-label="identityActionLabel"
          data-header-action="identity"
          @click="selectAction(identityAction.id, [identityAction])"
        >
          <FlareAvatar
            :user-id="identity.id"
            :display-name="identity.title"
            :avatar-url="identity.avatarUrl"
            :presence="identity.presence"
            :size="compact ? 36 : 40"
          />
          <span class="flare-conversation-header__copy">
            <span class="flare-conversation-header__title">{{ identity.title }}</span>
            <span
              v-if="subtitle"
              class="flare-conversation-header__subtitle"
              :class="{
                'is-online': identity.presence === 'online' && !identity.typingText,
                'is-typing': Boolean(identity.typingText),
              }"
            >
              {{ subtitle }}
            </span>
          </span>
        </button>
        <template v-else>
          <FlareAvatar
            :user-id="identity.id"
            :display-name="identity.title"
            :avatar-url="identity.avatarUrl"
            :presence="identity.presence"
            :size="compact ? 36 : 40"
          />
          <div class="flare-conversation-header__copy">
            <h2 class="flare-conversation-header__title">{{ identity.title }}</h2>
            <p
              v-if="subtitle"
              class="flare-conversation-header__subtitle"
              :class="{
                'is-online': identity.presence === 'online' && !identity.typingText,
                'is-typing': Boolean(identity.typingText),
              }"
            >
              {{ subtitle }}
            </p>
          </div>
        </template>
      </slot>
    </div>

    <nav class="flare-conversation-header__actions" :aria-label="t('conversationHeader.actions')">
      <slot name="actions" :actions="primaryActions" :compact="compact">
        <button
          v-for="action in primaryActions"
          :key="action.id"
          type="button"
          class="flare-conversation-header__icon-button"
          :class="{ 'is-pressed': action.pressed }"
          :disabled="action.enabled === false"
          :title="actionDescription(action)"
          :aria-label="actionDescription(action)"
          :aria-pressed="action.pressed === undefined ? undefined : action.pressed"
          :data-header-action="action.id"
          @click="selectAction(action.id, primaryActions)"
        >
          <slot name="action-icon" :action="action">
            <FlareIcon :name="iconName(action)" :size="20" />
          </slot>
          <span v-if="action.badge" class="flare-conversation-header__badge">{{ action.badge }}</span>
        </button>
      </slot>

      <FlareActionMenu
        v-if="addActions.length"
        :items="addItems"
        :label="t('conversationHeader.addActions')"
        @select="(id) => selectAction(id, addActions)"
      >
        <button
          type="button"
          class="flare-conversation-header__icon-button"
          :title="t('conversationHeader.addActions')"
          :aria-label="t('conversationHeader.addActions')"
          data-header-menu="add"
        >
          <FlareIcon name="add" :size="21" />
        </button>
      </FlareActionMenu>

      <button
        v-if="soleOverflowAction"
        type="button"
        class="flare-conversation-header__icon-button"
        :class="{ 'is-pressed': soleOverflowAction.pressed }"
        :disabled="soleOverflowAction.enabled === false"
        :title="actionDescription(soleOverflowAction)"
        :aria-label="actionDescription(soleOverflowAction)"
        :aria-pressed="soleOverflowAction.pressed === undefined ? undefined : soleOverflowAction.pressed"
        :data-header-action="soleOverflowAction.id"
        @click="selectAction(soleOverflowAction.id, overflowActions)"
      >
        <FlareIcon name="more" :size="21" />
        <span v-if="soleOverflowAction.badge" class="flare-conversation-header__badge">{{ soleOverflowAction.badge }}</span>
      </button>
      <FlareActionMenu
        v-else-if="overflowActions.length"
        :items="moreItems"
        :label="t('conversationHeader.moreActions')"
        @select="(id) => selectAction(id, overflowActions)"
      >
        <button
          type="button"
          class="flare-conversation-header__icon-button"
          :title="t('conversationHeader.moreActions')"
          :aria-label="t('conversationHeader.moreActions')"
          data-header-menu="more"
        >
          <FlareIcon name="more" :size="21" />
        </button>
      </FlareActionMenu>

      <slot name="trailing" />
    </nav>
  </header>
</template>

<style scoped>
.flare-conversation-header {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  box-sizing: border-box;
  min-width: 0;
  /* 三端(iOS/Android/Flutter)都是固定 headerHeight + bgPrimary + 实色 borderPrimary;
     这里原来是 min-height + bgSecondary + 72% 稀释的分隔线,是四端唯一不同的那一份。 */
  height: var(--flare-size-layout-header-height);
  padding-inline: var(--flare-size-spacing-lg);
  color: var(--flare-color-text-primary);
  background: var(--flare-color-bg-primary);
  border-bottom: 1px solid var(--flare-color-border-primary);
}

.flare-conversation-header__identity {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-2sm);
  flex: 1;
  min-width: 0;
}

.flare-conversation-header__copy {
  display: flex;
  flex-direction: column;
  gap: 1px;
  min-width: 0;
}

.flare-conversation-header__identity-action {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-2sm);
  flex: 1;
  min-width: 0;
  min-height: 48px;
  margin-inline-start: -6px;
  padding: 0 6px;
  border: 0;
  border-radius: var(--flare-size-radius-md);
  color: inherit;
  background: transparent;
  font: inherit;
  text-align: start;
  cursor: pointer;
  transition: background-color var(--flare-transition-fast);
}

.flare-conversation-header__identity-action:hover:not(:disabled) {
  background: var(--flare-color-bg-hover);
}

.flare-conversation-header__identity-action:active:not(:disabled) {
  background: var(--flare-color-bg-selected);
}

.flare-conversation-header__identity-action:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: 2px;
}

.flare-conversation-header__identity-action:disabled {
  opacity: 0.42;
  cursor: not-allowed;
}

.flare-conversation-header__title,
.flare-conversation-header__subtitle {
  display: block;
  overflow: hidden;
  margin: 0;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.flare-conversation-header__title {
  color: var(--flare-component-chat-hdr-title);
  font-size: var(--flare-size-font-size-2xl);
  font-weight: var(--flare-size-font-weight-semibold);
  line-height: 1.3;
  letter-spacing: 0;
}

.flare-conversation-header__subtitle {
  color: var(--flare-color-text-tertiary);
  font-size: var(--flare-size-font-size-sm);
  line-height: 1.35;
}

.flare-conversation-header__subtitle.is-online,
.flare-conversation-header__subtitle.is-typing {
  color: var(--flare-color-success-text);
}

.flare-conversation-header__actions {
  display: flex;
  align-items: center;
  gap: 2px;
  flex: none;
}

.flare-conversation-header__icon-button {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex: 0 0 auto;
  width: 48px;
  height: 48px;
  padding: 0;
  border: 0;
  border-radius: var(--flare-size-radius-md);
  color: var(--flare-color-text-secondary);
  background: transparent;
  cursor: pointer;
  transition: color var(--flare-transition-fast), background-color var(--flare-transition-fast);
}

.flare-conversation-header__icon-button:hover:not(:disabled) {
  color: var(--flare-color-primary-text);
  background: var(--flare-color-bg-hover);
}

.flare-conversation-header__icon-button.is-pressed {
  color: var(--flare-color-primary-text);
  background: var(--flare-color-bg-selected);
}

.flare-conversation-header__icon-button:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: 2px;
}

.flare-conversation-header__icon-button:disabled {
  opacity: 0.42;
  cursor: not-allowed;
}

.flare-conversation-header__badge {
  position: absolute;
  top: 2px;
  right: 1px;
  min-width: 15px;
  height: 15px;
  padding: 0 3px;
  border: 2px solid var(--flare-color-bg-secondary);
  border-radius: var(--flare-size-radius-full);
  color: #ffffff;
  background: var(--flare-color-error);
  font-size: 9px;
  font-weight: 700;
  line-height: 11px;
}

.flare-conversation-header--compact {
  gap: 4px;
  padding-inline: var(--flare-size-spacing-sm);
}

.flare-conversation-header--compact .flare-conversation-header__icon-button {
  width: 44px;
  height: 44px;
}
</style>
