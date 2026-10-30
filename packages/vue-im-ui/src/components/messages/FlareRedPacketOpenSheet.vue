<script setup lang="ts">
// 开红包浮层 —— 遮罩上居中的红色信封:弧形封盖、发送人、祝福语、封盖接缝上的金色「開」。
//
// 它只画:能不能领、领到多少由插件服务端决定,宿主把结论换成 `state` 传进来。`open` 是可见性
// (与 FlareModal 同名同义),`@open` 是点了「開」—— 宿主据此调 claim 并把 state 置为 opening。
// 滚动锁、焦点陷阱、Escape、平台返回键与传送目标来自 useFlareModalSurface,与其它模态面共用一个栈。
//
// DOM 契约:面上有 role="dialog"、aria-modal、aria-label(「X的红包」)与 data-flare-presentation="dialog";
// 遮罩带共用类 `flare-overlay-scrim`。关闭键在信封下方,但仍在面内,Tab 够得着它。
import { NIcon } from "naive-ui";
import { computed, getCurrentInstance, ref } from "vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import { flareRedPacketOpenSheetKeys, type FlareRedPacketOpenState } from "../../shared/contracts/red-packet";
import { flareIcons } from "../../shared/icons";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { useFlareModalSurface } from "../../shared/useModalSurface";

const props = withDefaults(
  defineProps<{
    /** Whether the sheet is shown. */
    open: boolean;
    senderName: string;
    senderAvatar?: string;
    blessing: string;
    /** Packet kind under the sender, e.g. "拼手气红包". */
    kindLabel?: string;
    /**
     * `ready` offers 開; `opening` flips it while the host claims; the others say why nothing opens (`refunded` for
     * PACKET_REFUNDED or the public status refunded — not `expired`).
     */
    state?: FlareRedPacketOpenState;
    /** Host notice that replaces the default copy of a non-ready state, e.g. "仅 TA 可领取". */
    message?: string;
    /**
     * From the viewer's personal layer: a finished, expired or refunded sheet offers the details key only when true. A
     * notEligible sheet never offers it — the server returns nothing to a non-designated viewer.
     */
    canViewDetails?: boolean;
  }>(),
  { state: "ready", canViewDetails: true },
);
const emit = defineEmits<{
  (e: "open"): void;
  (e: "viewDetails"): void;
  (e: "close"): void;
}>();

const { t } = useFlareI18nOptional();
const instance = getCurrentInstance();
const surfaceEl = ref<HTMLElement | null>(null);

const title = computed(() => t("redPacket.fromSender", { name: props.senderName }));
const opening = computed(() => props.state === "opening");
// 開 stays on the face while it can still be pressed (ready), is being pressed (opening) or can be
// pressed again after a failed attempt (error).
const keys = computed(() => flareRedPacketOpenSheetKeys(props.state, props.canViewDetails));
const showsCoin = computed(() => keys.value.coin);
const showsDetails = computed(() => keys.value.details);
const headline = computed(() => {
  switch (props.state) {
    case "finished":
      return props.message || t("redPacket.missed");
    case "expired":
      return props.message || t("redPacket.expiredNotice");
    case "refunded":
      return props.message || t("redPacket.refundedNotice");
    case "notEligible":
      return props.message || t("redPacket.notEligible");
    default:
      return props.blessing;
  }
});
const coinLabel = computed(() => t("redPacket.openAction"));
// One ideograph fills the coin; a word ("Open") is set smaller so it stays inside it.
const coinWord = computed(() => coinLabel.value.length > 2);

function requestClose(): void {
  emit("close");
}
function pressCoin(): void {
  if (props.state !== "opening") emit("open");
}

// 平台返回键只在宿主真的接了 close 时才接管。
const { overlayContainer } = useFlareModalSurface({
  open: () => props.open,
  surface: surfaceEl,
  nativeBack: () => Boolean(instance?.vnode.props?.onClose),
  onRequestClose: requestClose,
});
</script>

