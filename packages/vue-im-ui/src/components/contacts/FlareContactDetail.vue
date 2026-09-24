<script setup lang="ts">
/**
 * Contact profile — hero (avatar / name / presence / star chip), an action row
 * (message / voice / video), a 资料 settings card (Flare ID / remark /
 * description / favorite toggle), and a danger zone (block / remove). Purely
 * presentational: it renders state from props and emits intents; the host owns
 * the edit sheets and host writes.
 *
 * An intent appears only when the host handles it: a host without calls gets no
 * voice or video button, and a stranger's profile (no remark, star or remove
 * handlers) shows remark and description as read-only values and no friend-only
 * actions. `disabledActions` is for actions that exist but are unavailable now.
 */
import { computed, getCurrentInstance } from "vue";
import { NIcon } from "naive-ui";
import {
  CallOutline,
  ChatbubbleEllipsesOutline,
  VideocamOutline,
} from "../../shared/icon-glyphs";
import { flareIcons } from "../../shared/icons";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareSettingsList from "../profile/FlareSettingsList.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type {
  FlareContact,
  FlareDetailExtraAction,
  FlareSettingsItem,
  FlareSettingsSection,
} from "../../shared/contracts";

const props = defineProps<{
  contact: FlareContact;
  disabledActions?: ("message" | "call" | "video")[];
  busy?: boolean;
  /** Whether the viewer has starred (favorited) this contact. */
  starred?: boolean;
  /** Free-text description the viewer set for this contact. */
  description?: string;
  /** Host actions the kit cannot know about (report, share, an admin tool); drawn under the kit's own. */
  extraActions?: FlareDetailExtraAction[];
}>();
const emit = defineEmits<{
  (e: "message"): void;
  (e: "call"): void;
  (e: "video"): void;
  /** Edit the remark (备注). */
  (e: "edit"): void;
  /** Edit the description (描述). */
  (e: "editDescription"): void;
  (e: "toggleStar", value: boolean): void;
  (e: "block"): void;
  (e: "remove"): void;
  /** One of `extraActions` was chosen; the payload is its id. */
  (e: "extraAction", id: string): void;
}>();

const { t } = useFlareI18n();
const instance = getCurrentInstance();
// Read at render time, not cached: a host may bind different handlers once the relationship changes.
function handles(listener: "onMessage" | "onCall" | "onVideo" | "onEdit" | "onEditDescription" | "onToggleStar" | "onBlock" | "onRemove"): boolean {
  return Boolean(instance?.vnode.props?.[listener]);
}

const avatarStatus = computed<"online" | "offline" | "busy">(() => {
  if (props.contact.presence === "online") return "online";
  if (props.contact.presence === "busy" || props.contact.presence === "away") return "busy";
  return "offline";
});
const presenceLabel = computed(() =>
  props.contact.presence ? t(`contact.${props.contact.presence}`) : "",
);

function sections(): FlareSettingsSection[] {
  const items: FlareSettingsItem[] = [];
  // The public handle only: the account id is internal and never shown.
  if (props.contact.flareId) {
    items.push({ key: "flareId", label: t("contact.flareId"), icon: "id", kind: "value", detail: props.contact.flareId });
  }
  const remark = props.contact.remark || "";
  if (handles("onEdit") || remark) {
    items.push({ key: "remark", label: t("contact.remark"), icon: "edit", kind: handles("onEdit") ? "navigation" : "value", disabled: props.busy, detail: remark || t("contact.notSet") });
  }
  if (handles("onEditDescription") || props.description) {
    items.push({ key: "description", label: t("contact.description"), icon: "comment", kind: handles("onEditDescription") ? "navigation" : "value", disabled: props.busy, detail: props.description || t("contact.notSet") });
  }
  if (handles("onToggleStar")) {
    items.push({ key: "star", label: t("contact.star"), icon: "star", kind: "toggle", disabled: props.busy, value: props.starred ?? false });
  }
  return items.length ? [{ title: t("contact.info"), items }] : [];
}

