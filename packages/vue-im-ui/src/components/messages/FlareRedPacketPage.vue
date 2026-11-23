<script setup lang="ts">
// 红包页 —— 插件页的视图声明 presentation.renderer 为 redPacket.compose / redPacket.detail / redPacket.review 时，
// FlarePluginPage 用它代替通用文档（docs/plugin-experience.md §11「从 + 到详情都是红包版式」）：发红包是
// FlareRedPacketComposer，确认页是 FlareRedPacketReview，红包详情是 FlareRedPacketDetail，能领时盖上 FlareRedPacketOpenSheet。数据和命令仍是这页的：表单值按页面的输入
// 交回 onAction，领取、去钱包都是清单绑定的动作。视图映射不上（flareRedPacketPagePlan 为空）时什么也不画，页面画通用文档。
import { computed, nextTick, onBeforeUnmount, ref, watch } from "vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";
import FlareContactPicker from "../composer/FlareContactPicker.vue";
import FlarePluginView from "./FlarePluginView.vue";
import FlareRedPacketComposer from "./FlareRedPacketComposer.vue";
import FlareRedPacketDetail from "./FlareRedPacketDetail.vue";
import FlareRedPacketOpenSheet from "./FlareRedPacketOpenSheet.vue";
import FlareRedPacketReview from "./FlareRedPacketReview.vue";
import { flarePaymentAmountText } from "../../shared/contracts/capability-ui";
import {
  flarePluginCheckInput,
  flarePluginFormValues,
  flarePluginVisibleInputs,
  type FlarePluginActionPayload,
  type FlarePluginFormError,
  type FlarePluginMember,
  type FlarePluginResolveUser,
  type FlarePluginViewModel,
} from "../../shared/contracts/plugin-ui";
import {
  flareRedPacketAmountMinor,
  flareRedPacketComposePlan,
  flareRedPacketDetailPlan,
  flareRedPacketMoney,
  flareRedPacketReviewPlan,
  type FlareRedPacketClaim,
  type FlareRedPacketField,
  type FlareRedPacketKind,
} from "../../shared/contracts/red-packet";
import type { FlareContactPickerEntry } from "../../shared/contracts/contact-picker";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

const props = defineProps<{
  view: FlarePluginViewModel;
  busyActionId?: string;
  error?: string;
  formErrors?: ReadonlyArray<FlarePluginFormError>;
  settleToken?: number;
  refreshing?: boolean;
  /** UI memory of the shown page (the host drops it on close, reopen or session change): the composer's draft. */
  contentState?: Record<string, unknown>;
  members?: FlarePluginMember[];
  /** The group's size counting the viewer, from the host's own group or conversation data (never members.length). */
  memberCount?: number;
  membersLoading?: boolean;
  membersError?: string;
  membersRevision?: number;
  resolveUser?: FlarePluginResolveUser;
  onAction: (id: string, payload?: FlarePluginActionPayload) => void;
  onMemberSearch?: (query: string) => void;
  onMembersRetry?: () => void;
  onBack?: () => void;
  /** Re-read the page; with it, a failed opening offers 「查看结果」 instead of claiming again. */
  onRefresh?: () => void;
}>();
const { t } = useFlareI18nOptional();
const plan = computed(() => flareRedPacketComposePlan(props.view));
const detail = computed(() => flareRedPacketDetailPlan(props.view));
const review = computed(() => flareRedPacketReviewPlan(props.view));
const busy = computed(() => Boolean(props.busyActionId || props.refreshing));

// ── compose ──────────────────────────────────────────────────────────────
const kind = ref<FlareRedPacketKind>("normal"), amount = ref(""), count = ref(1), greeting = ref("");
const composer = ref<InstanceType<typeof FlareRedPacketComposer>>();
type PacketIssue = { field: FlareRedPacketField | "form"; text: string };
const fieldFor = (input: string): PacketIssue["field"] =>
  ({ amount: "amount", shareCount: "count", greeting: "greeting", designatedUserIds: "recipient" } as const)[
    input as "amount" | "shareCount" | "greeting" | "designatedUserIds"] ?? "form";
