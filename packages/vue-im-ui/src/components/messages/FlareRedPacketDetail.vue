<script setup lang="ts">
// 红包详情 —— 普通页面的正文,不是浮层:宿主把它放进导航栈,外面套 FlareScreen。
// 顶部红色弧形头图、发送人与种类标签、祝福语、本人领取金额(大字)、汇总行和领取列表。
// 金额、时间、名字都由宿主格式化;「手气最佳」由服务端判定,这里只画标记。
import { NIcon } from "naive-ui";
import { computed, getCurrentInstance } from "vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import type { FlareRedPacketClaim } from "../../shared/contracts/red-packet";
import { flareIcons } from "../../shared/icons";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    senderName: string;
    senderAvatar?: string;
    blessing: string;
    /** Short kind badge beside the sender, e.g. "拼". */
    kindLabel?: string;
    /** What the viewer received, drawn large (host formats it, e.g. "0.88 元"). */
    amount?: string;
    /** Line under the amount, e.g. "已存入钱包". */
    amountNote?: string;
    /** Progress line above the list, e.g. "已领取 3/5 个，共 2.10/5.00 元". */
    summary: string;
    claims?: ReadonlyArray<FlareRedPacketClaim>;
    /** Closing explanation, e.g. a refund notice after expiry. */
    note?: string;
    /** Title of the red bar drawn when the host listens to `back`; defaults to "红包详情". */
    title?: string;
  }>(),
  { claims: () => [] },
);
// With a `back` listener the page draws its own red title bar (back key and title), running into the
// arched header and up under the status bar; the host then hides its own navigation bar.
const emit = defineEmits<{ (e: "back"): void }>();

const { t } = useFlareI18nOptional();
const instance = getCurrentInstance();
const showsBar = computed(() => Boolean(instance?.vnode.props?.onBack));
const barTitle = computed(() => props.title || t("redPacket.detailTitle"));
const heading = computed(() => t("redPacket.fromSender", { name: props.senderName }));
</script>

<template>
  <section class="flare-rp-detail" :class="{ 'has-bar': showsBar }" :aria-label="heading">
    <header v-if="showsBar" class="flare-rp-detail__bar">
      <FlareIconButton
        class="flare-rp-detail__back"
        :icon="flareIcons.back"
        :ariaLabel="t('common.back')"
        tint="#fff"
        background="transparent"
        @click="emit('back')"
      />
      <h1 class="flare-rp-detail__bar-title">{{ barTitle }}</h1>
      <span class="flare-rp-detail__bar-spacer" aria-hidden="true" />
    </header>
    <div class="flare-rp-detail__hero" aria-hidden="true" />
    <header class="flare-rp-detail__head">
      <div class="flare-rp-detail__sender">
        <FlareAvatar :name="senderName" :avatar-url="senderAvatar" :size="28" />
        <h2 class="flare-rp-detail__title">{{ heading }}</h2>
        <span v-if="kindLabel" class="flare-rp-detail__kind">{{ kindLabel }}</span>
      </div>
      <p class="flare-rp-detail__blessing">{{ blessing }}</p>
      <p v-if="amount" class="flare-rp-detail__amount">{{ amount }}</p>
      <p v-if="amountNote" class="flare-rp-detail__amount-note">{{ amountNote }}</p>
    </header>

    <div class="flare-rp-detail__claims">
      <p class="flare-rp-detail__summary">{{ summary }}</p>
      <ul v-if="claims.length" class="flare-rp-detail__list" :aria-label="t('redPacket.claims')">
        <li v-for="claim in claims" :key="claim.id" class="flare-rp-detail__row" :class="{ 'is-best': claim.best }">
          <FlareAvatar :user-id="claim.id" :name="claim.name" :avatar-url="claim.avatar" :size="40" />
          <span class="flare-rp-detail__who">
            <span class="flare-rp-detail__name">{{ claim.name }}</span>
            <span class="flare-rp-detail__time">{{ claim.time }}</span>
          </span>
          <span class="flare-rp-detail__share">
            <span class="flare-rp-detail__share-amount">{{ claim.amount }}</span>
            <span v-if="claim.best" class="flare-rp-detail__best">
              <n-icon aria-hidden="true" :component="flareIcons.star" />
              <span>{{ t("redPacket.bestLuck") }}</span>
            </span>
          </span>
        </li>
      </ul>
      <p v-else class="flare-rp-detail__empty">{{ t("redPacket.noClaims") }}</p>
    </div>

    <p v-if="note" class="flare-rp-detail__note">{{ note }}</p>
  </section>