type ContactAction = { id: "message" | "call" | "video"; listener: "onMessage" | "onCall" | "onVideo"; label: string; icon: typeof CallOutline; primary?: boolean };
function actions(): ContactAction[] {
  const all: ContactAction[] = [
    { id: "message", listener: "onMessage", label: t("contact.message"), icon: ChatbubbleEllipsesOutline, primary: true },
    { id: "call", listener: "onCall", label: t("contact.voice"), icon: CallOutline },
    { id: "video", listener: "onVideo", label: t("contact.video"), icon: VideocamOutline },
  ];
  return all.filter((action) => handles(action.listener));
}

function runAction(id: ContactAction["id"]): void {
  if (id === "message") emit("message");
  else if (id === "call") emit("call");
  else emit("video");
}

function onSelect(item: FlareSettingsItem) {
  if (props.busy) return;
  if (item.key === "remark") emit("edit");
  else if (item.key === "description") emit("editDescription");
}
function onToggle(item: FlareSettingsItem, value: boolean) {
  if (props.busy) return;
  if (item.key === "star") emit("toggleStar", value);
}
</script>

<template>
  <div class="flare-contact-detail">
    <div class="flare-contact-detail__hero">
      <FlareAvatar
        :user-id="contact.id"
        :display-name="contact.name"
        :avatar-url="contact.avatarUrl"
        :size="76"
        show-status
        :status="avatarStatus"
      />
      <div class="flare-contact-detail__name">{{ contact.name }}</div>
      <div v-if="presenceLabel" class="flare-contact-detail__presence" :class="`is-${contact.presence}`">
        <span class="dot" />{{ presenceLabel }}
      </div>
      <div v-if="contact.signature" class="flare-contact-detail__sig">{{ contact.signature }}</div>
      <span v-if="starred" class="flare-contact-detail__star"><n-icon aria-hidden="true" :size="12" :component="flareIcons.star" />{{ t("contact.star") }}</span>
    </div>

    <div v-if="actions().length" class="flare-contact-detail__actions" :class="{ 'is-single': actions().length === 1 }">
      <button
        v-for="action in actions()"
        :key="action.id"
        type="button"
        :class="{ 'is-primary': action.primary }"
        :disabled="busy || disabledActions?.includes(action.id)"
        @click="runAction(action.id)"
      >
        <n-icon aria-hidden="true" :size="20" :component="action.icon" /><span>{{ action.label }}</span>
      </button>
    </div>

    <FlareSettingsList v-if="sections().length" class="flare-contact-detail__card" :sections="sections()" @select="onSelect" @toggle="onToggle" />

    <div v-if="extraActions?.length" class="flare-contact-detail__extra">
      <button
        v-for="action in extraActions"
        :key="action.id"
        type="button"
        :class="{ 'is-danger': action.danger }"
        :disabled="busy"
        @click="emit('extraAction', action.id)"
      >{{ action.label }}</button>
    </div>

    <div v-if="handles('onBlock') || handles('onRemove')" class="flare-contact-detail__foot">
      <button v-if="handles('onBlock')" type="button" :disabled="busy" @click="emit('block')">{{ t("contact.block") }}</button>
      <button v-if="handles('onRemove')" type="button" class="is-danger" :disabled="busy" @click="emit('remove')">{{ t("contact.remove") }}</button>
    </div>
  </div>
</template>

<style scoped>
.flare-contact-detail { display: flex; flex-direction: column; }
.flare-contact-detail__hero { display: flex; flex-direction: column; align-items: center; gap: 8px; padding: 24px 16px var(--flare-size-spacing-2sm); }
.flare-contact-detail__name { font-size: 20px; font-weight: 700; letter-spacing: -0.01em; color: var(--flare-color-text-primary); }
.flare-contact-detail__presence { display: inline-flex; align-items: center; gap: 6px; font-size: 12px; color: var(--flare-color-text-secondary); }
.flare-contact-detail__presence .dot { width: 7px; height: 7px; border-radius: 50%; background: var(--flare-color-text-tertiary); }
.flare-contact-detail__presence.is-online .dot { background: var(--flare-color-success); }
.flare-contact-detail__presence.is-busy .dot { background: var(--flare-color-error); }
.flare-contact-detail__presence.is-away .dot { background: var(--flare-color-warning); }
.flare-contact-detail__sig { font-size: 13px; color: var(--flare-color-text-secondary); text-align: center; }
.flare-contact-detail__star {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 2px var(--flare-size-spacing-2sm); border-radius: 999px; font-size: 12px; font-weight: 600;
  color: var(--flare-color-primary-text); background: var(--flare-color-bg-selected);
}

