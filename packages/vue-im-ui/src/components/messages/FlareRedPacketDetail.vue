<script setup lang="ts">
// 红包详情 —— 普通页面的正文,不是浮层:宿主把它放进导航栈,外面套 FlareScreen。
// 顶部红色弧形头图、发送人与种类角标、祝福语,然后按查看者角色(viewerRole)画服务端给出的东西
// (spec/red-packet-vectors.json → detail):本人金额(大字)与「已存入钱包」、来晚或非指定人的标题、
// 摘要行(只有发送人拿得到总额)、领取记录(claimsListed 时)、发送人的退回说明。没有的金额绝不显示;
// 金额按 currencyExponent 用整数运算格式化;「手气最佳」由服务端判定,这里只画标记。
import { NIcon } from "naive-ui";
import { computed, getCurrentInstance } from "vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareIcon from "../general/FlareIcon.vue";
import RedPacketArch from "./RedPacketArch.vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import {
  flareRedPacketCardBadge,
  flareRedPacketClaimTexts,
  flareRedPacketDetailTexts,
  type FlareRedPacketClaim,
  type FlareRedPacketDetailStrings,
  type FlareRedPacketDetailsView,
} from "../../shared/contracts/red-packet";
import { flareIcons } from "../../shared/icons";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { flareServerNowMs } from "../../shared/server-clock";

const props = withDefaults(
  defineProps<{
    /** The IM message's sender (never the payload's). */
    senderName: string;
    senderAvatar?: string;
    /** The plugin's details result for this viewer; absent amounts are never drawn. */
    details: FlareRedPacketDetailsView;
    /** Exclusive packets: the designated member's name for "仅 某某 可领取". */
    designatedName?: string;
    /** Claim rows (names and avatars from the host's directory); drawn only when details.claimsListed. */
    claims?: ReadonlyArray<FlareRedPacketClaim>;
    /** Title of the title bar drawn when the host listens to `back`; defaults to "红包详情". */
    title?: string;
    /** The clock the times are written against; defaults to now. */
    nowMs?: number;
  }>(),
  { senderAvatar: undefined, designatedName: undefined, claims: () => [], title: undefined, nowMs: undefined },
);
// With a `back` listener the page draws its own neutral title bar (back key and title), running into the
// arched header and up under the status bar; the host then hides its own navigation bar.
// With a `deposited` listener the "saved to your wallet" note is a row that opens the wallet (§4.6).
const emit = defineEmits<{ (e: "back"): void; (e: "deposited"): void }>();

const { t } = useFlareI18nOptional();
const instance = getCurrentInstance();
const showsBar = computed(() => Boolean(instance?.vnode.props?.onBack));
const opensWallet = computed(() => Boolean(instance?.vnode.props?.onDeposited));
const barTitle = computed(() => props.title || t("redPacket.detailTitle"));
const heading = computed(() => t("redPacket.fromSender", { name: props.senderName }));
const badge = computed(() => flareRedPacketCardBadge(props.details.kind));
const strings = computed<FlareRedPacketDetailStrings>(() => ({
  summarySender: t("redPacket.summarySender"),
  summaryCompleted: t("redPacket.summaryCompleted"),
  summaryCount: t("redPacket.summaryCount"),
  refundAt: t("redPacket.refundAt"),
  refundedNote: t("redPacket.refundedNote"),
  missed: t("redPacket.missed"),
  expired: t("redPacket.expiredNotice"),
  notEligible: t("redPacket.notEligible"),
  notEligibleName: t("redPacket.notEligibleName"),
  durationSeconds: t("redPacket.duration.seconds"),
  durationMinutes: t("redPacket.duration.minutes"),
  durationHours: t("redPacket.duration.hours"),
  durationDays: t("redPacket.duration.days"),
  dateTime: t("pluginView.dateTime"),
  dateTimeYear: t("pluginView.dateTimeYear"),
}));
const now = computed(() => props.nowMs ?? flareServerNowMs());
const texts = computed(() => flareRedPacketDetailTexts(props.details, { designatedName: props.designatedName, nowMs: now.value }, strings.value));
const rows = computed(() => (texts.value.claims ? props.claims : []).map((claim) => ({
  claim,
  ...flareRedPacketClaimTexts(claim, props.details.currency, props.details.currencyExponent, now.value, strings.value),
})));
</script>

