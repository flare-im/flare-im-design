<script setup lang="ts">
// 插件能力授权 —— 插件第一次用一项宿主能力时宿主弹的同意面板（设计 7.4）：
// 「〈插件名〉想要使用 〈能力〉」、用途、「仅本次允许」「始终允许」「不允许」。
// Kit 不存同意记录：`decide` 交回选择，宿主用 flareCapabilityConsentAnswer 换成引擎要的 {decision}；
// 引擎只记「始终允许」，「仅本次」只放行这一次，宿主不用撤销。一次性定位每次都要确认，所以不给「始终允许」。
import { computed } from "vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareIcon from "../general/FlareIcon.vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import type { FlareIconName } from "../../shared/icons";
import {
  flareCapabilityConsentAllowsAlways,
  flareCapabilityLabelKey,
  type FlareCapabilityConsentDecision,
} from "../../shared/contracts/capability-ui";

const props = withDefaults(
  defineProps<{
    open: boolean;
    /** The plugin's display name. */
    pluginName: string;
    /** The capability the engine asks about (`consent.capability`), e.g. documentCapture. */
    capability: string;
    /** The capability's params (`consent.params`): a location's precision picks the coarse or fine line. */
    params?: Record<string, unknown> | null;
    /** Why the plugin wants it, in the plugin's words (the manifest's declared purpose), when the host has one. */
    purpose?: string;
    busy?: boolean;
  }>(),
  { busy: false },
);
const emit = defineEmits<{ (e: "decide", decision: FlareCapabilityConsentDecision): void }>();
const { t } = useFlareI18nOptional();

const labelKey = computed(() => flareCapabilityLabelKey(props.capability, props.params));
const allowsAlways = computed(() => flareCapabilityConsentAllowsAlways(props.capability));
const ICONS: Record<string, FlareIconName> = {
  documentCapture: "camera",
  camera: "camera",
  paymentConfirmation: "wallet",
  locationCoarse: "location",
  locationFine: "location",
  microphone: "mic",
  rtcSession: "video",
  generic: "info",
};
const icon = computed<FlareIconName>(() => ICONS[labelKey.value] ?? "info");

function decide(decision: FlareCapabilityConsentDecision): void {
  if (!props.busy) emit("decide", decision);
}
</script>

<template>
  <!-- §6.5: on a wide window a 400 dialog, the payment sheet's width. -->
  <FlareBottomSheet :open="open" :title="t('capability.consentTitle', { plugin: pluginName })" :dismissible="!busy" dialog-width="var(--flare-size-component-payment-dialog-width)" @close="decide('deny')">
    <div class="flare-consent" :data-capability="capability">
      <div class="flare-consent__what">
        <span class="flare-consent__icon" aria-hidden="true"><FlareIcon :name="icon" /></span>
        <p class="flare-consent__label" data-consent-label="true">{{ t(`capability.label.${labelKey}`) }}</p>
      </div>
      <div v-if="purpose" class="flare-consent__purpose">
        <span class="flare-consent__purpose-label">{{ t("capability.purpose") }}</span>
        <p class="flare-consent__purpose-text">{{ purpose }}</p>
      </div>
      <p v-if="allowsAlways" class="flare-consent__note">{{ t("capability.note") }}</p>
      <div class="flare-consent__actions">
        <FlareButton
          v-if="allowsAlways"
          block
          size="lg"
          :label="t('capability.allowAlways')"
          :disabled="busy"
          data-consent="always"
          @click="decide('always')"
        />
        <FlareButton
          block
          size="lg"
          :variant="allowsAlways ? 'secondary' : 'primary'"
          :label="t('capability.allowOnce')"
          :disabled="busy"
          data-consent="once"
          @click="decide('once')"
        />
        <FlareButton block size="lg" variant="quiet" :label="t('capability.deny')" :disabled="busy" data-consent="deny" @click="decide('deny')" />
      </div>
    </div>
  </FlareBottomSheet>
</template>

<style scoped>
.flare-consent {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-md);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg) var(--flare-size-spacing-lg);
  color: var(--flare-color-text-primary);
}
.flare-consent__what { display: flex; align-items: center; gap: var(--flare-size-spacing-md); min-width: 0; }
.flare-consent__icon {
  display: inline-flex;
  flex: 0 0 auto;
  align-items: center;
  justify-content: center;
  width: var(--flare-size-layout-touch-target);
  height: var(--flare-size-layout-touch-target);
  border-radius: var(--flare-size-radius-full);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-primary-text);
}
.flare-consent__label { margin: 0; min-width: 0; font-size: var(--flare-size-font-size-lg); font-weight: var(--flare-size-font-weight-medium); overflow-wrap: anywhere; }
.flare-consent__purpose { display: grid; gap: var(--flare-size-spacing-xs); }
.flare-consent__purpose-label { font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-secondary); }
.flare-consent__purpose-text { margin: 0; font-size: var(--flare-size-font-size-md); overflow-wrap: anywhere; }
.flare-consent__note { margin: 0; font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-secondary); }
.flare-consent__actions { display: flex; flex-direction: column; gap: var(--flare-size-spacing-sm); }
</style>
