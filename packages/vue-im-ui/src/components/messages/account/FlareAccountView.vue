<script setup lang="ts">
import { computed, getCurrentInstance, ref, watch } from "vue";
import FlareIcon from "../../general/FlareIcon.vue";
import FlareIconButton from "../../general/FlareIconButton.vue";
import FlareButton from "../../general/FlareButton.vue";
import FlareBottomSheet from "../../general/FlareBottomSheet.vue";
import FlareEmptyState from "../../general/FlareEmptyState.vue";
import FlareStatusBanner from "../../general/FlareStatusBanner.vue";
import FlareTag from "../../general/FlareTag.vue";
import FlareSettingsRow from "../../profile/FlareSettingsRow.vue";
import FlarePluginView from "../FlarePluginView.vue";
import { useFlareAdaptiveSafe } from "../../../composables/useAdaptiveMode";
import { flareIcons } from "../../../shared/icons";
import { flareServerNowMs } from "../../../shared/server-clock";
import { useFlareI18nOptional, useFlareLocaleOptional } from "../../../shared/i18n/useFlareI18n";
import { flarePluginDateTime, flarePluginInlineFormAction, flarePluginMoneyFormatted, type FlarePluginAction, type FlarePluginActionPayload, type FlarePluginFormError, type FlarePluginFileState, type FlarePluginFileAction, type FlarePluginMember, type FlarePluginResolveUser, type FlarePluginViewModel } from "../../../shared/contracts/plugin-ui";
import { flareAccountDayKey, flareAccountEntries, type AccountEntry } from "./account";
import type { FlareTone } from "../../../shared/contracts/tone";
import { flarePluginActionRole, flarePluginAmountSign, flarePluginDisplayAmount, flarePluginStatusDraw } from "../../../shared/contracts/plugin-experience";
import { useFlarePluginWarnScope } from "../plugin/warnScope";

const props = withDefaults(defineProps<{
  view: FlarePluginViewModel; busyActionId?: string; error?: string; formErrors?: FlarePluginFormError[];
  fileStates?: Record<string, FlarePluginFileState>;
  settleToken?: number; members?: FlarePluginMember[];
    membersLoading?: boolean;
    membersRevision?: number;
    membersError?: string;
  resolveUser?: FlarePluginResolveUser; viewerId?: string;
  /** The host is offline (R8): every action is disabled, the view stays as last loaded. */
  offline?: boolean;
}>(), { busyActionId: undefined, error: undefined, formErrors: () => [], settleToken: 0, members: () => [], resolveUser: undefined, viewerId: undefined, offline: false });
const emit = defineEmits<{
  action: [id: string, payload: FlarePluginActionPayload];
  fileAction: [event: FlarePluginFileAction];
  memberSearch: [query: string];
  membersRetry: [];
}>();
function forwardMemberSearch(query: string): void { emit("memberSearch", query); }
function forwardMembersRetry(): void { emit("membersRetry"); }
const { t } = useFlareI18nOptional();
const locale = useFlareLocaleOptional();
const instance = getCurrentInstance();
const hidden = ref(false), selected = ref<string>(), informationOpen = ref(false);
const entries = computed(() => flareAccountEntries(props.view, t("pluginView.unknownStatus")));
const warnAt = useFlarePluginWarnScope();
/** R3: a badge or cell with a tone, or outside its declared values, as the kit Tag (the unknown status, never raw). */
function statusOf(item: { text: string; tone?: string; unmapped?: boolean }, where: string): { text: string; tone: FlareTone } | undefined {
  const drawn = flarePluginStatusDraw(item, warnAt(where));
  return drawn.draw === "tag" ? { text: drawn.unknown ? t("pluginView.unknownStatus") : drawn.text, tone: drawn.tone ?? "neutral" } : undefined;
}
// §5.1 phone: the first (default) wallet leads the overview, the others are an "other wallets" list; PC keeps the grid.
const adaptive = useFlareAdaptiveSafe();
const phone = computed(() => adaptive.isH5.value);
const overviewEntries = computed(() => phone.value ? entries.value.slice(0, 1) : entries.value);
const otherWallets = computed(() => phone.value ? entries.value.slice(1) : []);
const otherWalletsTitle = computed(() => t("wallet.otherWallets"));
const active = computed(() => entries.value.find(entry => entry.key === selected.value));
watch(() => props.view, () => { if (selected.value && !active.value) selected.value = undefined; });
const urgent = computed(() => (props.view.blocks ?? []).filter(block => {
  // A warning banner (the wallet's pending-operations notice, §5.1) leads the page with its own key, never inside the information panel.
  if (block.kind === "banner") return (block.tone === "warning" || block.tone === "danger") && block.text.trim().length > 0;
  if (layout.value !== "wallet" && layout.value !== "ledger") return block.kind === "note" && (block.tone === "warning" || block.tone === "danger");
  return (block.kind === "note" || block.kind === "status") && (block.tone === "warning" || block.tone === "danger") && block.text.trim().length > 0;
}));
const notices = computed<FlarePluginViewModel>(() => ({ ...props.view, presentation: undefined, fields: [], actions: [], menuActions: [], inputs: [], blocks: urgent.value, detail: false }));
const extras = computed(() => (props.view.blocks ?? []).filter(block => block.kind !== "rows" && !urgent.value.includes(block)));
const presentation = computed(() => props.view.presentation?.props ?? {});
const layout = computed(() => presentation.value.layout);
const isWallet = computed(() => layout.value === "wallet");
const isFlow = computed(() => layout.value === "flow");
const resultText = computed(() => [presentation.value.resultTitle, presentation.value.resultDescription].filter(value => typeof value === "string" && value.trim().length > 0).join("\n"));
const resultTone = computed<FlareTone>(() => {
  const tone = presentation.value.resultTone;
  return tone === "success" || tone === "warning" || tone === "danger" || tone === "info" || tone === "neutral" ? tone : "neutral";
});
const separateBadge = computed(() => presentation.value.rowBadgePlacement === "separate");
const hasLedger = computed(() => !isFlow.value && !isWallet.value);
const summaryTitle = computed(() => String(presentation.value.summaryTitle ?? props.view.title));
const walletTitle = computed(() => String(presentation.value.sectionTitle ?? summaryTitle.value));
const allActions = computed(() => {
  const seen = new Set<string>();
  return [...props.view.actions, ...(props.view.menuActions ?? [])].filter(action => {
    if (seen.has(action.id)) return false;
    seen.add(action.id);
    return true;
  });
});
const detailTitle = computed(() => String(presentation.value.detailTitle ?? presentation.value.sectionTitle ?? t("account.entryDetails")));
const extraView = computed<FlarePluginViewModel>(() => ({ ...props.view, presentation: undefined, title: "", fields: isWallet.value ? props.view.fields.slice(entries.value.length ? 0 : 1).map(field => ({ ...field, value: hidden.value ? "••••" : field.value })) : [], actions: [], menuActions: [], inputs: [], blocks: extras.value, detail: false }));
const hasInformation = computed(() => extras.value.length > 0 || (isWallet.value && extraView.value.fields.length > 0));
const receiptView = computed<FlarePluginViewModel>(() => ({ ...props.view, presentation: undefined, title: "", actions: primaryActions.value, menuActions: [], detail: false }));
// Slots group only actions the resolved view actually exposes. Conditional follow-up
// actions retain their primary placement even when the initial submit slot is hidden.
const primaryActions = computed(() => {
  const slots = props.view.presentation?.actions ?? {};
  const ids = (isFlow.value ? ["submit"] : isWallet.value ? ["primary", "secondary", "tertiary"] : []).map(slot => slots[slot]);
  const actions = [...new Set(ids)].flatMap(id => allActions.value.find(action => action.id === id) ?? []);
  if (isFlow.value) for (const action of allActions.value) if (action.style === "primary" && !actions.some(item => item.id === action.id)) actions.push(action);
  return actions;
});
const shortcutActions = computed(() => {
  if (!isWallet.value) return [];
  const slots = props.view.presentation?.actions ?? {};
  return [...new Set([slots.shortcutPrimary, slots.shortcutSecondary, slots.shortcutTertiary])].flatMap(id => allActions.value.find(action => action.id === id && !primaryActions.value.some(primary => primary.id === id)) ?? []);
});
const secondaryActions = computed(() => allActions.value.filter(action => !primaryActions.value.some(primary => primary.id === action.id) && !shortcutActions.value.some(shortcut => shortcut.id === action.id)));
/** §5.2: no account yet — the page is the setup state, with no balance and no top-up or withdrawal (W-01). */
const setup = computed(() => isWallet.value && !entries.value.length);
const direct = (action: FlarePluginAction) => !action.confirm && !action.form?.length && action.target?.kind !== "native";
/** §5.2: the key that opens an account — the first primary action that collects a form (the plugin's `create`). */
const setupAction = computed(() => allActions.value.find(action => action.style === "primary" && Boolean(action.form?.length)));
/** §5.2: the opening requests' key under it — the page destination declared next to the opening action (no words read). */
const setupProgress = computed(() => {
  const at = allActions.value.findIndex(action => action.id === setupAction.value?.id);
  return at < 0 ? undefined : [allActions.value[at - 1], allActions.value[at + 1]].find(action => action && flarePluginActionRole(action) === "destination" && direct(action));
});
/**
 * R2.1 on the wallet: placed as an overview page — the slot actions lead (the quick keys: two primaries, two commands),
 * the rest go to the grouped list cards, a danger action to its own card; declared shortcuts keep their row.
 * §5.2 without an account: no slot keys, the opening key first; its progress key is drawn under it, not in the list.
 */