.flare-contact-detail__actions { display: flex; gap: var(--flare-size-spacing-2sm); padding: 6px 16px 4px; }
.flare-contact-detail__actions button {
  flex: 1; display: flex; flex-direction: column; align-items: center; gap: 6px;
  padding: 12px 4px; border: none; border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-primary); box-shadow: var(--flare-shadow-sm);
  color: var(--flare-color-text-secondary); font-size: 13px; font-weight: 500; cursor: pointer;
  transition: transform var(--flare-transition-fast), filter var(--flare-transition-fast);
}
/* 判据用组件自己算出来的 is-single,不用 :has() —— 那个选择器要 Firefox 121,
   而这个包承诺 113,在 113 上整条规则被静默丢掉,按钮就又变回两种高度。
   只有一个动作时它不是「一排格子里的一格」,而是这一页的主按钮:摆成一行(图标在字左边),
   高度与下面 举报此人 / 加入黑名单 / 删除好友 一致。原来它是 343x69 的一块带光晕的紫色板,
   底下每一块都是 47 —— 一页里同一种「整宽按钮」出现两种高度。 */
.flare-contact-detail__actions.is-single button {
  flex-direction: row;
  gap: var(--flare-size-spacing-sm);
  min-height: 47px;
  padding: 0 var(--flare-size-spacing-md);
  box-shadow: none;
  font-size: var(--flare-size-font-size-lg);
}
.flare-contact-detail__actions button:disabled { opacity: 0.45; cursor: default; }
.flare-contact-detail__actions button:active { transform: scale(0.97); }
.flare-contact-detail__actions button.is-primary {
  color: #fff; background: var(--flare-component-brand-primary);
  box-shadow: 0 8px 20px -8px color-mix(in srgb, var(--flare-color-primary) 60%, transparent);
}
.flare-contact-detail__actions.is-single button.is-primary { box-shadow: none; }

.flare-contact-detail__card { margin-top: 8px; }

/* Host actions sit above the kit's own destructive pair, in the same column shape. */
.flare-contact-detail__extra { display: flex; flex-direction: column; gap: var(--flare-size-spacing-2sm); padding: 16px 16px 0; }
/* 下内距原本交给紧跟其后的 __foot(它自己 padding:16px)。但 __foot 只在能拉黑/删好友时才有 ——
   陌生人或待处理的申请就没有,这时 __extra 是最后一块,0 的下内距让宿主接在后面的那一排
   (接受 / 拒绝 / 加入黑名单)直接贴上来,两块之间一条缝都没有。 */
.flare-contact-detail__extra:last-child { padding-block-end: var(--flare-size-spacing-md); }
.flare-contact-detail__extra button {
  width: 100%; padding: 12px; border-radius: var(--flare-size-radius-lg);
  border: 1px solid var(--flare-color-border-primary); background: var(--flare-color-bg-primary);
  color: var(--flare-color-text-primary); font-size: 15px; font-weight: 500; cursor: pointer;
  transition: filter var(--flare-transition-fast);
}
.flare-contact-detail__extra button:active { filter: brightness(0.97); }
.flare-contact-detail__extra button.is-danger { color: var(--flare-color-error-text); }
.flare-contact-detail__foot { display: flex; flex-direction: column; gap: var(--flare-size-spacing-2sm); padding: 16px; }
.flare-contact-detail__foot button {
  width: 100%; padding: 12px; border-radius: var(--flare-size-radius-lg);
  border: 1px solid var(--flare-color-border-primary); background: var(--flare-color-bg-primary);
  color: var(--flare-color-text-primary); font-size: 15px; font-weight: 500; cursor: pointer;
  transition: filter var(--flare-transition-fast);
}
.flare-contact-detail__foot button:active { filter: brightness(0.97); }
.flare-contact-detail__foot button.is-danger {
  border: none; color: #fff; background: var(--flare-color-error);
}
</style>
