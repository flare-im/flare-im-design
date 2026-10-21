<script setup lang="ts">
import { computed, useId } from "vue";
import type { FlareRedPacketState } from "../../shared/contracts/red-packet";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    /** Greeting on the packet, e.g. "恭喜发财，大吉大利". */
    blessing: string;
    /** Packet kind shown on the brand line, e.g. "拼手气红包". */
    kindLabel?: string;
    /** What the current viewer sees: saturated while unopened, dimmed once claimed, finished or expired. */
    state?: FlareRedPacketState;
    /** What the viewer received (host formats the number); shown on a claimed card. */
    amount?: string;
    disabled?: boolean;
    busy?: boolean;
    statusLabel?: string;
  }>(),
  { state: "unopened", disabled: false, busy: false },
);
const emit = defineEmits<{ (e: "open"): void }>();

const { t } = useFlareI18n();
// Finished and expired cards stay tappable: that is how the viewer reaches the claim details.
const blocked = computed(() => props.disabled || props.busy);
const dimmed = computed(() => props.state !== "unopened");
const claimedAmount = computed(() => !props.busy && props.statusLabel == null && props.state === "claimed" && Boolean(props.amount));
// The small gold envelope — the same geometry as iOS `RedPacketGlyph` and Compose `RedPacketGlyph`: 30 wide,
// 1.3 times as tall, corners 0.18 of the width, a flap 0.42 of the height whose curved edge dips 0.3 of the
// flap below its straight sides, and a seal 0.36 of the width centred on the lowest point of that edge.
const round = (value: number) => Math.round(value * 100) / 100;
const GLYPH_WIDTH = 30;
const GLYPH_HEIGHT = round(GLYPH_WIDTH * 1.3);
const glyphCorner = round(GLYPH_WIDTH * 0.18);
const glyphFlap = round(GLYPH_HEIGHT * 0.42);
const glyphFlapSide = round(glyphFlap - glyphFlap * 0.3);
// A quadratic curve through (width / 2, flap): its control point sits as far below as the sides are above.
const glyphFlapPath = `M0 0H${GLYPH_WIDTH}V${glyphFlapSide}Q${GLYPH_WIDTH / 2} ${round(glyphFlap + (glyphFlap - glyphFlapSide))} 0 ${glyphFlapSide}Z`;
const glyphSealRadius = round((GLYPH_WIDTH * 0.36) / 2);
const glyphId = `flare-red-packet-glyph-${useId()}`;

const status = computed(() => {
  if (props.busy) return t("redPacket.busy");
  if (props.statusLabel != null) return props.statusLabel;
  if (props.state === "claimed") return props.amount ? `${t("redPacket.received")} · ${props.amount}` : t("redPacket.received");
  if (props.state === "finished") return t("redPacket.finished");
  if (props.state === "expired") return t("redPacket.expired");
  return props.disabled ? t("redPacket.unavailable") : t("redPacket.tapToOpen");
});
// The button's name: the blessing and the status line, so a screen reader says what the packet is and
// what tapping it does, not just "button" (the glyph is decorative, the brand line is not news).
const accessibleName = computed(() => t("redPacket.cardLabel", { blessing: props.blessing, status: status.value }));
</script>