const walletActions = computed(() => {
  if (!isWallet.value) return [];
  const slots = (["primary", "secondary", "tertiary"] as const).flatMap(slot => allActions.value.find(action => action.id === props.view.presentation?.actions?.[slot]) ?? []);
  const rest = allActions.value.filter(action => !slots.includes(action) && !shortcutActions.value.some(shortcut => shortcut.id === action.id));
  if (!setup.value) return [...slots, ...rest];
  const create = setupAction.value;
  return [...(create ? [create] : []), ...rest.filter(action => action !== create && action !== setupProgress.value)];
});
const canAct = computed(() => props.view.available && props.view.unavailableReason !== "unbound_copy" && Boolean(instance?.vnode.props?.onAction));
/** A direct key the account view draws itself (the setup progress): no confirmation, form or capture to run. */
function runDirect(action: FlarePluginAction): void {
  if (!canAct.value || props.busyActionId || props.offline || action.disabledReason) return;
  emit("action", action.id, action.values ? { input: action.values } : {});
}
const formUnavailableText = computed(() => {
  const title = presentation.value.formTitle;
  const description = presentation.value.formUnavailableDescription;
  const blockingStatus = (props.view.blocks ?? []).some(block => block.kind === "status" && (block.tone === "warning" || block.tone === "danger") && block.text.trim().length > 0);
  return isFlow.value && typeof title === "string" && title.trim().length > 0 && !primaryActions.value.length && !resultText.value && !blockingStatus && typeof description === "string" ? description.trim() : "";
});
function forwardAction(id: string, payload: FlarePluginActionPayload): void { emit("action", id, payload); }
const inlineFormActionId = computed(() => isFlow.value && primaryActions.value.length === 1 && instance?.vnode.props?.onAction ? flarePluginInlineFormAction(props.view, primaryActions.value[0].id)?.id : undefined);
const actionsView = computed<FlarePluginViewModel>(() => ({ ...props.view, presentation: undefined, title: "", fields: [], blocks: [], actions: secondaryActions.value, menuActions: [], detail: false }));
const shortcutsView = computed<FlarePluginViewModel>(() => ({ ...actionsView.value, actions: shortcutActions.value }));
const walletView = computed<FlarePluginViewModel>(() => ({ ...actionsView.value, actions: walletActions.value }));
const groups = computed(() => {
  const out: Array<{ key: string; label: string; entries: AccountEntry[] }> = [];
  for (const entry of entries.value) {
    const key = flareAccountDayKey(entry.atMs);
    if (out.at(-1)?.key !== key) out.push({ key, label: dayLabel(entry.atMs), entries: [] });
    out.at(-1)!.entries.push(entry);
  }
  return out;
});
function dayLabel(at?: number): string {
  if (flareAccountDayKey(at) === "unknown") return t("account.otherEntries");
  const today = new Date(), yesterday = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 1);
  if (flareAccountDayKey(at) === flareAccountDayKey(today.getTime())) return t("account.today");
  if (flareAccountDayKey(at) === flareAccountDayKey(yesterday.getTime())) return t("account.yesterday");
  return new Intl.DateTimeFormat(locale.value, { year: new Date(at!).getFullYear() === today.getFullYear() ? undefined : "numeric", month: "short", day: "numeric" }).format(at);
}
// §5.8 ledger line, as PluginRowsBlock's records: the sign picks the leading icon (income arrow-down, expense send).
const entryIcon = (amount: string) => {
  const sign = flarePluginAmountSign(amount);
  return sign === "in" ? "arrow-down" : sign === "out" ? "send" : "refresh";
};
function timeLabel(at?: number): string { return at === undefined || flareAccountDayKey(at) === "unknown" ? "" : new Intl.DateTimeFormat(locale.value, { hour: "2-digit", minute: "2-digit", hour12: false }).format(at); }
const detailView = computed<FlarePluginViewModel | undefined>(() => {
  const entry = active.value;
  if (!entry) return undefined;
  return { ...props.view, title: "", blocks: [], detail: false, menuActions: [], fields: [
    ...(entry.row.badge ? [{ label: String(presentation.value.rowBadgeLabel ?? t("account.type")), value: entry.row.badge.text, tone: entry.row.badge.tone, unmapped: entry.row.badge.unmapped }] : []),
    ...entry.block.columns.slice(1).map((column, offset) => { const index = offset + 1; const cell = entry.row.cells[index]; return { label: column.label, value: column.format === "time" && cell?.timeMs !== undefined ? flarePluginDateTime(cell.timeMs, flareServerNowMs(), { dateTime: t("pluginView.dateTime"), dateTimeYear: t("pluginView.dateTimeYear") }) : cell?.text ?? "", tone: cell?.tone, unmapped: cell?.unmapped }; }),
    { label: String(presentation.value.rowKeyLabel ?? t("account.entryId")), value: entry.row.key },
  ], actions: entry.row.actions.flatMap(bound => { const action = entry.block.actions.find(action => action.id === bound.id); return action ? [action] : []; }) };
});
function detailAction(id: string, payload: FlarePluginActionPayload): void {
  const entry = active.value, bound = entry?.row.actions.find(action => action.id === id);
  if (entry && bound) emit("action", id, { ...payload, row: { key: entry.row.key, input: bound.input } });
}
function entryAction(entry: AccountEntry) {
  const id = presentation.value.rowEntryAction;
  const bound = typeof id === "string" ? entry.row.actions.find(action => action.id === id) : undefined;
  const action = bound ? entry.block.actions.find(action => action.id === bound.id) : undefined;
  if (props.view.available && props.view.unavailableReason !== "unbound_copy" && instance?.vnode.props?.onAction && bound && action && !action.confirm && !action.form?.length) {
    return {action, bound};
  }
}
function activateEntry(entry: AccountEntry): void {
  if (props.busyActionId || (props.offline && entryAction(entry))) return;
  const direct = entryAction(entry);
  if (direct) emit("action", direct.action.id, { row: { key: entry.row.key, input: direct.bound.input } });
  else selected.value = entry.key;
}
function walletDetails(entry: AccountEntry) {
  return entry.block.columns.flatMap((column, index) => {
    if (index < 2) return [];
    const cell = entry.row.cells[index];
    const value = column.format === "time" && cell?.timeMs !== undefined ? flarePluginDateTime(cell.timeMs, flareServerNowMs(), { dateTime: t("pluginView.dateTime"), dateTimeYear: t("pluginView.dateTimeYear") }) : cell?.text ?? "";
    // A toned cell (the wallet's 正常 / 冻结) is a status: the kit Tag, an unmapped value reads unknown (R3).
    const status = cell && (cell.tone !== undefined || cell.unmapped) ? statusOf(cell, `account:${column.label}`) : undefined;
    return value || status ? [{ label: column.label, value: status?.text ?? value, tone: status?.tone }] : [];
  });
}
/** §12.23 PC card foot: only the status cells (toned or unmapped, R3) of the details. */
function walletStatuses(entry: AccountEntry) { return walletDetails(entry).filter(field => field.tone); }
/** The other wallets' row: the wallet name and its first detail (asset · currency) under it. */
function walletCaption(entry: AccountEntry): string { return walletDetails(entry).find(field => !field.tone)?.value ?? ""; }
function forwardFileAction(event: FlarePluginFileAction): void { emit("fileAction", event); }
</script>