</template>

<style scoped>
.flare-rp-detail {
  display: flex;
  flex-direction: column;
  min-width: 0;
  color: var(--flare-color-text-primary);
  background: var(--flare-color-bg-primary);
}
/* The red header: a band that bows out at the bottom, the way the envelope's flap does. */
.flare-rp-detail__hero {
  height: var(--flare-size-component-red-packet-detail-header-height);
  background: linear-gradient(180deg, var(--flare-color-red-packet-middle), var(--flare-color-red-packet-start));
  border-radius: 0 0 50% 50% / 0 0 var(--flare-size-spacing-2xl) var(--flare-size-spacing-2xl);
}
/* The page's own title bar: the deep red keeps the light title and back key above 4.5:1, and the arched
   header below starts from the same red, so bar and arch read as one piece reaching up under the
   status bar. */
.flare-rp-detail__bar {
  display: grid;
  grid-template-columns: var(--flare-size-layout-touch-target) minmax(0, 1fr) var(--flare-size-layout-touch-target);
  align-items: center;
  min-height: var(--flare-size-layout-header-height);
  padding: env(safe-area-inset-top, 0px) var(--flare-size-spacing-xs) 0;
  box-sizing: content-box;
  background: var(--flare-color-red-packet-end);
  color: #fff;
}
.flare-rp-detail.has-bar .flare-rp-detail__hero {
  /* Overlap the bar by a hairline: at a fractional offset the page behind would show through the seam. */
  margin-top: -1px;
  background: linear-gradient(180deg, var(--flare-color-red-packet-end), var(--flare-color-red-packet-middle));
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
  padding: var(--flare-size-spacing-2xl) var(--flare-size-spacing-xl) var(--flare-size-spacing-xl);
  text-align: center;
}
.flare-rp-detail__sender {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  max-width: 100%;
  min-width: 0;
}
.flare-rp-detail__title {
  margin: 0;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: var(--flare-size-font-size-3xl);
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
  color: var(--flare-color-red-packet-end);
  background: var(--flare-color-red-packet-gold);
}
.flare-rp-detail__blessing {
  margin: 0;
  font-size: var(--flare-size-font-size-lg);
  color: var(--flare-color-text-secondary);
  overflow-wrap: anywhere;
}
.flare-rp-detail__amount {
  margin: var(--flare-size-spacing-md) 0 0;
  font-size: var(--flare-size-component-red-packet-amount-font-size);
  line-height: var(--flare-size-line-height-tight);
  font-weight: var(--flare-size-font-weight-semibold);
  font-variant-numeric: tabular-nums;
  overflow-wrap: anywhere;
}
.flare-rp-detail__amount-note {
  margin: 0;
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-warning-text);
}
.flare-rp-detail__claims {
  border-top: 1px solid var(--flare-color-border-primary);
}
.flare-rp-detail__summary {
  margin: 0;
  padding: var(--flare-size-spacing-md) var(--flare-size-spacing-lg);
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-text-tertiary);
  border-bottom: 1px solid var(--flare-color-border-primary);
}
.flare-rp-detail__list { list-style: none; margin: 0; padding: 0; }
.flare-rp-detail__row {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr) auto;
  align-items: center;
  gap: var(--flare-size-spacing-md);
  min-height: var(--flare-size-layout-session-item-height);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg);
  box-sizing: border-box;
  border-bottom: 1px solid var(--flare-color-border-secondary);
}
.flare-rp-detail__who { display: flex; flex-direction: column; gap: var(--flare-size-spacing-3xs); min-width: 0; }
.flare-rp-detail__name {
  font-size: var(--flare-size-font-size-xl);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-rp-detail__time { font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-tertiary); }
.flare-rp-detail__share { display: flex; flex-direction: column; align-items: flex-end; gap: var(--flare-size-spacing-3xs); }
.flare-rp-detail__share-amount {
  font-size: var(--flare-size-font-size-xl);
  font-weight: var(--flare-size-font-weight-medium);
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}
.flare-rp-detail__best {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-3xs);
  font-size: var(--flare-size-font-size-xs);
  color: var(--flare-color-warning-text);
  white-space: nowrap;
}
.flare-rp-detail__best :deep(svg) { color: var(--flare-color-red-packet-gold-deep); }
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