const chosen = ref<FlareContactPickerEntry>(), picking = ref(false), attempted = ref(false), hostErrors = ref(true);
const draftOf = (value: unknown): Record<string, unknown> =>
  value && typeof value === "object" && !Array.isArray(value) ? (value as Record<string, unknown>) : {};
watch([() => plan.value?.action.id ?? "", () => props.contentState], () => {
  const inputs = plan.value?.inputs ?? [];
  const saved = draftOf(props.contentState?.redPacketDraft);
  kind.value = plan.value?.kinds.includes(saved.kind as FlareRedPacketKind) ? (saved.kind as FlareRedPacketKind) : plan.value?.kinds[0] ?? "normal";
  amount.value = typeof saved.amount === "string" ? saved.amount : "";
  count.value = Number.isSafeInteger(saved.count) && Number(saved.count) >= 0 ? Number(saved.count) : 1;
  const value = inputs.find((input) => input.id === "greeting")?.default;
  greeting.value = typeof saved.greeting === "string" ? saved.greeting : typeof value === "string" ? value : "";
  chosen.value = props.members?.find((member) => member.userId === saved.recipientId);
  picking.value = false;
  attempted.value = false;
}, { immediate: true });
watch(() => props.membersRevision, () => { chosen.value = undefined; picking.value = false; });
watch([kind, amount, count, greeting, chosen], () => {
  hostErrors.value = false;
  if (props.contentState && plan.value) props.contentState.redPacketDraft = {
    kind: kind.value, amount: amount.value, count: count.value, greeting: greeting.value, recipientId: chosen.value?.userId,
  };
}, { flush: "sync" });
watch(() => props.settleToken, () => { hostErrors.value = true; });
const scale = computed(() => plan.value?.scale ?? 2);
const amountMinor = computed(() => flareRedPacketAmountMinor(amount.value, scale.value));
const totalMinor = computed(() => amountMinor.value == null ? null : kind.value === "normal" && plan.value?.kinds.length !== 1
  ? (BigInt(amountMinor.value) * BigInt(Number.isSafeInteger(count.value) && count.value > 0 ? count.value : 0)).toString()
  : amountMinor.value);
const total = computed(() => flareRedPacketMoney(totalMinor.value ?? "0", scale.value, plan.value?.currency ?? "") ?? "");
const draft = computed(() => ({
  kind: kind.value, amount: amount.value,
  shareCount: kind.value === "exclusive" || plan.value?.kinds.length === 1 ? 1 : count.value,
  greeting: greeting.value.trim() || String(plan.value?.inputs.find((input) => input.id === "greeting")?.default ?? ""),
  designatedUserIds: chosen.value ? [chosen.value.userId] : [],
}));
function issueText(issue: FlarePluginFormError["issue"], inputId: string): string {
  const input = plan.value?.inputs.find((candidate) => candidate.id === inputId);
  // §4.2: a missing exclusive recipient reads 请选择发给谁, not the generic "<label>: 必填".
  if (fieldFor(inputId) === "recipient" && (issue === "required" || issue === "tooFewItems")) return t("redPacket.chooseRecipient");
  const key = issue === "required" || issue === "tooLong" || issue === "outOfRange" || issue === "tooFewItems"
    || issue === "tooManyItems" || issue === "duplicateItem" ? issue : "invalid";
  const text = t(`pluginForm.${key}`, { n: key === "tooFewItems" ? input?.min ?? 1 : input?.max ?? 1 });
  return input ? `${input.label}: ${text}` : text;
}
function validation(): PacketIssue | undefined {
  const active = plan.value;
  if (!active) return;
  for (const input of flarePluginVisibleInputs(active.inputs, draft.value)) {
    const value = draft.value[input.id as keyof typeof draft.value];
    if (input.id === "shareCount" && input.kind === "number" && typeof value === "number") {
      const limits = [input.max, active.maxRecipients]
        .filter((limit): limit is number => typeof limit === "number" && Number.isSafeInteger(limit) && limit > 0);
      const max = limits.length ? Math.min(...limits) : undefined;
      if (max !== undefined && value > max) return { field: "count", text: t("redPacket.countLimit", { n: max }) };
    }
    // The composer's empty count is 0: the input's declared range applies before a payment is prepared; the generic
    // validator only checks that a number is there.
    const issue = input.id === "shareCount" && input.kind === "number"
      ? !Number.isSafeInteger(value) || Number(value) <= 0 ? "required"
        : (input.min != null && Number(value) < input.min) || (input.max != null && Number(value) > input.max) ? "outOfRange" : null
      : flarePluginCheckInput(input, value);
    if (!issue) continue;
    if (input.kind === "money" && input.money?.min != null && input.money.max != null)
      return { field: fieldFor(input.id), text: t("pluginForm.moneyRange", { min: input.money.min, max: input.money.max, currency: input.money.currency ?? "" }) };
    return { field: fieldFor(input.id), text: issueText(issue, input.id) };
  }
  const max = active.money.money?.max;
  const maxMinor = max == null ? null : flareRedPacketAmountMinor(max, scale.value);
  if (totalMinor.value != null && maxMinor != null && BigInt(totalMinor.value) > BigInt(maxMinor))
    return { field: "amount", text: `${t("redPacket.field.total")}: ${t("pluginForm.moneyRange", { min: active.money.money?.min ?? "", max: max ?? "", currency: active.money.money?.currency ?? "" })}` };
}
const displayIssue = computed<PacketIssue | undefined>(() => props.error ? { field: "form", text: props.error }
  : hostErrors.value && props.formErrors?.length
    ? { field: fieldFor(props.formErrors[0]!.input), text: issueText(props.formErrors[0]!.issue, props.formErrors[0]!.input) }
    : attempted.value ? validation() : undefined);