<template>
  <FlarePluginView :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" v-if="!view.available" :view="view" embedded />
  <div v-else class="flare-account-view" :class="{ 'is-wallet': isWallet, 'is-flow': isFlow }">
    <header v-if="layout === 'ledger' && (presentation.contextLabel || presentation.description)" class="flare-account-view__ledger-intro">
      <p v-if="presentation.contextLabel" class="flare-account-view__context">{{ presentation.contextLabel }}</p>
      <p v-if="presentation.description" class="flare-account-view__description">{{ presentation.description }}</p>
    </header>
    <FlarePluginView :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" v-if="layout === 'ledger' && urgent.length" :view="notices" embedded :busy-action-id="busyActionId" :offline="offline" :onAction="instance?.vnode.props?.onAction ? forwardAction : undefined" />
    <FlarePluginView :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" v-if="isWallet && urgent.length" class="flare-account-view__wallet-notices" :view="notices" embedded :busy-action-id="busyActionId" :offline="offline" :onAction="instance?.vnode.props?.onAction ? forwardAction : undefined" />
    <section v-if="isWallet" class="flare-account-view__wallet-overview" :class="{ 'is-phone': phone }" :aria-label="setup ? t('wallet.setupTitle') : walletTitle">
      <template v-if="!setup">
      <header class="flare-account-view__wallet-header">
        <h2>{{ walletTitle }}</h2>
        <FlareIconButton :icon="hidden ? flareIcons['eye-off'] : flareIcons.eye" :ariaLabel="t(hidden ? 'account.showBalance' : 'account.hideBalance')" :aria-pressed="hidden" size="sm" @click="hidden = !hidden" />
      </header>
      <!-- R2.1 / §5.1: the overview card holds the wallet and closes with the quick keys (a phone draws it as one card). -->
      <div class="flare-account-view__overview-card" data-overview-card="true">
      <div class="flare-account-view__wallet-cards">
        <button v-for="entry in overviewEntries" :key="entry.key" type="button" class="flare-account-view__wallet-card" :disabled="Boolean(busyActionId) || (offline && Boolean(entryAction(entry)))" :data-account-entry="entry.row.key" data-wallet-card="true" @click="activateEntry(entry)">
          <span class="flare-account-view__wallet-card-top">
            <span class="flare-account-view__wallet-card-heading"><FlareIcon name="wallet" size="md" aria-hidden="true" /><strong>{{ entry.row.cells[1]?.text ?? entry.title }}</strong><FlareIcon v-if="!entryAction(entry)" name="chevron-right" size="sm" aria-hidden="true" /></span>
            <span class="flare-account-view__wallet-card-balance">
              <span v-if="phone" class="flare-account-view__wallet-card-label">{{ entry.block.columns[0]?.label }}</span>
              <span class="flare-account-view__wallet-card-amount" data-account-balance="true" :aria-label="hidden ? t('account.balanceHidden') : undefined">{{ hidden ? '••••' : entry.amount }}</span>
            </span>
          </span>
          <!-- §12.23 PC: one foot line, the status Tag · 「查看明细 ›」 (no other details). -->
          <span v-if="!phone && (walletStatuses(entry).length || entryAction(entry))" class="flare-account-view__wallet-card-foot is-pc" data-wallet-card-foot="true">
            <template v-for="(field, index) in walletStatuses(entry)" :key="index"><span v-if="index" class="flare-account-view__wallet-card-dot" aria-hidden="true">·</span><FlareTag :label="field.value" :tone="field.tone!" data-wallet-status="true" /></template>
            <span v-if="entryAction(entry)" class="flare-account-view__wallet-card-link"><span v-if="walletStatuses(entry).length" class="flare-account-view__wallet-card-dot" aria-hidden="true">·</span>{{ entryAction(entry)!.action.label }}<FlareIcon name="chevron-right" size="sm" aria-hidden="true" /></span>
          </span>
          <!-- §5.1 phone: the card's details (a phone puts the entry after the quick keys). -->
          <span v-else-if="phone && walletDetails(entry).length" class="flare-account-view__wallet-card-foot">
            <dl class="flare-account-view__wallet-card-details"><div v-for="(field, index) in walletDetails(entry)" :key="index"><dt>{{ field.label }}</dt><dd><FlareTag v-if="field.tone" :label="field.value" :tone="field.tone" data-wallet-status="true" /><template v-else>{{ hidden ? '••••' : field.value }}</template></dd></div></dl>
          </span>
        </button>
      </div>
      <div v-if="walletActions.length" class="flare-account-view__quick-row" :data-wallet-quick-row="phone ? undefined : 'true'">
      <FlarePluginView v-if="walletActions.length" class="flare-account-view__quick" :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" :view="walletView" embedded action-layout="roles" overview-part="quick" :busy-action-id="busyActionId" :error="error" :show-error="false" :form-errors="formErrors" :settle-token="settleToken" :members="members" :members-loading="membersLoading" :members-revision="membersRevision" :members-error="membersError" :on-member-search="instance?.vnode.props?.onMemberSearch ? forwardMemberSearch : undefined" :on-members-retry="instance?.vnode.props?.onMembersRetry ? forwardMembersRetry : undefined" :offline="offline" :onAction="instance?.vnode.props?.onAction ? forwardAction : undefined" />
      </div>
      <!-- §5.1 phone: the card reads wallet, balance, quick keys, then its 「查看明细」 line (the card itself still opens it). -->
      <button v-for="entry in phone ? overviewEntries.filter(entryAction) : []" :key="`entry-${entry.key}`" type="button" class="flare-account-view__wallet-card-entry" :disabled="Boolean(busyActionId) || offline" data-wallet-entry="true" @click="activateEntry(entry)">{{ entryAction(entry)!.action.label }}<FlareIcon name="chevron-right" size="sm" aria-hidden="true" /></button>
      </div>
      <section v-if="otherWallets.length" class="flare-account-view__other-wallets" :aria-label="otherWalletsTitle" data-other-wallets="true">
        <h3>{{ otherWalletsTitle }}</h3>
        <div class="flare-account-view__card-list">
          <button v-for="entry in otherWallets" :key="entry.key" type="button" class="flare-account-view__other-wallet" :disabled="Boolean(busyActionId) || (offline && Boolean(entryAction(entry)))" :data-account-entry="entry.row.key" @click="activateEntry(entry)">
            <span class="flare-account-view__other-wallet-name"><strong>{{ entry.row.cells[1]?.text ?? entry.title }}</strong><span v-if="walletCaption(entry)">{{ walletCaption(entry) }}</span></span>
            <span class="flare-account-view__other-wallet-balance" :aria-label="hidden ? t('account.balanceHidden') : undefined">{{ hidden ? '••••' : entry.amount }}</span>
            <FlareIcon name="chevron-right" size="sm" aria-hidden="true" />
          </button>
        </div>
      </section>
      </template>
      <!-- §5.2: no account yet — the setup state: no balance, no top-up or withdrawal; the opening key, its progress under it. -->
      <div v-else class="flare-account-view__setup" data-account-setup="true" data-account-empty="true">
        <span class="flare-account-view__setup-icon" aria-hidden="true"><FlareIcon name="wallet" size="lg" /></span>
        <h2>{{ t("wallet.setupTitle") }}</h2>
        <p>{{ t("wallet.setupBody") }}</p>
        <FlarePluginView v-if="walletActions.length" class="flare-account-view__setup-keys" :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" :view="walletView" embedded action-layout="roles" overview-part="quick" :busy-action-id="busyActionId" :error="error" :show-error="false" :form-errors="formErrors" :settle-token="settleToken" :members="members" :members-loading="membersLoading" :members-revision="membersRevision" :members-error="membersError" :on-member-search="instance?.vnode.props?.onMemberSearch ? forwardMemberSearch : undefined" :on-members-retry="instance?.vnode.props?.onMembersRetry ? forwardMembersRetry : undefined" :offline="offline" :onAction="instance?.vnode.props?.onAction ? forwardAction : undefined" />
        <FlareButton v-if="setupProgress && canAct" class="flare-account-view__setup-progress" variant="secondary" :size="phone ? 'lg' : 'md'" :block="phone" :label="setupProgress.label" :loading="busyActionId === setupProgress.id" :disabled="Boolean(busyActionId) || offline || Boolean(setupProgress.disabledReason)" :data-action-id="setupProgress.id" data-action-variant="secondary" @click="runDirect(setupProgress)" />
      </div>
    </section>
    <section v-if="!isFlow && !isWallet && view.fields.length" class="flare-account-view__balance" :aria-label="view.fields[0].label">
        <div class="flare-account-view__balance-label"><span>{{ view.fields[0].label }}</span><FlareIconButton :icon="hidden ? flareIcons['eye-off'] : flareIcons.eye" :ariaLabel="t(hidden ? 'account.showBalance' : 'account.hideBalance')" :aria-pressed="hidden" size="sm" @click="hidden = !hidden" /></div>
        <p class="flare-account-view__amount" :aria-label="hidden ? t('account.balanceHidden') : undefined" data-account-balance="true">{{ hidden ? '••••' : flarePluginMoneyFormatted(view.fields[0].value, view.fields[0].format) }}</p>
      <dl v-if="view.fields.length > 1" class="flare-account-view__stats"><div v-for="(field, index) in view.fields.slice(1)" :key="index"><dt>{{ field.label }}</dt><dd>{{ hidden ? '••••' : flarePluginMoneyFormatted(field.value, field.format) }}</dd></div></dl>
    </section>
    <template v-if="isFlow">
      <header v-if="presentation.stepLabel || presentation.description || presentation.summaryTitle" class="flare-account-view__flow-intro">
        <p v-if="presentation.stepLabel" class="flare-account-view__step">{{ presentation.stepLabel }}</p>
        <h2 v-if="presentation.summaryTitle">{{ presentation.summaryTitle }}</h2>
        <p v-if="presentation.description" class="flare-account-view__description">{{ presentation.description }}</p>
      </header>
      <FlareStatusBanner v-if="resultText" :text="resultText" :tone="resultTone" :dot="false" class="flare-account-view__result" data-flow-result="true" />
      <FlareStatusBanner v-if="formUnavailableText" :text="formUnavailableText" tone="neutral" :dot="false" data-flow-form-unavailable="true" />
      <section class="flare-account-view__flow">
        <h2 v-if="presentation.sectionTitle">{{ presentation.sectionTitle }}</h2>
        <FlarePluginView :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" :view="receiptView" embedded rows-layout="list" label-rows action-layout="compact" :inline-form-action-id="inlineFormActionId" :inline-form-title="typeof presentation.formTitle === 'string' ? presentation.formTitle : undefined" :inline-form-description="typeof presentation.formDescription === 'string' ? presentation.formDescription : undefined" :resolve-user="resolveUser" :viewer-id="viewerId" :busy-action-id="busyActionId" :error="error" :show-error="false" :form-errors="formErrors" :settle-token="settleToken" :members="members" :members-loading="membersLoading" :members-revision="membersRevision" :members-error="membersError" :on-member-search="instance?.vnode.props?.onMemberSearch ? forwardMemberSearch : undefined" :on-members-retry="instance?.vnode.props?.onMembersRetry ? forwardMembersRetry : undefined" :offline="offline" :onAction="instance?.vnode.props?.onAction ? forwardAction : undefined" />
      </section>
    </template>
    <FlarePluginView :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" v-if="!isFlow && !isWallet && layout !== 'ledger' && urgent.length" :view="notices" embedded :busy-action-id="busyActionId" :offline="offline" :onAction="instance?.vnode.props?.onAction ? forwardAction : undefined" />
    <FlareStatusBanner v-if="error && !active && !inlineFormActionId" :text="error" tone="danger" :dot="false" />
    <section v-if="hasLedger" class="flare-account-view__ledger" :aria-label="String(presentation.sectionTitle ?? t('account.transactions'))">
      <h2 v-if="view.fields.length || presentation.sectionTitle">{{ typeof view.presentation?.props.sectionTitle === 'string' ? view.presentation.props.sectionTitle : t('account.transactions') }}</h2>
      <template v-for="(group, groupIndex) in groups" :key="`${group.key}-${groupIndex}`">
        <h3 v-if="presentation.groupByDate === true || (presentation.groupByDate !== false && !isWallet)" class="flare-account-view__date">{{ group.label }}</h3>
        <ul class="flare-account-view__list"><li v-for="entry in group.entries" :key="entry.key">
          <button type="button" class="flare-account-view__entry" :disabled="Boolean(busyActionId)" :data-account-entry="entry.row.key" @click="activateEntry(entry)">
            <span class="flare-account-view__entry-icon" :class="flarePluginAmountSign(entry.amount) && `is-${flarePluginAmountSign(entry.amount)}`" aria-hidden="true"><FlareIcon :name="entryIcon(entry.amount)" size="md" /></span>
            <!-- §5.8: title, then the line under it (subtitle · time); the amount ends the row with its status Tag under it. -->
            <span class="flare-account-view__entry-main"><strong>{{ entry.title }}</strong><span v-if="entry.subtitle || timeLabel(entry.atMs)">{{ entry.subtitle }}<template v-if="entry.subtitle && timeLabel(entry.atMs)"> · </template><time v-if="timeLabel(entry.atMs)" :datetime="new Date(entry.atMs!).toISOString()">{{ timeLabel(entry.atMs) }}</time></span></span>
            <span class="flare-account-view__entry-value"><b :class="{ 'is-positive': flarePluginAmountSign(entry.amount) === 'in' }">{{ hidden && presentation.maskRowAmounts === true ? '••••' : flarePluginDisplayAmount(entry.amount) }}</b><FlareTag v-if="separateBadge && entry.row.badge && (entry.row.badge.unmapped || entry.row.badge.tone !== 'success')" v-bind="{ label: statusOf(entry.row.badge, 'account:badge')!.text, tone: statusOf(entry.row.badge, 'account:badge')!.tone }" data-account-badge="true" /></span>
          </button>
        </li></ul>
      </template>
      <FlareEmptyState v-if="!entries.length" compact icon="clock" :title="typeof presentation.emptyTitle === 'string' ? presentation.emptyTitle : t('account.empty')" :description="typeof presentation.emptyDescription === 'string' ? presentation.emptyDescription : t('account.emptyDescription')" data-account-empty="true" />
    </section>
    <section v-if="shortcutActions.length" class="flare-account-view__shortcuts">
      <h2 v-if="presentation.shortcutsTitle">{{ presentation.shortcutsTitle }}</h2>
      <FlarePluginView :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" :view="shortcutsView" embedded action-layout="compact" :busy-action-id="busyActionId" :error="error" :show-error="false" :form-errors="formErrors" :settle-token="settleToken" :members="members" :members-loading="membersLoading" :members-revision="membersRevision" :members-error="membersError" :on-member-search="instance?.vnode.props?.onMemberSearch ? forwardMemberSearch : undefined" :on-members-retry="instance?.vnode.props?.onMembersRetry ? forwardMembersRetry : undefined" :offline="offline" :onAction="instance?.vnode.props?.onAction ? forwardAction : undefined" />
    </section>
    <section v-if="(isWallet ? walletActions.length : secondaryActions.length) || (!isFlow && hasInformation)" class="flare-account-view__navigation">
      <h2 v-if="presentation.servicesTitle">{{ presentation.servicesTitle }}</h2>
      <!-- W-06: the account information is a row of the destination list that opens its panel, not a floating fold. -->
      <div v-if="!isFlow && hasInformation" class="flare-account-view__card-list">
        <FlareSettingsRow :item="{ key: 'information', label: String(presentation.informationTitle ?? t('account.information')), kind: 'navigation' }" data-account-information="true" @select="informationOpen = true" />
      </div>
      <!-- R2.1: the wallet's list cards by group (common, records and settings) with each action's icon, then the danger card. -->
      <FlarePluginView v-if="isWallet && walletActions.length" :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" :view="walletView" embedded action-layout="roles" overview-part="lists" :busy-action-id="busyActionId" :error="error" :show-error="false" :form-errors="formErrors" :settle-token="settleToken" :members="members" :members-loading="membersLoading" :members-revision="membersRevision" :members-error="membersError" :on-member-search="instance?.vnode.props?.onMemberSearch ? forwardMemberSearch : undefined" :on-members-retry="instance?.vnode.props?.onMembersRetry ? forwardMembersRetry : undefined" :offline="offline" :onAction="instance?.vnode.props?.onAction ? forwardAction : undefined" />
      <FlarePluginView v-else-if="!isWallet && secondaryActions.length" :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" :view="actionsView" embedded action-layout="list" :busy-action-id="busyActionId" :error="error" :show-error="false" :form-errors="formErrors" :settle-token="settleToken" :members="members" :members-loading="membersLoading" :members-revision="membersRevision" :members-error="membersError" :on-member-search="instance?.vnode.props?.onMemberSearch ? forwardMemberSearch : undefined" :on-members-retry="instance?.vnode.props?.onMembersRetry ? forwardMembersRetry : undefined" :offline="offline" :onAction="instance?.vnode.props?.onAction ? forwardAction : undefined" />
    </section>
    <FlareBottomSheet :open="informationOpen" :title="String(presentation.informationTitle ?? t('account.information'))" show-close max-height="80vh" @close="informationOpen = false">
      <div v-if="informationOpen" class="flare-account-view__detail" data-account-information-panel="true"><FlarePluginView :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" :view="extraView" embedded :resolve-user="resolveUser" :viewer-id="viewerId" /></div>
    </FlareBottomSheet>
    <FlareBottomSheet :open="Boolean(active)" :title="detailTitle" show-close max-height="80vh" @close="selected = undefined">
      <div v-if="active && detailView" class="flare-account-view__detail"><p class="flare-account-view__detail-label">{{ active.block.columns[0]?.label }}</p><p class="flare-account-view__detail-amount">{{ hidden && (isWallet || presentation.maskRowAmounts === true) ? '••••' : active.amount }}</p><FlarePluginView :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" :view="detailView" embedded :busy-action-id="busyActionId" :error="error" :form-errors="formErrors" :settle-token="settleToken" :members="members" :members-loading="membersLoading" :members-revision="membersRevision" :members-error="membersError" :on-member-search="instance?.vnode.props?.onMemberSearch ? forwardMemberSearch : undefined" :on-members-retry="instance?.vnode.props?.onMembersRetry ? forwardMembersRetry : undefined" :offline="offline" :onAction="instance?.vnode.props?.onAction ? detailAction : undefined" /></div>
    </FlareBottomSheet>
  </div>