<template>
  <button
    type="button"
    class="flare-red-packet"
    :class="[`is-${state}`, { 'is-dimmed': dimmed }]"
    :disabled="blocked"
    :aria-busy="busy"
    :aria-label="accessibleName"
    :data-state="state"
    @click="!blocked && emit('open')"
  >
    <svg
      class="flare-red-packet__glyph"
      :viewBox="`0 0 ${GLYPH_WIDTH} ${GLYPH_HEIGHT}`"
      :width="GLYPH_WIDTH"
      :height="GLYPH_HEIGHT"
      aria-hidden="true"
      focusable="false"
    >
      <defs>
        <linearGradient :id="`${glyphId}-body`" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" class="flare-red-packet__glyph-gold" />
          <stop offset="1" class="flare-red-packet__glyph-gold-deep" />
        </linearGradient>
        <clipPath :id="`${glyphId}-clip`">
          <rect :width="GLYPH_WIDTH" :height="GLYPH_HEIGHT" :rx="glyphCorner" :ry="glyphCorner" />
        </clipPath>
      </defs>
      <g :clip-path="`url(#${glyphId}-clip)`">
        <rect :width="GLYPH_WIDTH" :height="GLYPH_HEIGHT" :fill="`url(#${glyphId}-body)`" />
        <path class="flare-red-packet__glyph-shadow" :d="glyphFlapPath" transform="translate(0 1)" />
        <path class="flare-red-packet__glyph-flap" :d="glyphFlapPath" />
        <circle class="flare-red-packet__glyph-seal" :cx="GLYPH_WIDTH / 2" :cy="glyphFlap" :r="glyphSealRadius" />
      </g>
    </svg>
    <span class="flare-red-packet__body">
      <span class="flare-red-packet__blessing">{{ blessing }}</span>
      <span class="flare-red-packet__status" :aria-live="busy ? 'polite' : 'off'">
        <template v-if="claimedAmount">{{ t("redPacket.received") }} · <b>{{ amount }}</b></template>
        <template v-else>{{ status }}</template>
      </span>
    </span>
    <span class="flare-red-packet__brand">
      <span v-if="kindLabel" class="flare-red-packet__kind">{{ kindLabel }}</span>
      <span class="flare-red-packet__brand-name">{{ t("redPacket.brand") }}</span>
    </span>
  </button>
</template>

<style scoped>
/* Every colour the card paints goes through these slots, so a spent packet is one block of overrides
   below rather than a second set of rules. */
.flare-red-packet {
  --rp-start: var(--flare-color-red-packet-start);
  --rp-middle: var(--flare-color-red-packet-middle);
  --rp-end: var(--flare-color-red-packet-end);
  --rp-gold: var(--flare-color-red-packet-gold);
  --rp-gold-deep: var(--flare-color-red-packet-gold-deep);
  --rp-text: #fff;
  --rp-status: color-mix(in srgb, var(--flare-color-red-packet-on-surface) 85%, transparent);
  --rp-amount: var(--flare-color-red-packet-gold);
  --rp-soft: color-mix(in srgb, var(--flare-color-red-packet-on-surface) 60%, transparent);
  --rp-rule: color-mix(in srgb, var(--flare-color-red-packet-on-surface) 28%, transparent);
  display: grid;
  grid-template-columns: auto minmax(0, 1fr);
  align-items: center;
  gap: var(--flare-size-spacing-md);
  width: var(--flare-size-component-red-packet-card-width);
  max-width: 100%;
  min-height: var(--flare-size-layout-touch-target);
  min-width: 0;
  box-sizing: border-box;
  padding: var(--flare-size-spacing-2md);
  border: none;
  border-radius: var(--flare-size-radius-xl);
  cursor: pointer;
  text-align: left;
  color: var(--rp-status);
  background: linear-gradient(135deg, var(--rp-start) 0%, var(--rp-middle) 52%, var(--rp-end) 100%);
  box-shadow: 0 10px 24px color-mix(in srgb, var(--flare-color-red-packet-end) 32%, transparent);
  position: relative;
  overflow: hidden;
  transition: transform var(--flare-transition-fast), filter var(--flare-transition-fast);
}
.flare-red-packet:hover:not(:disabled) { filter: brightness(1.03); }
.flare-red-packet:active:not(:disabled) { transform: scale(0.98); }
.flare-red-packet:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 3px; }
.flare-red-packet:disabled { cursor: default; }
/* Opened, emptied or expired: the same envelope, quieter — every colour mixed with fadedMixTarget by the
   shared ratio (redPacketFadedMix, spec/red-packet-vectors.json → faded), the way a spent packet reads in
   every mainstream chat. The target is white in light mode and a deep red in dark mode, so the hue stays
   and a spent packet never glows on a dark page. The words take fadedInk: white on the light face is under
   3:1, the deep ink is 4.75:1 on its darkest stop (the light dark-mode ink at least 5.5:1). It stays a
   button — tapping it shows who got what. Busy and disabled are not spent: they keep this face. */