<template>
  <Teleport :to="overlayContainer">
    <transition name="flare-rp-open-fade">
      <div v-if="open" class="flare-overlay-scrim flare-rp-open-scrim" @click="requestClose">
        <div
          ref="surfaceEl"
          class="flare-rp-open"
          :class="`is-${state}`"
          role="dialog"
          aria-modal="true"
          :aria-label="title"
          :aria-busy="opening || undefined"
          tabindex="-1"
          data-flare-presentation="dialog"
          :data-state="state"
          @click.stop
        >
          <div class="flare-rp-open__envelope">
            <div class="flare-rp-open__cover">
              <div class="flare-rp-open__sender">
                <FlareAvatar :name="senderName" :avatar-url="senderAvatar" :size="28" />
                <span class="flare-rp-open__sender-name">{{ title }}</span>
              </div>
              <span v-if="kindLabel" class="flare-rp-open__kind">{{ kindLabel }}</span>
              <p class="flare-rp-open__headline" :class="{ 'is-notice': state === 'notEligible' }" aria-live="polite">{{ headline }}</p>
              <p v-if="state === 'error'" class="flare-rp-open__error" role="alert">{{ message || t("redPacket.openFailed") }}</p>
            </div>
            <button
              v-if="showsCoin"
              type="button"
              class="flare-rp-open__coin"
              :class="{ 'is-word': coinWord }"
              :disabled="opening"
              :aria-busy="opening"
              :aria-label="opening ? t('redPacket.busy') : coinLabel"
              @click="pressCoin"
            >
              <span class="flare-rp-open__coin-glyph" aria-hidden="true">{{ coinLabel }}</span>
              <span class="flare-rp-open__coin-busy" aria-hidden="true">{{ t("redPacket.busy") }}</span>
            </button>
            <div class="flare-rp-open__foot">
              <button v-if="showsDetails" type="button" class="flare-rp-open__details" @click="emit('viewDetails')">
                <span>{{ t("redPacket.viewDetails") }}</span>
                <n-icon aria-hidden="true" :component="flareIcons['chevron-right']" />
              </button>
            </div>
          </div>
          <FlareIconButton
            class="flare-rp-open__close"
            :icon="flareIcons.close"
            :ariaLabel="t('common.close')"
            tint="var(--flare-color-red-packet-gold)"
            background="color-mix(in srgb, var(--flare-color-red-packet-end) 40%, transparent)"
            @click="requestClose"
          />
        </div>
      </div>
    </transition>
  </Teleport>
</template>

<style scoped>
.flare-rp-open-scrim {
  position: fixed;
  inset: 0;
  z-index: var(--flare-z-index-modal);
  display: flex;
  align-items: center;
  justify-content: center;
  box-sizing: border-box;
  padding: var(--flare-size-spacing-xl) var(--flare-size-spacing-lg);
  background: var(--flare-color-scrim);
  overflow-y: auto;
}
/* The dialog is the envelope plus the close key under it: both stay inside the focus trap. */
.flare-rp-open {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--flare-size-spacing-xl);
  width: min(var(--flare-size-component-red-packet-envelope-width), 100%);
  margin: auto;
  outline: none;
}
.flare-rp-open__envelope {
  --coin: var(--flare-size-component-red-packet-open-button-size);
  position: relative;
  box-sizing: border-box;
  width: 100%;
  min-height: var(--flare-size-component-red-packet-envelope-min-height);
  display: flex;
  flex-direction: column;
  border-radius: var(--flare-size-radius-xl);
  overflow: hidden;
  color: var(--flare-color-red-packet-on-surface);
  background: var(--flare-color-red-packet-end);
  box-shadow: var(--flare-shadow-xl);
}
/* The flap: a shallow ellipse over the pocket. Deeper red at the top, where the small sender line sits,
   so white keeps its contrast; the blessing below is large text in gold. */