</template>

<style scoped>
.flare-account-view { display: grid; gap: var(--flare-size-spacing-md); width: 100%; max-width: var(--flare-size-layout-directory-content-max-width); margin-inline: auto; min-width: 0; }
.flare-account-view__balance, .flare-account-view__flow { padding: var(--flare-size-spacing-lg); border-radius: var(--flare-size-radius-lg); background: var(--flare-color-bg-secondary); }
.flare-account-view__wallet-overview { display: grid; gap: var(--flare-size-spacing-sm); min-width: 0; }
.flare-account-view__wallet-header { display: flex; align-items: center; flex-wrap: wrap; gap: var(--flare-size-spacing-xs); }
/* R2.1 / §5.1: the wallet and its quick keys; on a phone one card (bg.primary, radius.card), the wallet flat inside it. */
.flare-account-view__overview-card { display: grid; gap: var(--flare-size-spacing-lg); min-width: 0; }
.flare-account-view__overview-card .flare-account-view__quick :deep(.flare-plugin-view__quick) { margin-top: 0; }
.flare-account-view__quick-row { display: flex; align-items: center; gap: var(--flare-size-spacing-sm); min-width: 0; }
.flare-account-view__quick-row > .flare-account-view__quick { flex: 1 1 auto; min-width: 0; }
.is-phone .flare-account-view__overview-card { padding: var(--flare-size-spacing-lg); border: 1px solid var(--flare-color-border-secondary); border-radius: var(--flare-size-radius-card); background: var(--flare-color-bg-primary); }
.is-phone .flare-account-view__overview-card .flare-account-view__wallet-card { padding: 0; border: 0; background: transparent; }
/* §5.2 setup state: wallet 48 circle (bg.selected), title 20/700, body 13 secondary, the key full width on a phone, 200 elsewhere. */
.flare-account-view__setup { display: grid; justify-items: center; gap: var(--flare-size-spacing-md); padding-block: var(--flare-size-spacing-2xl); text-align: center; }
.flare-account-view__setup-icon { display: inline-flex; align-items: center; justify-content: center; width: var(--flare-size-layout-control-height-lg); height: var(--flare-size-layout-control-height-lg); border-radius: var(--flare-size-radius-full); background: var(--flare-color-bg-selected); color: var(--flare-color-primary-text); }
.flare-account-view__setup h2 { margin: 0; font-size: var(--flare-size-font-size-4xl); font-weight: var(--flare-size-font-weight-bold); }
.flare-account-view__setup p { margin: 0; color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-md); line-height: var(--flare-size-line-height-relaxed); }
.flare-account-view__setup-keys :deep(.flare-plugin-view__quick) { justify-content: center; margin-top: 0; }
.flare-account-view__wallet-overview:not(.is-phone) .flare-account-view__setup-keys :deep(.flare-plugin-view__quick > .flare-button),
.flare-account-view__wallet-overview:not(.is-phone) .flare-account-view__setup-progress { width: var(--flare-size-component-account-setup-action-width); }
.is-phone .flare-account-view__setup > .flare-plugin-view, .is-phone .flare-account-view__setup-progress { justify-self: stretch; }
.flare-account-view__wallet-header h2, .flare-account-view__navigation h2, .flare-account-view__shortcuts h2 { margin: 0; font-size: var(--flare-size-font-size-xl); font-weight: var(--flare-size-font-weight-semibold); }
.flare-account-view__wallet-cards { display: grid; align-items: start; grid-template-columns: repeat(auto-fit, minmax(min(100%, max(var(--flare-size-layout-primary-pane-min-width), calc((100% - var(--flare-size-spacing-md)) / 2))), 1fr)); gap: var(--flare-size-spacing-sm); }
.flare-account-view__wallet-card { display: grid; min-width: 0; width: 100%; gap: var(--flare-size-spacing-sm); padding: var(--flare-size-spacing-lg); border: 1px solid var(--flare-color-border-secondary); border-radius: var(--flare-size-radius-card); background: var(--flare-color-bg-primary); color: var(--flare-color-text-primary); font: inherit; text-align: start; cursor: pointer; }
.flare-account-view__wallet-card:hover { border-color: var(--flare-color-border-primary); }
.flare-account-view__wallet-card:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-account-view__wallet-card:disabled { cursor: default; opacity: var(--flare-opacity-disabled); }
/* §5.1: the wallet's name, then its balance under it at the start. */
.flare-account-view__wallet-card-top { display: grid; gap: var(--flare-size-spacing-xs); min-width: 0; }
.flare-account-view__wallet-card-heading { display: flex; flex: 1; align-items: center; gap: var(--flare-size-spacing-sm); min-width: 0; }
.flare-account-view__wallet-card-heading strong { flex: 1; min-width: 0; overflow-wrap: anywhere; font-size: var(--flare-size-font-size-lg); font-weight: var(--flare-size-font-weight-semibold); line-height: var(--flare-size-line-height-snug); }
.flare-account-view__wallet-card-balance { display: grid; gap: var(--flare-size-spacing-2xs); min-width: 0; }
.flare-account-view__wallet-card-heading > .flare-icon { flex: none; color: var(--flare-color-text-secondary); }
.flare-account-view__wallet-card-heading > .flare-icon:first-child { color: var(--flare-color-primary-text); }
.flare-account-view__wallet-card-label { color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); }
.flare-account-view__wallet-card-amount { font-size: var(--flare-size-component-amount-hero-font-size); font-weight: var(--flare-size-font-weight-bold); line-height: var(--flare-size-line-height-snug); font-variant-numeric: tabular-nums; overflow-wrap: anywhere; }
.flare-account-view__wallet-card-details { display: flex; flex-wrap: wrap; column-gap: var(--flare-size-spacing-md); row-gap: var(--flare-size-spacing-xs); margin: 0; }
.flare-account-view__wallet-card-details > div { display: flex; flex-wrap: wrap; align-items: baseline; gap: var(--flare-size-spacing-xs); font-size: var(--flare-size-font-size-sm); min-width: 0; }
.flare-account-view__wallet-card-details dt { color: var(--flare-color-text-secondary); overflow-wrap: anywhere; }
.flare-account-view__wallet-card-details dd { margin: 0; font-size: var(--flare-size-font-size-sm); font-weight: var(--flare-size-font-weight-medium); overflow-wrap: anywhere; }
.flare-account-view__wallet-card-entry { display: flex; align-items: center; justify-content: space-between; gap: var(--flare-size-spacing-sm); padding-top: var(--flare-size-spacing-sm); border-top: 1px solid var(--flare-color-border-secondary); color: var(--flare-color-primary-text); font-size: var(--flare-size-font-size-sm); font-weight: var(--flare-size-font-weight-medium); }
.flare-account-view__wallet-card-foot.is-pc { justify-content: flex-start; gap: var(--flare-size-spacing-xs); }
.flare-account-view__wallet-card-foot.is-pc .flare-account-view__wallet-card-link { margin-inline-start: 0; gap: var(--flare-size-spacing-xs); }
.flare-account-view__wallet-card-dot { color: var(--flare-color-text-tertiary); font-size: var(--flare-size-font-size-sm); }
.flare-account-view__wallet-card-foot { display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: var(--flare-size-spacing-xs) var(--flare-size-spacing-md); min-width: 0; }
.flare-account-view__wallet-card-link { display: inline-flex; align-items: center; gap: var(--flare-size-spacing-2xs); margin-inline-start: auto; color: var(--flare-color-primary-text); font-size: var(--flare-size-font-size-sm); font-weight: var(--flare-size-font-weight-medium); white-space: nowrap; }
button.flare-account-view__wallet-card-entry { width: 100%; margin: 0; padding-inline: 0; padding-bottom: 0; border-width: 1px 0 0; background: none; font-family: inherit; text-align: start; cursor: pointer; }
button.flare-account-view__wallet-card-entry:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
button.flare-account-view__wallet-card-entry:disabled { cursor: default; opacity: var(--flare-opacity-disabled); }
.flare-account-view__shortcuts { min-width: 0; }
.flare-account-view__shortcuts h2 { margin-bottom: var(--flare-size-spacing-md); }
.flare-account-view__context { margin: 0; color: var(--flare-color-text-primary); font-size: var(--flare-size-font-size-md); font-weight: var(--flare-size-font-weight-medium); overflow-wrap: anywhere; }
.flare-account-view__wallet-notices { margin-top: var(--flare-size-spacing-md); }
.flare-account-view__flow-intro, .flare-account-view__ledger-intro { display: grid; gap: var(--flare-size-spacing-sm); }
.flare-account-view__result { white-space: pre-line; }
.flare-account-view__flow-intro h2 { margin: 0; font-size: var(--flare-size-font-size-xl); font-weight: var(--flare-size-font-weight-semibold); }
.flare-account-view__flow > h2 { margin: 0 0 var(--flare-size-spacing-md); font-size: var(--flare-size-font-size-xl); font-weight: var(--flare-size-font-weight-semibold); }
.flare-account-view__step { margin: 0; color: var(--flare-color-primary-text); font-size: var(--flare-size-font-size-sm); font-weight: var(--flare-size-font-weight-semibold); }
.flare-account-view__description { margin: 0; color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); line-height: var(--flare-size-line-height-relaxed); overflow-wrap: anywhere; }
.flare-account-view__balance-label { display: flex; align-items: center; gap: var(--flare-size-spacing-xs); color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-md); }
.flare-account-view__amount { margin: var(--flare-size-spacing-xs) 0 0; color: var(--flare-color-text-primary); font-size: var(--flare-size-component-amount-hero-font-size); font-weight: var(--flare-size-font-weight-bold); line-height: var(--flare-size-line-height-snug); font-variant-numeric: tabular-nums; overflow-wrap: anywhere; }
.flare-account-view__stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(min(100%, 6em), 1fr)); gap: var(--flare-size-spacing-md); padding-top: var(--flare-size-spacing-lg); border-top: 1px solid var(--flare-color-border-secondary); margin: 0; }
.flare-account-view__stats dt { color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); }
.flare-account-view__stats dd { margin: var(--flare-size-spacing-xs) 0 0; font-size: var(--flare-size-font-size-lg); font-weight: var(--flare-size-font-weight-medium); font-variant-numeric: tabular-nums; overflow-wrap: anywhere; }
.flare-account-view__navigation { min-width: 0; }
.flare-account-view__navigation > .flare-plugin-view:not(.has-actions-roles) { padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg); border-radius: var(--flare-size-radius-lg); background: var(--flare-color-bg-secondary); }
.flare-account-view__navigation h2 { margin-bottom: var(--flare-size-spacing-md); }
.flare-account-view__ledger { min-width: 0; }
.flare-account-view__ledger h2 { margin: 0 0 var(--flare-size-spacing-md); font-size: var(--flare-size-font-size-3xl); font-weight: var(--flare-size-font-weight-semibold); }
/* Day headings stay while their entries scroll under them (§5.8). */
.flare-account-view__date { position: sticky; top: 0; z-index: 1; margin: var(--flare-size-spacing-lg) 0 var(--flare-size-spacing-xs); padding-block: var(--flare-size-spacing-xs); background: var(--flare-color-bg-primary); font-size: var(--flare-size-font-size-sm); font-weight: var(--flare-size-font-weight-semibold); color: var(--flare-color-text-secondary); }
.flare-account-view__date:first-of-type { margin-top: 0; }
.flare-account-view__list { list-style: none; margin: 0; padding: 0; }
.flare-account-view__list > li + li { border-top: 1px solid var(--flare-color-border-secondary); }
.flare-account-view__entry { display: flex; align-items: center; gap: var(--flare-size-spacing-md); width: 100%; min-height: var(--flare-size-component-record-row-height); padding: var(--flare-size-spacing-md) 0; border: 0; border-radius: var(--flare-size-radius-sm); background: transparent; color: var(--flare-color-text-primary); font: inherit; text-align: start; cursor: pointer; }
.flare-account-view__entry:hover { background: var(--flare-color-bg-hover); }
.flare-account-view__entry:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-account-view__entry:disabled { cursor: default; opacity: var(--flare-opacity-disabled); }
/* The 36 circle of the §5.8 ledger line (the same as PluginRowsBlock's records). */
.flare-account-view__entry-icon { flex: none; display: grid; place-items: center; width: var(--flare-size-component-record-icon-size); height: var(--flare-size-component-record-icon-size); border-radius: var(--flare-size-radius-full); background: var(--flare-color-bg-tertiary); color: var(--flare-color-text-secondary); }
.flare-account-view__entry-icon.is-in { background: color-mix(in srgb, var(--flare-color-success) calc(var(--flare-opacity-tint-weak) * 100%), var(--flare-color-bg-primary)); color: var(--flare-color-success-text); }
.flare-account-view__entry-main { display: grid; flex: 1 1 auto; min-width: 0; gap: var(--flare-size-spacing-2xs); }
.flare-account-view__entry-main strong { font-size: var(--flare-size-font-size-xl); font-weight: var(--flare-size-font-weight-regular); overflow-wrap: anywhere; }
.flare-account-view__entry-main > span { font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-secondary); overflow-wrap: anywhere; }
.flare-account-view__entry-value { display: grid; flex: 0 0 auto; min-width: 0; max-width: 46%; justify-items: end; gap: var(--flare-size-spacing-2xs); text-align: end; font-variant-numeric: tabular-nums; }
.flare-account-view__entry-value b { font-size: var(--flare-size-font-size-2xl); font-weight: var(--flare-size-font-weight-semibold); overflow-wrap: anywhere; }
.flare-account-view__entry-value b.is-positive { color: var(--flare-color-success-text); }
.flare-account-view__entry-main time { color: var(--flare-color-text-tertiary); font-size: var(--flare-size-font-size-sm); }
.flare-account-view__card-list { display: grid; overflow: hidden; border: 1px solid var(--flare-color-border-secondary); border-radius: var(--flare-size-radius-card); background: var(--flare-color-bg-primary); }
.flare-account-view__card-list + .flare-plugin-view { margin-top: var(--flare-size-spacing-md); }
.flare-account-view__other-wallets { display: grid; gap: var(--flare-size-spacing-sm); margin-top: var(--flare-size-spacing-lg); }
.flare-account-view__other-wallets h3 { margin: 0; font-size: var(--flare-size-font-size-md); font-weight: var(--flare-size-font-weight-semibold); color: var(--flare-color-text-secondary); }
.flare-account-view__other-wallet { display: flex; align-items: center; gap: var(--flare-size-spacing-md); width: 100%; min-height: var(--flare-size-layout-touch-target); padding: var(--flare-size-spacing-md) var(--flare-size-spacing-lg); border: 0; background: transparent; color: var(--flare-color-text-primary); font: inherit; text-align: start; cursor: pointer; }
.flare-account-view__other-wallet + .flare-account-view__other-wallet { border-top: 1px solid var(--flare-color-border-secondary); }
.flare-account-view__other-wallet:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
.flare-account-view__other-wallet:disabled { cursor: default; opacity: var(--flare-opacity-disabled); }
.flare-account-view__other-wallet > .flare-icon { flex: none; color: var(--flare-color-text-tertiary); }
.flare-account-view__other-wallet-name { display: grid; flex: 1; min-width: 0; gap: var(--flare-size-spacing-3xs); }
.flare-account-view__other-wallet-name strong { font-size: var(--flare-size-font-size-xl); font-weight: var(--flare-size-font-weight-medium); overflow-wrap: anywhere; }
.flare-account-view__other-wallet-name span { font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-secondary); overflow-wrap: anywhere; }
.flare-account-view__other-wallet-balance { flex: none; max-width: 45%; font-size: var(--flare-size-font-size-2xl); font-weight: var(--flare-size-font-weight-semibold); font-variant-numeric: tabular-nums; overflow-wrap: anywhere; text-align: end; }
@media (hover: hover) { .flare-account-view__other-wallet:hover:not(:disabled) { background: var(--flare-color-bg-hover); } }
.flare-account-view__detail { padding: var(--flare-size-spacing-md) var(--flare-size-spacing-lg) var(--flare-size-spacing-xl); }
.flare-account-view__detail-amount { margin: 0 0 var(--flare-size-spacing-xl); font-size: var(--flare-size-font-size-5xl); font-weight: var(--flare-size-font-weight-semibold); text-align: center; font-variant-numeric: tabular-nums; overflow-wrap: anywhere; }
.flare-account-view__detail-label { margin: 0 0 var(--flare-size-spacing-xs); color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); text-align: center; }
</style>