<template>
  <section class="flare-rp-detail" :class="{ 'has-bar': showsBar }" :aria-label="heading" :data-viewer-role="details.viewerRole">
    <header v-if="showsBar" class="flare-rp-detail__bar">
      <FlareIconButton
        class="flare-rp-detail__back"
        :icon="flareIcons.back"
        :ariaLabel="t('common.back')"
        tint="var(--flare-color-text-primary)"
        background="transparent"
        @click="emit('back')"
      />
      <h1 class="flare-rp-detail__bar-title">{{ barTitle }}</h1>
      <span class="flare-rp-detail__bar-spacer" aria-hidden="true" />
    </header>
    <RedPacketArch />
    <header class="flare-rp-detail__head">
      <div class="flare-rp-detail__sender">
        <FlareAvatar :name="senderName" :avatar-url="senderAvatar" />
        <h2 class="flare-rp-detail__title">{{ heading }}</h2>
        <span v-if="badge.badge" class="flare-rp-detail__kind" data-detail-badge="true">{{ t(`redPacket.badge.${badge.badge}`) }}</span>
      </div>
      <p class="flare-rp-detail__blessing">{{ details.greeting }}</p>
      <p v-if="texts.headline" class="flare-rp-detail__headline" data-detail-headline="true">{{ texts.headline }}</p>
      <div v-if="texts.amount" class="flare-rp-detail__settlement">
        <p class="flare-rp-detail__amount" data-detail-amount="true">{{ texts.amount }}</p>
        <button v-if="opensWallet" type="button" class="flare-rp-detail__amount-note is-link" data-detail-deposited="true" @click="emit('deposited')">
          <FlareIcon name="success" size="sm" aria-hidden="true" /><span>{{ t("redPacket.deposited") }}</span><FlareIcon name="chevron-right" size="sm" aria-hidden="true" />
        </button>
        <p v-else class="flare-rp-detail__amount-note"><FlareIcon name="success" size="sm" aria-hidden="true" /><span>{{ t("redPacket.deposited") }}</span></p>
      </div>
    </header>

    <div v-if="texts.summary || texts.claims" class="flare-rp-detail__claims">
      <p v-if="texts.summary" class="flare-rp-detail__summary" data-detail-summary="true">{{ texts.summary }}</p>
      <template v-if="texts.claims">
        <ul v-if="rows.length" class="flare-rp-detail__list" :aria-label="t('redPacket.claims')">
          <li v-for="row in rows" :key="row.claim.id" class="flare-rp-detail__row" :class="{ 'is-best': row.claim.best }" data-detail-claim="true">
            <FlareAvatar :user-id="row.claim.id" :name="row.claim.name" :avatar-url="row.claim.avatar" />
            <span class="flare-rp-detail__who">
              <span class="flare-rp-detail__name">{{ row.claim.name }}</span>
              <span class="flare-rp-detail__time">{{ row.time }}</span>
            </span>
            <span class="flare-rp-detail__share">
              <span v-if="row.amount" class="flare-rp-detail__share-amount">{{ row.amount }}</span>
              <span v-if="row.claim.best" class="flare-rp-detail__best">
                <n-icon size="var(--flare-size-font-size-sm)" aria-hidden="true" :component="flareIcons.star" />
                <span>{{ t("redPacket.bestLuck") }}</span>
              </span>
            </span>
          </li>
        </ul>
        <p v-else class="flare-rp-detail__empty">{{ t("redPacket.noClaims") }}</p>
      </template>
    </div>

    <p v-if="texts.note" class="flare-rp-detail__note" data-detail-note="true">{{ texts.note }}</p>
  </section>
</template>

