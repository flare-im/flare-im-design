<script setup lang="ts">
// Placeholder for an account the host cannot describe: an id that resolved to
// nothing, a deactivated account, one that is blocked, or one that is simply
// not contactable right now. Without it these rows render blank or, worse, a
// bare user id as the title. Pure display: no actions, no callbacks, no I/O.
import { computed } from "vue";
import { NIcon } from "naive-ui";
import {
  BanOutline,
  CloseCircleOutline,
  LockClosedOutline,
  PersonOutline,
} from "../../shared/icon-glyphs";
import {
  shortenUserId,
  unknownUserPresentation,
  type UnknownUserDensity,
  type UnknownUserIcon,
  type UnknownUserKind,
} from "../../shared/contracts/relation";

const props = withDefaults(
  defineProps<{
    /** The id the host failed to resolve. Diagnostic only — never the title. */
    userId: string;
    kind: UnknownUserKind;
    /** `row` inside lists, `card` on a detail surface. */
    density?: UnknownUserDensity;
    /** Host-supplied supplement, e.g. where the id came from. */
    detail?: string;
    unknownText?: string;
    deactivatedText?: string;
    blockedText?: string;
    unreachableText?: string;
    /** Prefix of the diagnostic id line. */
    idLabel?: string;
    /** Longest id rendered before middle-eliding. */
    idMaxLength?: number;
  }>(),
  {
    density: "row",
    detail: "",
    unknownText: "未知用户",
    deactivatedText: "该账号已注销",
    blockedText: "该账号已被屏蔽",
    unreachableText: "暂时无法联系该账号",
    idLabel: "ID",
    idMaxLength: 24,
  },
);

const glyphs: Record<UnknownUserIcon, unknown> = {
  unknown: PersonOutline,
  deactivated: CloseCircleOutline,
  blocked: BanOutline,
  unreachable: LockClosedOutline,
};

const presentation = computed(() => unknownUserPresentation(props.kind));
const title = computed(() => {
  switch (presentation.value.kind) {
    case "deactivated": return props.deactivatedText;
    case "blocked": return props.blockedText;
    case "unreachable": return props.unreachableText;
    default: return props.unknownText;
  }
});
const fullId = computed(() => (props.userId ?? "").trim());
const shortId = computed(() => shortenUserId(props.userId, props.idMaxLength));
// The id is diagnostic, so it is read out after the reason, never before it.
const accessibleName = computed(() =>
  [title.value, props.detail, fullId.value ? `${props.idLabel} ${fullId.value}` : ""]
    .filter(Boolean)
    .join(" · "),
);
</script>

<template>
  <div
    class="flare-unknown-user"
    :class="[`flare-unknown-user--${density}`, `flare-unknown-user--${presentation.tone}`]"
    role="group"
    :aria-label="accessibleName"
    :data-kind="presentation.kind"
  >
    <span class="flare-unknown-user__avatar" aria-hidden="true">
      <n-icon :size="density === 'card' ? 28 : 20" :component="PersonOutline as any" />
    </span>
    <div class="flare-unknown-user__body">
      <p class="flare-unknown-user__title">
        <span class="flare-unknown-user__badge" aria-hidden="true">
          <n-icon :size="14" :component="glyphs[presentation.icon] as any" />
        </span>
        <span class="flare-unknown-user__title-text">{{ title }}</span>
      </p>
      <p v-if="detail" class="flare-unknown-user__detail">{{ detail }}</p>
      <p v-if="shortId" class="flare-unknown-user__id" :title="fullId">
        <span class="flare-unknown-user__id-label">{{ idLabel }}</span>
        <bdi class="flare-unknown-user__id-value" dir="ltr">{{ shortId }}</bdi>
      </p>
    </div>
  </div>
</template>

<style scoped>
.flare-unknown-user {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-md, 12px);
  min-width: 0;
  min-height: var(--flare-size-layout-touch-target, 48px);
  color: var(--flare-color-text-primary);
}
.flare-unknown-user--card {
  flex-direction: column;
  align-items: center;
  gap: var(--flare-size-spacing-sm, 8px);
  padding: var(--flare-size-spacing-xl, 20px) var(--flare-size-spacing-lg, 16px);
  border-radius: var(--flare-size-radius-lg, 10px);
  background: var(--flare-color-bg-secondary);
  text-align: center;
}
.flare-unknown-user__avatar {
  display: grid;
  place-items: center;
  flex: none;
  width: var(--flare-size-layout-avatar-size, 44px);
  height: var(--flare-size-layout-avatar-size, 44px);
  border-radius: var(--flare-size-radius-full, 999px);
  background: var(--flare-color-bg-disabled);
  color: var(--flare-color-text-tertiary);
}
.flare-unknown-user--card .flare-unknown-user__avatar {
  width: 64px;
  height: 64px;
}
.flare-unknown-user__body {
  display: grid;
  gap: 2px;
  min-width: 0;
}
.flare-unknown-user--card .flare-unknown-user__body {
  justify-items: center;
  gap: var(--flare-size-spacing-xs, 4px);
}
.flare-unknown-user__title {
  display: flex;
  align-items: center;
  gap: 6px;
  margin: 0;
  min-width: 0;
  font-size: var(--flare-size-font-size-lg, 14px);
  font-weight: 600;
  line-height: var(--flare-size-line-height-tight, 1.2);
}
.flare-unknown-user--card .flare-unknown-user__title {
  font-size: var(--flare-size-font-size-3xl, 18px);
}
.flare-unknown-user__title-text {
  min-width: 0;
  overflow-wrap: anywhere;
}
.flare-unknown-user__badge {
  display: grid;
  place-items: center;
  flex: none;
  width: 22px;
  height: 22px;
  border-radius: var(--flare-size-radius-full, 999px);
  background: var(--flare-color-bg-disabled);
  color: var(--flare-color-text-secondary);
}
.flare-unknown-user--warning .flare-unknown-user__badge {
  color: var(--flare-color-warning);
}
.flare-unknown-user--danger .flare-unknown-user__badge {
  color: var(--flare-color-error);
}
.flare-unknown-user__detail {
  margin: 0;
  font-size: var(--flare-size-font-size-md, 13px);
  color: var(--flare-color-text-secondary);
  overflow-wrap: anywhere;
}
.flare-unknown-user__id {
  display: flex;
  align-items: baseline;
  gap: 5px;
  margin: 0;
  min-width: 0;
  font-size: var(--flare-size-font-size-sm, 12px);
  color: var(--flare-color-text-tertiary);
}
.flare-unknown-user--card .flare-unknown-user__id {
  justify-content: center;
}
.flare-unknown-user__id-label {
  flex: none;
}
.flare-unknown-user__id-value {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-variant-numeric: tabular-nums;
  unicode-bidi: isolate;
}
</style>
