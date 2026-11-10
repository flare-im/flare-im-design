<script setup lang="ts">
import { computed, getCurrentInstance, ref, watch } from "vue";
import FlareIcon from "../../general/FlareIcon.vue";
import FlareIconButton from "../../general/FlareIconButton.vue";
import FlareBottomSheet from "../../general/FlareBottomSheet.vue";
import FlareEmptyState from "../../general/FlareEmptyState.vue";
import FlareStatusBanner from "../../general/FlareStatusBanner.vue";
import FlareTag from "../../general/FlareTag.vue";
import FlarePluginView from "../FlarePluginView.vue";
import { flareIcons } from "../../../shared/icons";
import { flareServerNowMs } from "../../../shared/server-clock";
import { useFlareI18nOptional, useFlareLocaleOptional } from "../../../shared/i18n/useFlareI18n";
import { flarePluginBadgeTone, flarePluginDateTime, flarePluginInlineFormAction, type FlarePluginActionPayload, type FlarePluginFormError, type FlarePluginFileState, type FlarePluginFileAction, type FlarePluginMember, type FlarePluginResolveUser, type FlarePluginViewModel } from "../../../shared/contracts/plugin-ui";
import { flareAccountDayKey, flareAccountEntries, type AccountEntry } from "./account";
import type { FlareTone } from "../../../shared/contracts/tone";