function submit(): void {
  if (busy.value || !plan.value) return;
  attempted.value = true;
  const issue = validation();
  if (issue) {
    if (issue.field !== "form") { const field = issue.field; void nextTick(() => composer.value?.focusField(field)); }
    return;
  }
  props.onAction(plan.value.action.id, { formValues: flarePluginFormValues(plan.value.inputs, draft.value) });
}
function choose(entries: FlareContactPickerEntry[]): void { chosen.value = entries[0]; picking.value = false; }
function openPicker(): void { if (!busy.value) { picking.value = true; props.onMemberSearch?.(""); } }
// 「本群共 N 人」: a group offers more than the one ordinary kind; the composer shows it under the count row only.
const memberCount = computed(() => (plan.value && plan.value.kinds.length > 1 && props.memberCount ? props.memberCount : undefined));
// The page's warnings stay above the composer and the review; its other blocks are what they already draw.
const notes = computed<FlarePluginViewModel>(() => ({ ...props.view, presentation: undefined, title: "", fields: [], inputs: [],
  blocks: (props.view.blocks ?? []).filter((block) => block.kind === "note" && (block.tone === "danger" || block.tone === "warning")),
  actions: [], menuActions: [] }));

// ── review ───────────────────────────────────────────────────────────────
const reviewAmount = computed(() => review.value ? (review.value.currency ? flarePaymentAmountText(review.value.amount, review.value.currency) : null) ?? review.value.amount : "");
const reviewKind = computed(() => {
  const active = review.value;
  if (!active || active.kindLabel) return active?.kindLabel;
  if (!active.packetKind) return undefined;
  const kind = t(`redPacket.kind.${active.packetKind}`);
  const unit = t("redPacket.countUnit");
  return active.shareCount === undefined ? kind : `${kind} · ${active.shareCount}${unit ? ` ${unit}` : ""}`;
});
function send(): void { const action = review.value?.action; if (!busy.value && action) props.onAction(action.id); }

// ── detail ───────────────────────────────────────────────────────────────
const people = ref<Record<string, { name: string; avatarUrl?: string }>>({});
let identityEpoch = 0;
watch(() => [detail.value?.senderId ?? "", ...(detail.value?.claims ?? []).map((row) => row.id), ...(detail.value?.designatedUserIds ?? [])].join("\0"), async (key) => {
  const epoch = ++identityEpoch;
  const ids = [...new Set(key.split("\0").filter(Boolean))];
  const resolved = await Promise.all(ids.map(async (id) => {
    const local = props.members?.find((member) => member.userId === id);
    try { return [id, local ?? await props.resolveUser?.(id)] as const; } catch { return [id, undefined] as const; }
  }));
  if (epoch === identityEpoch) people.value = Object.fromEntries(resolved.filter((row): row is readonly [string, { name: string; avatarUrl?: string }] => Boolean(row[1])));
}, { immediate: true });
onBeforeUnmount(() => { identityEpoch++; });
const unknown = computed(() => t("displayName.unknownUser"));
const sender = computed(() => people.value[detail.value?.senderId ?? ""] ?? { name: unknown.value });
const claims = computed<FlareRedPacketClaim[]>(() => (detail.value?.claims ?? []).map((row) => ({ ...row,
  name: people.value[row.id]?.name ?? unknown.value, avatar: people.value[row.id]?.avatarUrl })));