.flare-red-packet.is-dimmed {
  --rp-mix: calc(var(--flare-size-component-red-packet-faded-mix) * 100%);
  --rp-start: color-mix(in srgb, var(--flare-color-red-packet-start), var(--flare-color-red-packet-faded-mix-target) var(--rp-mix));
  --rp-middle: color-mix(in srgb, var(--flare-color-red-packet-middle), var(--flare-color-red-packet-faded-mix-target) var(--rp-mix));
  --rp-end: color-mix(in srgb, var(--flare-color-red-packet-end), var(--flare-color-red-packet-faded-mix-target) var(--rp-mix));
  --rp-gold: color-mix(in srgb, var(--flare-color-red-packet-gold), var(--flare-color-red-packet-faded-mix-target) var(--rp-mix));
  --rp-gold-deep: color-mix(in srgb, var(--flare-color-red-packet-gold-deep), var(--flare-color-red-packet-faded-mix-target) var(--rp-mix));
  --rp-text: var(--flare-color-red-packet-faded-ink);
  --rp-status: var(--flare-color-red-packet-faded-ink);
  --rp-amount: var(--flare-color-red-packet-faded-ink);
  --rp-soft: color-mix(in srgb, var(--flare-color-red-packet-faded-ink) 72%, transparent);
  --rp-rule: color-mix(in srgb, var(--flare-color-red-packet-faded-ink) 18%, transparent);
  box-shadow: none;
}
/* The envelope glyph paints from the same slots, so a spent card's glyph is mixed with the rest. */
.flare-red-packet__glyph { flex: 0 0 auto; display: block; z-index: 1; }
.flare-red-packet__glyph-gold { stop-color: var(--rp-gold); }
.flare-red-packet__glyph-gold-deep { stop-color: var(--rp-gold-deep); }
.flare-red-packet__glyph-flap { fill: var(--rp-gold-deep); }
.flare-red-packet__glyph-seal { fill: var(--rp-end); }
.flare-red-packet__glyph-shadow { fill: var(--flare-color-red-packet-end); opacity: 0.25; }
.flare-red-packet.is-dimmed .flare-red-packet__glyph-shadow { opacity: 0.12; }
.flare-red-packet__body { flex: 1; min-width: 0; z-index: 1; }
.flare-red-packet__blessing {
  display: block;
  font-size: var(--flare-size-font-size-lg);
  font-weight: var(--flare-size-font-weight-semibold);
  color: var(--rp-text);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-red-packet__status {
  display: block;
  margin-top: 3px;
  font-size: var(--flare-size-font-size-sm);
  color: var(--rp-status);
  overflow-wrap: anywhere;
}
.flare-red-packet__status b { color: var(--rp-amount); font-variant-numeric: tabular-nums; }
.flare-red-packet__brand {
  grid-column: 1 / -1;
  display: flex;
  align-items: baseline;
  gap: var(--flare-size-spacing-sm);
  width: 100%;
  padding-top: var(--flare-size-spacing-sm);
  border-top: 1px solid var(--rp-rule);
  font-size: var(--flare-size-font-size-2xs);
  letter-spacing: 0.04em;
  color: var(--rp-soft);
  z-index: 1;
}
.flare-red-packet__kind {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-red-packet__brand-name { margin-inline-start: auto; flex: 0 0 auto; }
@media (prefers-reduced-motion: reduce) {
  .flare-red-packet { transition: none; }
  .flare-red-packet:active:not(:disabled) { transform: none; }
}
</style>