<style scoped>
/* PC: the content column stays at the detail pane width, centred; the arch follows the column (R-08). */
.flare-rp-detail {
  display: flex;
  flex-direction: column;
  width: 100%;
  max-width: var(--flare-size-layout-detail-pane-max-width);
  margin-inline: auto;
  box-sizing: border-box;
  min-width: 0;
  color: var(--flare-color-text-primary);
  background: var(--flare-color-bg-primary);
  border-radius: var(--flare-size-radius-card);
  overflow: hidden;
}
.flare-rp-detail__bar {
  display: grid;
  grid-template-columns: var(--flare-size-layout-touch-target) minmax(0, 1fr) var(--flare-size-layout-touch-target);
  align-items: center;
  min-height: var(--flare-size-layout-header-height);
  padding: env(safe-area-inset-top, 0px) var(--flare-size-spacing-xs) 0;
  box-sizing: content-box;
  background: var(--flare-color-bg-primary);
  color: var(--flare-color-text-primary);
}
.flare-rp-detail__back { justify-self: center; }
.flare-rp-detail__bar-title {
  margin: 0;
  min-width: 0;
  text-align: center;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: var(--flare-size-font-size-2xl);
  font-weight: var(--flare-size-font-weight-semibold);
}
.flare-rp-detail__head {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  padding: var(--flare-size-spacing-lg);
  text-align: center;
}
/* §4.6: the avatar sits above the title, centred; the blessing follows under the block. */
.flare-rp-detail__sender {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  max-width: 100%;
  min-width: 0;
}
/* FlareAvatar takes a number: the sender's 56 comes from the token, as the call stage does. */
.flare-rp-detail__sender :deep(.im-avatar) {
  width: var(--flare-size-component-red-packet-detail-avatar-size) !important;
  height: var(--flare-size-component-red-packet-detail-avatar-size) !important;
  --avatar-size: var(--flare-size-component-red-packet-detail-avatar-size) !important;
}
.flare-rp-detail__title {
  margin: 0;
  min-width: 0;
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: var(--flare-size-font-size-2xl);
  font-weight: var(--flare-size-font-weight-semibold);
}
.flare-rp-detail__kind {
  flex: 0 0 auto;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: var(--flare-size-icon-size-md);
  height: var(--flare-size-icon-size-md);
  padding: 0 var(--flare-size-spacing-xs);
  box-sizing: border-box;
  border-radius: var(--flare-size-radius-xs);
  font-size: var(--flare-size-font-size-xs);
  font-weight: var(--flare-size-font-weight-semibold);
  color: var(--flare-color-text-secondary);
  background: var(--flare-color-bg-secondary);
}
.flare-rp-detail__blessing {
  margin: 0;
  font-size: var(--flare-size-font-size-lg);
  color: var(--flare-color-text-secondary);
  overflow-wrap: anywhere;
}
.flare-rp-detail__headline {
  margin: var(--flare-size-spacing-md) 0 0;
  font-size: var(--flare-size-font-size-xl);
  font-weight: var(--flare-size-font-weight-medium);
  color: var(--flare-color-text-primary);
  overflow-wrap: anywhere;
}
.flare-rp-detail__settlement { display: flex; flex-direction: column; align-items: center; gap: var(--flare-size-spacing-sm); margin-top: var(--flare-size-spacing-md); max-width: 100%; }
.flare-rp-detail__amount {
  margin: 0;
  font-size: var(--flare-size-component-red-packet-detail-amount-font-size);
  line-height: var(--flare-size-line-height-tight);
  font-weight: var(--flare-size-font-weight-semibold);
  font-variant-numeric: tabular-nums;
  overflow-wrap: anywhere;
}
.flare-rp-detail__amount-note {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
  margin: 0;
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-success-text);
}
.flare-rp-detail__amount-note.is-link {
  min-height: var(--flare-size-layout-touch-target);
  padding: 0 var(--flare-size-spacing-sm);
  border: 0;
  border-radius: var(--flare-size-radius-md);
  background: transparent;
  font: inherit;
  font-size: var(--flare-size-font-size-md);
  cursor: pointer;
}
.flare-rp-detail__amount-note.is-link:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
@media (hover: hover) {
  .flare-rp-detail__amount-note.is-link:hover { background: var(--flare-color-bg-hover); }
}
.flare-rp-detail__claims {
  border-top: 1px solid var(--flare-color-border-primary);
}
.flare-rp-detail__summary {
  margin: 0;
  padding: var(--flare-size-spacing-md) var(--flare-size-spacing-lg);
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-text-secondary);
  background: var(--flare-color-bg-secondary);
  border-bottom: 1px solid var(--flare-color-border-secondary);
}
.flare-rp-detail__list { list-style: none; margin: 0; padding: 0; }
.flare-rp-detail__row {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr) minmax(0, 1fr);
  align-items: center;
  gap: var(--flare-size-spacing-md);
  min-height: var(--flare-size-component-red-packet-claim-row-height);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg);
  box-sizing: border-box;
  border-bottom: 1px solid var(--flare-color-border-secondary);
}
.flare-rp-detail__row:last-child { border-bottom: none; }
/* Claim rows draw the 40 message avatar (FlareAvatar takes a number; the size comes from the token). */
.flare-rp-detail__row :deep(.im-avatar) {
  width: var(--flare-size-component-message-avatar-size) !important;
  height: var(--flare-size-component-message-avatar-size) !important;
  --avatar-size: var(--flare-size-component-message-avatar-size) !important;
}
.flare-rp-detail__who { display: flex; flex-direction: column; gap: var(--flare-size-spacing-3xs); min-width: 0; }
.flare-rp-detail__name {
  font-size: var(--flare-size-font-size-xl);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-rp-detail__time { font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-tertiary); }
.flare-rp-detail__share { display: flex; flex-direction: column; align-items: flex-end; gap: var(--flare-size-spacing-3xs); min-width: 0; max-width: 100%; text-align: end; }
/* §4.6: the claimed share 16/600. */
.flare-rp-detail__share-amount {
  font-size: var(--flare-size-font-size-2xl);
  font-weight: var(--flare-size-font-weight-semibold);
  font-variant-numeric: tabular-nums;
  overflow-wrap: anywhere;
}
.flare-rp-detail__best {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-3xs);
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-warning-text);
  flex-wrap: wrap;
  justify-content: flex-end;
}
/* §4.6: the best-luck star 12 in warning, beside its 12 label. */
.flare-rp-detail__best :deep(svg) { color: var(--flare-color-warning-text); }
.flare-rp-detail__empty,
.flare-rp-detail__note {
  margin: 0;
  padding: var(--flare-size-spacing-xl) var(--flare-size-spacing-lg);
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-text-tertiary);
  text-align: center;
}
.flare-rp-detail__note { padding-top: var(--flare-size-spacing-lg); }
</style>
