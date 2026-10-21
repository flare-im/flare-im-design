<script setup lang="ts">
import { NIcon } from "naive-ui";
import { computed } from "vue";
import { GiftOutline } from "../../shared/icon-glyphs";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    /** Greeting on the packet, e.g. "恭喜发财，大吉大利". */
    blessing: string;
    /** Revealed amount once opened (host formats the number). */
    amount?: string;
    /** Whether this packet has been claimed by the current user. */
    opened?: boolean;
    /** Whether the packet is fully claimed / expired (dimmed, not tappable). */
    finished?: boolean;
    disabled?: boolean;
    busy?: boolean;
    statusLabel?: string;
  }>(),
  { opened: false, finished: false, disabled: false, busy: false },
);
const emit = defineEmits<{ (e: "open"): void }>();

const { t } = useFlareI18n();
const blocked = computed(() => props.finished || props.disabled || props.busy);
const status = computed(() => props.busy ? t("redPacket.busy") : props.statusLabel
  ?? (props.opened && props.amount ? `${t("redPacket.received")} · ${props.amount}`
    : props.finished ? t("redPacket.finished") : props.disabled ? t("redPacket.unavailable") : t("redPacket.tapToOpen")));
</script>

<template>
  <button
    type="button"
    class="flare-red-packet"
    :class="{ 'is-opened': opened, 'is-finished': finished }"
    :disabled="blocked"
    :aria-busy="busy"
    @click="!blocked && emit('open')"
  >
    <span class="flare-red-packet__seal">
      <n-icon aria-hidden="true" :size="22" :component="GiftOutline" />
    </span>
    <span class="flare-red-packet__body">
      <span class="flare-red-packet__blessing">{{ blessing }}</span>
      <span class="flare-red-packet__status" :aria-live="busy ? 'polite' : 'off'">
        <template v-if="!busy && statusLabel == null && opened && amount">{{ t("redPacket.received") }} · <b>{{ amount }}</b></template>
        <template v-else>{{ status }}</template>
      </span>
    </span>
    <span class="flare-red-packet__brand">{{ t("redPacket.brand") }}</span>
  </button>
</template>

<style scoped>
.flare-red-packet {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr);
  align-items: center;
  gap: 12px;
  width: 248px;
  max-width: 100%;
  min-height: 48px;
  min-width: 0;
  box-sizing: border-box;
  padding: var(--flare-size-spacing-2md);
  border: none;
  border-radius: 14px;
  cursor: pointer;
  text-align: left;
  color: #fff5e6;
  background: linear-gradient(135deg, #f0503c 0%, #e23b2e 52%, #c8291f 100%);
  box-shadow: 0 10px 24px rgba(200, 41, 31, 0.32);
  position: relative;
  overflow: hidden;
  transition: transform var(--flare-transition-fast), filter var(--flare-transition-fast);
}
.flare-red-packet:hover:not(:disabled) { filter: brightness(1.03); }
.flare-red-packet:active:not(:disabled) { transform: scale(0.98); }
.flare-red-packet:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 3px; }
.flare-red-packet:disabled { cursor: default; }
.flare-red-packet.is-finished { filter: saturate(0.55) brightness(0.92); cursor: default; }
.flare-red-packet__seal {
  flex: 0 0 auto;
  width: 42px;
  height: 42px;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #c8291f;
  background: radial-gradient(circle at 50% 38%, #ffe9b8, #f6c453);
  box-shadow: inset 0 0 0 2px rgba(200, 41, 31, 0.18);
  z-index: 1;
}
.flare-red-packet__body { flex: 1; min-width: 0; z-index: 1; }
.flare-red-packet__blessing {
  display: block;
  font-size: 14px;
  font-weight: 600;
  color: #fff;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-red-packet__status {
  display: block;
  margin-top: 3px;
  font-size: 12px;
  color: rgba(255, 236, 210, 0.85);
  overflow-wrap: anywhere;
}
.flare-red-packet__status b { color: #ffe9b8; font-variant-numeric: tabular-nums; }
.flare-red-packet__brand {
  grid-column: 1 / -1;
  width: 100%;
  padding-top: var(--flare-size-spacing-sm);
  border-top: 1px solid rgba(255, 240, 210, 0.28);
  text-align: right;
  font-size: var(--flare-size-font-size-2xs);
  letter-spacing: 0.04em;
  color: rgba(255, 236, 210, 0.5);
  z-index: 1;
}
</style>