const designatedName = computed(() => { const id = detail.value?.designatedUserIds[0]; return id ? people.value[id]?.name : undefined; });
const sheetDismissed = ref(false);
const opening = computed(() => Boolean(detail.value?.claimAction && !sheetDismissed.value));
function claim(): void { const action = detail.value?.claimAction; if (!busy.value && action) props.onAction(action.id); }
function deposited(): void { const action = detail.value?.walletAction; if (action) props.onAction(action.id); }
function reviewDetails(): void {
  sheetDismissed.value = true;
  if (props.error && !busy.value) props.onRefresh?.();
}
</script>

<template>
  <template v-if="plan">
    <FlarePluginView v-if="notes.blocks?.length" :view="notes" embedded :busy-action-id="busyActionId" :on-action="onAction" />
    <FlareRedPacketComposer ref="composer" v-model:kind="kind" v-model:amount="amount" v-model:count="count" v-model:greeting="greeting"
      :kinds="plan.kinds" :currency-exponent="scale" :member-count="memberCount" :total="total" :busy="busy" :error="displayIssue?.text" :error-field="displayIssue?.field ?? 'form'"
      :submit-label="plan.action.label" @submit="submit">
      <template #recipient><FlareButton size="sm" variant="text" :label="chosen?.name || t('pluginForm.chooseMembers')" :disabled="busy" @click="openPicker" /></template>
    </FlareRedPacketComposer>
    <FlareButton v-if="error && onRefresh" size="sm" variant="text" :label="t('pluginView.refresh')" :loading="refreshing" :disabled="busy" @click="onRefresh" />
    <FlareBottomSheet :open="picking" :title="t('redPacket.field.recipient')" fill @close="picking = false">
      <FlareContactPicker v-if="picking" :groups="[{ id: 'members', entries: members ?? [] }]" :title="t('redPacket.field.recipient')"
        :loading="membersLoading" :error="membersError" :on-search="onMemberSearch" :on-retry="onMembersRetry" @select="choose" @cancel="picking = false" />
    </FlareBottomSheet>
  </template>
  <template v-else-if="review">
    <FlarePluginView v-if="notes.blocks?.length" :view="notes" embedded :busy-action-id="busyActionId" :on-action="onAction" />
    <FlareRedPacketReview :amount="reviewAmount" :kind-label="reviewKind" :blessing="review.blessing" :submit-label="review.action.label"
      :busy="busy" :error="error" @submit="send" />
  </template>
  <template v-else-if="detail">
    <FlareStatusBanner v-if="error" :text="detail.paidClaimPending ? t('redPacket.claimPendingReview') : error" :tone="detail.paidClaimPending ? 'warning' : 'danger'" />
    <FlareRedPacketDetail :sender-name="sender.name" :sender-avatar="sender.avatarUrl" :details="detail.details" :claims="claims"
      :designated-name="designatedName" :onDeposited="detail.walletAction ? deposited : undefined" />
    <FlareButton v-if="detail.claimAction && sheetDismissed" block :label="detail.claimAction.label" :loading="busy" @click="sheetDismissed = false" />
    <FlareRedPacketOpenSheet :open="opening" :sender-name="sender.name" :sender-avatar="sender.avatarUrl" :blessing="detail.details.greeting"
      :kind-label="t(`redPacket.kind.${detail.details.kind}`)" :state="busy ? 'opening' : error ? 'error' : 'ready'"
      :message="error" :review-on-error="Boolean(onRefresh)" @open="claim" @close="onBack?.()" @view-details="reviewDetails" />
  </template>
</template>