const props = withDefaults(defineProps<{
  view: FlarePluginViewModel; busyActionId?: string; error?: string; formErrors?: FlarePluginFormError[];
  fileStates?: Record<string, FlarePluginFileState>;
  settleToken?: number; members?: FlarePluginMember[];
    membersLoading?: boolean;
    membersRevision?: number;
    membersError?: string;
    onMemberSearch?: (query: string) => void;
    onMembersRetry?: () => void; resolveUser?: FlarePluginResolveUser; viewerId?: string;
}>(), { busyActionId: undefined, error: undefined, formErrors: () => [], settleToken: 0, members: () => [], resolveUser: undefined, viewerId: undefined });
const emit = defineEmits<{ action: [id: string, payload: FlarePluginActionPayload]; fileAction: [event: FlarePluginFileAction] }>();
const { t } = useFlareI18nOptional();
const locale = useFlareLocaleOptional();
const instance = getCurrentInstance();
const hidden = ref(false), selected = ref<string>();
const entries = computed(() => flareAccountEntries(props.view));
const active = computed(() => entries.value.find(entry => entry.key === selected.value));
watch(() => props.view, () => { if (selected.value && !active.value) selected.value = undefined; });
const urgent = computed(() => (props.view.blocks ?? []).filter(block => {
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
const formUnavailableText = computed(() => {
  const title = presentation.value.formTitle;
  const description = presentation.value.formUnavailableDescription;
  const blockingStatus = (props.view.blocks ?? []).some(block => block.kind === "status" && (block.tone === "warning" || block.tone === "danger") && block.text.trim().length > 0);
  return isFlow.value && typeof title === "string" && title.trim().length > 0 && !primaryActions.value.length && !resultText.value && !blockingStatus && typeof description === "string" ? description.trim() : "";
});
function forwardAction(id: string, payload: FlarePluginActionPayload): void { emit("action", id, payload); }
const inlineFormActionId = computed(() => isFlow.value && primaryActions.value.length === 1 && instance?.vnode.props?.onAction ? flarePluginInlineFormAction(props.view, primaryActions.value[0].id)?.id : undefined);
const primaryView = computed<FlarePluginViewModel>(() => ({ ...props.view, presentation: undefined, title: "", fields: [], blocks: [], actions: primaryActions.value, menuActions: [], detail: false }));
const actionsView = computed<FlarePluginViewModel>(() => ({ ...props.view, presentation: undefined, title: "", fields: [], blocks: [], actions: secondaryActions.value, menuActions: [], detail: false }));
const shortcutsView = computed<FlarePluginViewModel>(() => ({ ...actionsView.value, actions: shortcutActions.value }));
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
function timeLabel(at?: number): string { return at === undefined || flareAccountDayKey(at) === "unknown" ? "" : new Intl.DateTimeFormat(locale.value, { hour: "2-digit", minute: "2-digit", hour12: false }).format(at); }
const detailView = computed<FlarePluginViewModel | undefined>(() => {
  const entry = active.value;
  if (!entry) return undefined;
  return { ...props.view, title: "", blocks: [], detail: false, menuActions: [], fields: [
    ...(entry.row.badge ? [{ label: String(presentation.value.rowBadgeLabel ?? t("account.type")), value: entry.row.badge.text }] : []),
    ...entry.block.columns.slice(1).map((column, offset) => { const index = offset + 1; const cell = entry.row.cells[index]; return { label: column.label, value: column.format === "time" && cell?.timeMs !== undefined ? flarePluginDateTime(cell.timeMs, flareServerNowMs(), { dateTime: t("pluginView.dateTime"), dateTimeYear: t("pluginView.dateTimeYear") }) : cell?.text ?? "" }; }),
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
  if (props.busyActionId) return;
  const direct = entryAction(entry);
  if (direct) emit("action", direct.action.id, { row: { key: entry.row.key, input: direct.bound.input } });
  else selected.value = entry.key;
}
function walletDetails(entry: AccountEntry) {
  return entry.block.columns.flatMap((column, index) => {
    if (index < 2) return [];
    const cell = entry.row.cells[index];
    const value = column.format === "time" && cell?.timeMs !== undefined ? flarePluginDateTime(cell.timeMs, flareServerNowMs(), { dateTime: t("pluginView.dateTime"), dateTimeYear: t("pluginView.dateTimeYear") }) : cell?.text ?? "";
    return value ? [{ label: column.label, value }] : [];
  });
}
function forwardFileAction(event: FlarePluginFileAction): void { emit("fileAction", event); }
</script>

<template>
  <FlarePluginView :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" v-if="!view.available" :view="view" embedded />
  <div v-else class="flare-account-view" :class="{ 'is-wallet': isWallet, 'is-flow': isFlow }">
    <header v-if="layout === 'ledger' && (presentation.contextLabel || presentation.description)" class="flare-account-view__ledger-intro">
      <p v-if="presentation.contextLabel" class="flare-account-view__context">{{ presentation.contextLabel }}</p>
      <p v-if="presentation.description" class="flare-account-view__description">{{ presentation.description }}</p>
    </header>
    <FlarePluginView :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" v-if="layout === 'ledger' && urgent.length" :view="notices" embedded />
    <section v-if="isWallet" class="flare-account-view__wallet-overview" :aria-label="walletTitle">
      <header class="flare-account-view__wallet-header">
        <h2>{{ walletTitle }}</h2>
        <div class="flare-account-view__wallet-controls">
          <FlarePluginView :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" v-if="primaryActions.length" :view="primaryView" embedded action-layout="compact" :busy-action-id="busyActionId" :error="error" :show-error="false" :form-errors="formErrors" :settle-token="settleToken" :members="members" :members-loading="membersLoading" :members-revision="membersRevision" :members-error="membersError" :on-member-search="onMemberSearch" :on-members-retry="onMembersRetry" :onAction="instance?.vnode.props?.onAction ? forwardAction : undefined" />
          <FlareIconButton :icon="hidden ? flareIcons['eye-off'] : flareIcons.eye" :ariaLabel="t(hidden ? 'account.showBalance' : 'account.hideBalance')" size="sm" @click="hidden = !hidden" />
        </div>
      </header>
      <FlarePluginView :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" v-if="urgent.length" class="flare-account-view__wallet-notices" :view="notices" embedded />
      <div v-if="entries.length" class="flare-account-view__wallet-cards">
        <button v-for="entry in entries" :key="entry.key" type="button" class="flare-account-view__wallet-card" :disabled="Boolean(busyActionId)" :data-account-entry="entry.row.key" data-wallet-card="true" @click="activateEntry(entry)">
          <span class="flare-account-view__wallet-card-heading"><FlareIcon name="wallet" :size="20" aria-hidden="true" /><strong>{{ entry.row.cells[1]?.text ?? entry.title }}</strong><FlareIcon v-if="!entryAction(entry)" name="chevron-right" :size="16" aria-hidden="true" /></span>
          <span class="flare-account-view__wallet-card-label">{{ entry.block.columns[0]?.label }}</span>
          <span class="flare-account-view__wallet-card-amount" data-account-balance="true" :aria-label="hidden ? t('account.balanceHidden') : undefined">{{ hidden ? '••••' : entry.amount }}</span>
          <dl v-if="walletDetails(entry).length" class="flare-account-view__wallet-card-details"><div v-for="(field, index) in walletDetails(entry)" :key="index"><dt>{{ field.label }}</dt><dd>{{ hidden ? '••••' : field.value }}</dd></div></dl>
          <span v-if="entryAction(entry)" class="flare-account-view__wallet-card-entry">{{ entryAction(entry)!.action.label }}<FlareIcon name="chevron-right" :size="16" aria-hidden="true" /></span>
        </button>
      </div>
      <template v-else>
        <div v-if="view.fields.length" class="flare-account-view__balance"><span class="flare-account-view__wallet-card-label">{{ view.fields[0].label }}</span><p class="flare-account-view__amount" data-account-balance="true">{{ hidden ? '••••' : view.fields[0].value }}</p></div>
        <FlareEmptyState icon="wallet" :title="String(presentation.emptyTitle ?? t('account.empty'))" :description="String(presentation.emptyDescription ?? t('account.emptyDescription'))" data-account-empty="true" />
      </template>
    </section>
    <section v-if="!isFlow && !isWallet && view.fields.length" class="flare-account-view__balance" :aria-label="view.fields[0].label">
        <div class="flare-account-view__balance-label"><span>{{ view.fields[0].label }}</span><FlareIconButton :icon="hidden ? flareIcons['eye-off'] : flareIcons.eye" :ariaLabel="t(hidden ? 'account.showBalance' : 'account.hideBalance')" size="sm" @click="hidden = !hidden" /></div>
        <p class="flare-account-view__amount" :aria-label="hidden ? t('account.balanceHidden') : undefined" data-account-balance="true">{{ hidden ? '••••' : view.fields[0].value }}</p>
      <dl v-if="view.fields.length > 1" class="flare-account-view__stats"><div v-for="(field, index) in view.fields.slice(1)" :key="index"><dt>{{ field.label }}</dt><dd>{{ hidden ? '••••' : field.value }}</dd></div></dl>
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
        <FlarePluginView :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" :view="receiptView" embedded rows-layout="list" label-rows action-layout="compact" :inline-form-action-id="inlineFormActionId" :inline-form-title="typeof presentation.formTitle === 'string' ? presentation.formTitle : undefined" :inline-form-description="typeof presentation.formDescription === 'string' ? presentation.formDescription : undefined" :resolve-user="resolveUser" :viewer-id="viewerId" :busy-action-id="busyActionId" :error="error" :show-error="false" :form-errors="formErrors" :settle-token="settleToken" :members="members" :members-loading="membersLoading" :members-revision="membersRevision" :members-error="membersError" :on-member-search="onMemberSearch" :on-members-retry="onMembersRetry" :onAction="instance?.vnode.props?.onAction ? forwardAction : undefined" />
      </section>
    </template>
    <FlarePluginView :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" v-if="!isFlow && !isWallet && layout !== 'ledger' && urgent.length" :view="notices" embedded />
    <FlareStatusBanner v-if="error && !active && !inlineFormActionId" :text="error" tone="danger" :dot="false" />
    <section v-if="hasLedger" class="flare-account-view__ledger" :class="{'has-separate-badges': separateBadge}" :aria-label="String(presentation.sectionTitle ?? t('account.transactions'))">
      <h2 v-if="view.fields.length || presentation.sectionTitle">{{ typeof view.presentation?.props.sectionTitle === 'string' ? view.presentation.props.sectionTitle : t('account.transactions') }}</h2>
      <template v-for="(group, groupIndex) in groups" :key="`${group.key}-${groupIndex}`">
        <h3 v-if="presentation.groupByDate === true || (presentation.groupByDate !== false && !isWallet)" class="flare-account-view__date">{{ group.label }}</h3>
        <ul class="flare-account-view__list"><li v-for="entry in group.entries" :key="entry.key">
          <button type="button" class="flare-account-view__entry" :disabled="Boolean(busyActionId)" :data-account-entry="entry.row.key" @click="activateEntry(entry)">
            <span class="flare-account-view__entry-icon" :class="`is-${entry.row.badge?.tone ?? 'neutral'}`" aria-hidden="true"><FlareIcon name="wallet" :size="18" /></span>
            <span class="flare-account-view__entry-main"><span class="flare-account-view__entry-heading"><strong>{{ entry.title }}</strong><FlareTag v-if="separateBadge && entry.row.badge" :label="entry.row.badge.text" :tone="flarePluginBadgeTone(entry.row.badge.tone)" data-account-badge="true" /></span><span v-if="entry.subtitle">{{ entry.subtitle }}</span></span>
            <span class="flare-account-view__entry-value"><b :class="{ 'is-positive': entry.amount.trimStart().startsWith('+') }">{{ hidden && presentation.maskRowAmounts === true ? '••••' : entry.amount }}</b><time v-if="timeLabel(entry.atMs)" :datetime="new Date(entry.atMs!).toISOString()">{{ timeLabel(entry.atMs) }}</time></span>
            <FlareIcon name="chevron-right" :size="14" class="flare-account-view__chevron" aria-hidden="true" />
          </button>
        </li></ul>
      </template>
      <FlareEmptyState v-if="!entries.length" icon="wallet" :title="typeof presentation.emptyTitle === 'string' ? presentation.emptyTitle : t('account.empty')" :description="typeof presentation.emptyDescription === 'string' ? presentation.emptyDescription : t('account.emptyDescription')" data-account-empty="true" />
    </section>
    <section v-if="shortcutActions.length" class="flare-account-view__shortcuts">
      <h2 v-if="presentation.shortcutsTitle">{{ presentation.shortcutsTitle }}</h2>
      <FlarePluginView :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" :view="shortcutsView" embedded action-layout="compact" :busy-action-id="busyActionId" :error="error" :show-error="false" :form-errors="formErrors" :settle-token="settleToken" :members="members" :members-loading="membersLoading" :members-revision="membersRevision" :members-error="membersError" :on-member-search="onMemberSearch" :on-members-retry="onMembersRetry" :onAction="instance?.vnode.props?.onAction ? forwardAction : undefined" />
    </section>
    <details v-if="isWallet && hasInformation" class="flare-account-view__info"><summary>{{ presentation.informationTitle ?? t('account.information') }}<FlareIcon name="chevron-down" :size="16" aria-hidden="true" /></summary><FlarePluginView :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" :view="extraView" embedded :resolve-user="resolveUser" :viewer-id="viewerId" /></details>
    <section v-if="secondaryActions.length" class="flare-account-view__navigation">
      <h2 v-if="presentation.servicesTitle">{{ presentation.servicesTitle }}</h2>
      <FlarePluginView :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" :view="actionsView" embedded action-layout="list" :busy-action-id="busyActionId" :error="error" :show-error="false" :form-errors="formErrors" :settle-token="settleToken" :members="members" :members-loading="membersLoading" :members-revision="membersRevision" :members-error="membersError" :on-member-search="onMemberSearch" :on-members-retry="onMembersRetry" :onAction="instance?.vnode.props?.onAction ? forwardAction : undefined" />
    </section>
    <details v-if="!isFlow && !isWallet && hasInformation" class="flare-account-view__info"><summary>{{ presentation.informationTitle ?? t('account.information') }}<FlareIcon name="chevron-down" :size="16" aria-hidden="true" /></summary><FlarePluginView :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" :view="extraView" embedded :resolve-user="resolveUser" :viewer-id="viewerId" /></details>
    <FlareBottomSheet :open="Boolean(active)" :title="detailTitle" show-close max-height="80vh" @close="selected = undefined">
      <div v-if="active && detailView" class="flare-account-view__detail"><p class="flare-account-view__detail-label">{{ active.block.columns[0]?.label }}</p><p class="flare-account-view__detail-amount">{{ hidden && presentation.maskRowAmounts === true ? '••••' : active.amount }}</p><FlarePluginView :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" :view="detailView" embedded :busy-action-id="busyActionId" :error="error" :form-errors="formErrors" :settle-token="settleToken" :members="members" :members-loading="membersLoading" :members-revision="membersRevision" :members-error="membersError" :on-member-search="onMemberSearch" :on-members-retry="onMembersRetry" :onAction="instance?.vnode.props?.onAction ? detailAction : undefined" /></div>
    </FlareBottomSheet>
  </div>
</template>

<style scoped>
.flare-account-view { display: grid; gap: var(--flare-size-spacing-md); width: 100%; max-width: var(--flare-size-layout-directory-content-max-width); margin-inline: auto; min-width: 0; }
.flare-account-view__balance, .flare-account-view__flow { padding: var(--flare-size-spacing-lg); border-radius: var(--flare-size-radius-lg); background: var(--flare-color-bg-secondary); }
.flare-account-view__wallet-header { display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: var(--flare-size-spacing-md); }
.flare-account-view__wallet-header h2, .flare-account-view__navigation h2, .flare-account-view__shortcuts h2 { margin: 0; font-size: var(--flare-size-font-size-xl); font-weight: var(--flare-size-font-weight-semibold); }
.flare-account-view__wallet-controls { display: flex; align-items: center; gap: var(--flare-size-spacing-sm); max-width: 100%; min-width: 0; }
.flare-account-view__wallet-controls > .flare-plugin-view { width: auto; min-width: 0; max-width: 100%; }
.flare-account-view__wallet-cards { display: grid; align-items: start; grid-template-columns: repeat(auto-fit, minmax(min(100%, max(var(--flare-size-layout-primary-pane-min-width), calc((100% - var(--flare-size-spacing-md)) / 2))), 1fr)); gap: var(--flare-size-spacing-md); margin-top: var(--flare-size-spacing-md); }
.flare-account-view__wallet-card { display: grid; min-width: 0; width: 100%; gap: var(--flare-size-spacing-sm); padding: var(--flare-size-spacing-lg); border: 1px solid var(--flare-color-border-secondary); border-radius: var(--flare-size-radius-lg); background: var(--flare-color-bg-secondary); color: var(--flare-color-text-primary); font: inherit; text-align: start; cursor: pointer; }
.flare-account-view__wallet-card:hover { border-color: var(--flare-color-border-primary); }
.flare-account-view__wallet-card:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-account-view__wallet-card:disabled { cursor: default; opacity: var(--flare-opacity-disabled); }
.flare-account-view__wallet-card-heading { display: flex; align-items: center; gap: var(--flare-size-spacing-sm); min-width: 0; }
.flare-account-view__wallet-card-heading strong { flex: 1; min-width: 0; overflow-wrap: anywhere; font-size: var(--flare-size-font-size-4xl); font-weight: var(--flare-size-font-weight-semibold); }
.flare-account-view__wallet-card-heading > .flare-icon { flex: none; color: var(--flare-color-text-secondary); }
.flare-account-view__wallet-card-heading > .flare-icon:first-child { color: var(--flare-color-primary-text); }
.flare-account-view__wallet-card-label { color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); }
.flare-account-view__wallet-card-amount { font-size: var(--flare-size-font-size-5xl); font-weight: var(--flare-size-font-weight-bold); font-variant-numeric: tabular-nums; overflow-wrap: anywhere; }
.flare-account-view__wallet-card-details { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); column-gap: var(--flare-size-spacing-md); row-gap: var(--flare-size-spacing-sm); padding-top: var(--flare-size-spacing-sm); margin: 0; }
.flare-account-view__wallet-card-details > div { display: grid; align-content: start; gap: var(--flare-size-spacing-xs); font-size: var(--flare-size-font-size-sm); min-width: 0; }
.flare-account-view__wallet-card-details > div:only-child { grid-column: 1 / -1; }
.flare-account-view__wallet-card-details dt { color: var(--flare-color-text-secondary); overflow-wrap: anywhere; }
.flare-account-view__wallet-card-details dd { margin: 0; font-size: var(--flare-size-font-size-lg); font-weight: var(--flare-size-font-weight-medium); overflow-wrap: anywhere; }
.flare-account-view__wallet-card-entry { display: flex; align-items: center; justify-content: space-between; gap: var(--flare-size-spacing-sm); padding-top: var(--flare-size-spacing-sm); border-top: 1px solid var(--flare-color-border-secondary); color: var(--flare-color-primary-text); font-size: var(--flare-size-font-size-sm); font-weight: var(--flare-size-font-weight-medium); }
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
.flare-account-view__amount { margin: var(--flare-size-spacing-xs) 0 0; color: var(--flare-color-text-primary); font-size: var(--flare-size-component-red-packet-amount-font-size); font-weight: var(--flare-size-font-weight-semibold); line-height: var(--flare-size-line-height-snug); font-variant-numeric: tabular-nums; overflow-wrap: anywhere; }
.flare-account-view__stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(min(100%, 6em), 1fr)); gap: var(--flare-size-spacing-md); padding-top: var(--flare-size-spacing-lg); border-top: 1px solid var(--flare-color-border-secondary); margin: 0; }
.flare-account-view__stats dt { color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); }
.flare-account-view__stats dd { margin: var(--flare-size-spacing-xs) 0 0; font-size: var(--flare-size-font-size-lg); font-weight: var(--flare-size-font-weight-medium); font-variant-numeric: tabular-nums; overflow-wrap: anywhere; }
.flare-account-view__navigation { min-width: 0; }
.flare-account-view__navigation > .flare-plugin-view { padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg); border-radius: var(--flare-size-radius-lg); background: var(--flare-color-bg-secondary); }
.flare-account-view__navigation h2 { margin-bottom: var(--flare-size-spacing-md); }
.flare-account-view__ledger { min-width: 0; }
.flare-account-view__ledger h2 { margin: 0 0 var(--flare-size-spacing-md); font-size: var(--flare-size-font-size-3xl); font-weight: var(--flare-size-font-weight-semibold); }
.flare-account-view__date { margin: var(--flare-size-spacing-lg) 0 var(--flare-size-spacing-xs); font-size: var(--flare-size-font-size-sm); font-weight: var(--flare-size-font-weight-medium); color: var(--flare-color-text-secondary); }
.flare-account-view__date:first-of-type { margin-top: 0; }
.flare-account-view__list { list-style: none; margin: 0; padding: 0; }
.flare-account-view__list > li + li { border-top: 1px solid var(--flare-color-border-secondary); }
.flare-account-view__entry { display: flex; align-items: center; gap: var(--flare-size-spacing-sm); width: 100%; min-height: var(--flare-size-layout-touch-target); padding: var(--flare-size-spacing-md) 0; border: 0; border-radius: var(--flare-size-radius-sm); background: transparent; color: var(--flare-color-text-primary); font: inherit; text-align: start; cursor: pointer; }
.flare-account-view__entry:hover { background: var(--flare-color-bg-hover); }
.flare-account-view__entry:focus-visible, .flare-account-view__info summary:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-account-view__entry:disabled { cursor: default; opacity: var(--flare-opacity-disabled); }
.flare-account-view__entry-icon { flex: none; display: grid; place-items: center; width: calc(var(--flare-size-icon-size-lg) + var(--flare-size-spacing-sm)); height: calc(var(--flare-size-icon-size-lg) + var(--flare-size-spacing-sm)); border-radius: var(--flare-size-radius-lg); background: var(--flare-color-bg-secondary); color: var(--flare-color-text-secondary); }
.flare-account-view__entry-icon.is-success { background: color-mix(in srgb, var(--flare-color-success) 10%, var(--flare-color-bg-primary)); color: var(--flare-color-success-text); }
.flare-account-view__entry-icon.is-warning { background: color-mix(in srgb, var(--flare-color-warning) 10%, var(--flare-color-bg-primary)); color: var(--flare-color-warning-text); }
.flare-account-view__entry-main { display: grid; flex: 1 1 auto; min-width: 0; gap: var(--flare-size-spacing-2xs); }
.flare-account-view__entry-heading { display: flex; flex-wrap: wrap; align-items: center; gap: var(--flare-size-spacing-sm); min-width: 0; }
.has-separate-badges .flare-account-view__entry-heading { display: grid; justify-items: start; gap: var(--flare-size-spacing-2xs); }
.flare-account-view__entry-main strong { font-size: var(--flare-size-font-size-lg); font-weight: var(--flare-size-font-weight-medium); overflow-wrap: anywhere; }
.flare-account-view__entry-main > span:not(.flare-account-view__entry-heading) { font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-secondary); overflow-wrap: anywhere; }
.flare-account-view__entry-value { display: grid; flex: 0 0 auto; min-width: 0; max-width: 46%; justify-items: end; gap: var(--flare-size-spacing-2xs); text-align: end; font-variant-numeric: tabular-nums; }
.flare-account-view__entry-value b { font-size: var(--flare-size-font-size-lg); font-weight: var(--flare-size-font-weight-semibold); overflow-wrap: anywhere; }
.flare-account-view__entry-value b.is-positive { color: var(--flare-color-success-text); }
.flare-account-view__entry-value time, .flare-account-view__chevron { color: var(--flare-color-text-tertiary); font-size: var(--flare-size-font-size-sm); }
.flare-account-view__chevron { flex: none; }
.flare-account-view__info { padding: var(--flare-size-spacing-md) 0; }
.flare-account-view__info summary { display: flex; align-items: center; justify-content: space-between; min-height: var(--flare-size-layout-touch-target); color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-md); cursor: pointer; list-style: none; }
.flare-account-view__info summary::-webkit-details-marker { display: none; }
.flare-account-view__info[open] summary { margin-bottom: var(--flare-size-spacing-lg); }
.flare-account-view__detail { padding: var(--flare-size-spacing-md) var(--flare-size-spacing-lg) var(--flare-size-spacing-xl); }
.flare-account-view__detail-amount { margin: 0 0 var(--flare-size-spacing-xl); font-size: var(--flare-size-font-size-5xl); font-weight: var(--flare-size-font-weight-semibold); text-align: center; font-variant-numeric: tabular-nums; overflow-wrap: anywhere; }
.flare-account-view__detail-label { margin: 0 0 var(--flare-size-spacing-xs); color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); text-align: center; }
</style>