.flare-rp-open__cover {
  flex: 1 1 auto;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: var(--flare-size-spacing-md);
  box-sizing: border-box;
  padding: var(--flare-size-spacing-2xl) var(--flare-size-spacing-2xl) calc(var(--coin) / 2 + var(--flare-size-spacing-lg));
  text-align: center;
  background: linear-gradient(180deg, var(--flare-color-red-packet-end) 0%, var(--flare-color-red-packet-middle) 100%);
  border-radius: 0 0 50% 50% / 0 0 var(--flare-size-spacing-2xl) var(--flare-size-spacing-2xl);
  box-shadow: 0 3px 8px color-mix(in srgb, #000 22%, transparent);
  z-index: 1;
}
.flare-rp-open__sender {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  max-width: 100%;
  min-width: 0;
}
.flare-rp-open__sender-name {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: var(--flare-size-font-size-2xl);
  font-weight: var(--flare-size-font-weight-semibold);
  color: #fff;
}
.flare-rp-open__kind {
  padding: var(--flare-size-spacing-3xs) var(--flare-size-spacing-sm);
  border-radius: var(--flare-size-radius-full);
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-red-packet-gold);
  background: color-mix(in srgb, #000 16%, transparent);
}
.flare-rp-open__headline {
  margin: var(--flare-size-spacing-sm) 0 0;
  font-size: var(--flare-size-font-size-5xl);
  line-height: var(--flare-size-line-height-snug);
  font-weight: var(--flare-size-font-weight-semibold);
  color: var(--flare-color-red-packet-gold);
  overflow-wrap: anywhere;
}
.flare-rp-open__error {
  margin: 0;
  font-size: var(--flare-size-font-size-lg);
  color: #fff;
}
/* A host notice (not eligible, a failed claim) can run long: body line spacing, at most three lines. */
.flare-rp-open__headline.is-notice,
.flare-rp-open__error {
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 3;
  line-clamp: 3;
  overflow: hidden;
  line-height: var(--flare-size-line-height-normal);
}
/* The coin sits on the seam: pulled up by half its size so its centre lands on the flap's edge. */
.flare-rp-open__coin {
  position: relative;
  z-index: 2;
  flex: 0 0 auto;
  align-self: center;
  width: var(--coin);
  height: var(--coin);
  margin-top: calc(var(--coin) / -2);
  padding: 0;
  border: none;
  border-radius: 50%;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: var(--flare-color-red-packet-end);
  background: radial-gradient(circle at 50% 36%, var(--flare-color-red-packet-gold) 0%, var(--flare-color-red-packet-gold-deep) 78%);
  box-shadow: 0 6px 16px color-mix(in srgb, #000 28%, transparent),
    inset 0 0 0 3px color-mix(in srgb, var(--flare-color-red-packet-gold) 70%, transparent);
  transition: transform var(--flare-transition-fast);
}
.flare-rp-open__coin:hover:not(:disabled) { transform: scale(1.04); }
.flare-rp-open__coin:active:not(:disabled) { transform: scale(0.96); }
.flare-rp-open__coin:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 4px; }
.flare-rp-open__coin:disabled { cursor: default; }
.flare-rp-open__coin-glyph {
  font-size: calc(var(--coin) * 0.42);
  font-weight: var(--flare-size-font-weight-bold);
  line-height: 1;
}
.flare-rp-open__coin.is-word .flare-rp-open__coin-glyph { font-size: var(--flare-size-font-size-3xl); }
.flare-rp-open__coin-busy { display: none; font-size: var(--flare-size-font-size-sm); font-weight: var(--flare-size-font-weight-semibold); }
/* Opening: the coin turns on its vertical axis until the host settles the state. */
.is-opening .flare-rp-open__coin { animation: flare-rp-coin-flip 0.9s linear infinite; }
@keyframes flare-rp-coin-flip {
  from { transform: perspective(600px) rotateY(0deg); }
  to { transform: perspective(600px) rotateY(360deg); }
}
.flare-rp-open__foot {
  flex: 0 0 auto;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: calc(var(--flare-size-component-red-packet-envelope-min-height) * 0.28);
  padding: var(--flare-size-spacing-lg);
  box-sizing: border-box;
}
.flare-rp-open__details {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-3xs);
  min-height: var(--flare-size-layout-touch-target-min);
  padding: 0 var(--flare-size-spacing-md);
  border: none;
  border-radius: var(--flare-size-radius-full);
  background: transparent;
  cursor: pointer;
  font-size: var(--flare-size-font-size-lg);
  color: var(--flare-color-red-packet-gold);
}
.flare-rp-open__details:hover { background: color-mix(in srgb, #000 12%, transparent); }
.flare-rp-open__details:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }

.flare-rp-open-fade-enter-active,
.flare-rp-open-fade-leave-active { transition: opacity var(--flare-transition-normal); }
.flare-rp-open-fade-enter-from,
.flare-rp-open-fade-leave-to { opacity: 0; }
.flare-rp-open-fade-enter-active .flare-rp-open,
.flare-rp-open-fade-leave-active .flare-rp-open { transition: transform var(--flare-transition-spring); }
.flare-rp-open-fade-enter-from .flare-rp-open,
.flare-rp-open-fade-leave-to .flare-rp-open { transform: scale(0.9); }

/* Reduced motion: no flip and no pop-in — the coin says it is working in words instead. */
@media (prefers-reduced-motion: reduce) {
  .is-opening .flare-rp-open__coin { animation: none; }
  .is-opening .flare-rp-open__coin-glyph { display: none; }
  .is-opening .flare-rp-open__coin-busy { display: inline; }
  .flare-rp-open__coin { transition: none; }
  .flare-rp-open__coin:hover:not(:disabled),
  .flare-rp-open__coin:active:not(:disabled) { transform: none; }
  .flare-rp-open-fade-enter-active,
  .flare-rp-open-fade-leave-active,
  .flare-rp-open-fade-enter-active .flare-rp-open,
  .flare-rp-open-fade-leave-active .flare-rp-open { transition: none; }
}
</style>
