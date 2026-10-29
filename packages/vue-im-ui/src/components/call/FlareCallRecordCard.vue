<script setup lang="ts">
import { computed } from "vue";
import FlareButton from "../general/FlareButton.vue";
import FlareIcon from "../general/FlareIcon.vue";
import {
  flareCallDurationLabel,
  flareCallRecordAction,
  flareCallRecordStatus,
  flareCallRecordTone,
  type FlareCallEndReason,
  type FlareCallMode,
  type FlareCallRecordScope,
  type FlareCallRecordState,
  type FlareCallRecordStatus,
} from "../../shared/contracts/call";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

// The call record in the chat timeline (spec/call-record-vectors.json): the media icon, one viewer-relative status
// line, the media name and at most one action — join a group call in progress, or call back after a 1:1 call.
// Presentational only: the host maps the call plugin's record and the viewer's own facts onto these props and owns
// what join and callBack do. The card is the message's card surface; the timeline draws no bubble around it.
const props = withDefaults(
  defineProps<{
    media: FlareCallMode;
    scope: FlareCallRecordScope;
    state: FlareCallRecordState;
    /** Why an ended call ended; a missing reason reads completed. */
    endReason?: FlareCallEndReason;
    /** Talk time of a completed call, in seconds. */
    durationSeconds?: number;
    /** People in a group call in progress. */
    joinedCount?: number;
    /** The viewer started this call. */
    viewerIsInitiator: boolean;
    /** Host-decided: a group call in progress the viewer is not in. */
    canJoin: boolean;
    /** Host-decided: calls are available for this conversation. */
    canCallBack: boolean;
    /** The call plugin is unavailable: the record stays, the action goes. */
    disabled?: boolean;
    /** The action the viewer took is in flight: it shows progress and does not take another tap. */
    busy?: boolean;
  }>(),
  { endReason: undefined, durationSeconds: undefined, joinedCount: undefined, disabled: false, busy: false },
);
const emit = defineEmits<{ (e: "join"): void; (e: "callBack"): void }>();

const { t } = useFlareI18n();
const STATUS_KEYS: Record<FlareCallRecordStatus, string> = {
  waitingAnswer: "callRecord.waitingAnswer",
  incoming: "callRecord.incoming",
  groupRinging: "callRecord.groupRinging",
  inCall: "callRecord.inCall",
  groupOngoing: "callRecord.groupOngoing",
  groupInProgress: "callRecord.groupInProgress",
  duration: "callRecord.duration",
  groupEndedDuration: "callRecord.groupEndedDuration",
  groupEnded: "callRecord.groupEnded",
  cancelledByYou: "callRecord.cancelledByYou",
  cancelledByCaller: "callRecord.cancelledByCaller",
  declinedByPeer: "callRecord.declinedByPeer",
  declinedByYou: "callRecord.declinedByYou",
  noAnswer: "callRecord.noAnswer",
  missed: "callRecord.missed",
  peerBusy: "callRecord.peerBusy",
  missedBusy: "callRecord.missedBusy",
  unavailable: "callRecord.unavailable",
  failed: "callRecord.failed",
};

const status = computed(() => flareCallRecordStatus(props));
const tone = computed(() => flareCallRecordTone(status.value));
const action = computed(() => flareCallRecordAction(props));
const statusText = computed(() =>
  t(STATUS_KEYS[status.value], {
    count: props.joinedCount ?? 0,
    duration: flareCallDurationLabel(props.durationSeconds ?? 0),
  }),
);
const mediaText = computed(() => (props.media === "video" ? t("callRecord.video") : t("callRecord.voice")));
const actionLabel = computed(() => (action.value === "join" ? t("callRecord.join") : t("callRecord.callBack")));
// The group is named by what the card says; the button inside names itself.
const accessibleName = computed(() => t("callRecord.label", { media: mediaText.value, status: statusText.value }));

function onAction() {
  if (props.busy || !action.value) return;
  if (action.value === "join") emit("join");
  else emit("callBack");
}
</script>

<template>
  <div
    class="flare-call-record"
    :class="[`is-${tone}`, { 'has-action': action }]"
    role="group"
    :aria-label="accessibleName"
    :data-status="status"
    :data-tone="tone"
  >
    <span class="flare-call-record__icon" aria-hidden="true">
      <FlareIcon :name="media === 'video' ? 'video' : 'phone'" :size="20" />
    </span>
    <span class="flare-call-record__body" aria-hidden="true">
      <span class="flare-call-record__status" data-call-record-status="true">{{ statusText }}</span>
      <span class="flare-call-record__media">{{ mediaText }}</span>
    </span>
    <FlareButton
      v-if="action"
      class="flare-call-record__action"
      variant="secondary"
      size="sm"
      :label="actionLabel"
      :loading="busy"
      :data-call-record-action="action"
      @click="onAction"
    />
  </div>
</template>

<style scoped>
/* The kit card shell (spec/message-surface-vectors.json rules.cardShell): richCardWidth like every card, the primary
   ground, a hairline and radius lg. Outgoing and incoming records differ by alignment only. */
.flare-call-record {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr);
  align-items: center;
  gap: var(--flare-size-spacing-md);
  width: var(--flare-size-component-rich-card-width);
  max-width: 100%;
  min-width: 0;
  box-sizing: border-box;
  padding: var(--flare-size-spacing-md);
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-primary);
  color: var(--flare-color-text-primary);
}
.flare-call-record.has-action { grid-template-columns: auto minmax(0, 1fr) auto; }
/* The media icon on the voice player's disc: a weak tint of the accent, the accent's text colour. */
.flare-call-record__icon {
  display: grid;
  place-items: center;
  width: var(--flare-size-layout-control-height-md);
  height: var(--flare-size-layout-control-height-md);
  border-radius: var(--flare-size-radius-full);
  color: var(--flare-color-primary-text);
  background: color-mix(in srgb, var(--flare-color-primary) calc(var(--flare-opacity-tint-weak) * 100%), transparent);
}
.flare-call-record.is-danger .flare-call-record__icon {
  color: var(--flare-color-error-text);
  background: color-mix(in srgb, var(--flare-color-error) calc(var(--flare-opacity-tint-weak) * 100%), transparent);
}
.flare-call-record__body {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-3xs);
  min-width: 0;
}
.flare-call-record__status {
  font-size: var(--flare-size-font-size-lg);
  font-weight: var(--flare-size-font-weight-medium);
  line-height: var(--flare-size-line-height-snug);
  overflow-wrap: anywhere;
}
.flare-call-record.is-danger .flare-call-record__status { color: var(--flare-color-error-text); }
.flare-call-record__media {
  font-size: var(--flare-size-font-size-sm);
  line-height: var(--flare-size-line-height-snug);
  color: var(--flare-color-text-tertiary);
}
.flare-call-record__action { flex: none; }
</style>
