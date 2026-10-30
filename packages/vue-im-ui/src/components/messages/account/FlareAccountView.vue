<script setup lang="ts">
import { computed, ref, watch } from "vue";
import FlareIcon from "../../general/FlareIcon.vue";
import FlareIconButton from "../../general/FlareIconButton.vue";
import FlareBottomSheet from "../../general/FlareBottomSheet.vue";
import FlareEmptyState from "../../general/FlareEmptyState.vue";
import FlarePluginView from "../FlarePluginView.vue";
import { flareIcons } from "../../../shared/icons";
import { useFlareI18nOptional, useFlareLocaleOptional } from "../../../shared/i18n/useFlareI18n";
import { flarePluginDateTime, type FlarePluginActionPayload, type FlarePluginFormError, type FlarePluginMember, type FlarePluginResolveUser, type FlarePluginViewModel } from "../../../shared/contracts/plugin-ui";
import { flareAccountDayKey, flareAccountEntries, type AccountEntry } from "./account";

const props = withDefaults(defineProps<{
  view: FlarePluginViewModel; busyActionId?: string; error?: string; formErrors?: FlarePluginFormError[];
  settleToken?: number; members?: FlarePluginMember[]; resolveUser?: FlarePluginResolveUser; viewerId?: string;
}>(), { busyActionId: undefined, error: undefined, formErrors: () => [], settleToken: 0, members: () => [], resolveUser: undefined, viewerId: undefined });
const emit = defineEmits<{ action: [id: string, payload: FlarePluginActionPayload] }>();
const { t } = useFlareI18nOptional();
const locale = useFlareLocaleOptional();
const hidden = ref(false), selected = ref<string>();
const entries = computed(() => flareAccountEntries(props.view));
const active = computed(() => entries.value.find(entry => entry.key === selected.value));
watch(() => props.view, () => { if (selected.value && !active.value) selected.value = undefined; });
const urgent = computed(() => (props.view.blocks ?? []).filter(block => block.kind === "note" && (block.tone === "warning" || block.tone === "danger")));
const notices = computed<FlarePluginViewModel>(() => ({ ...props.view, presentation: undefined, fields: [], actions: [], menuActions: [], inputs: [], blocks: urgent.value, detail: false }));
const extras = computed(() => (props.view.blocks ?? []).filter(block => block.kind !== "rows" && !urgent.value.includes(block)));
const presentation = computed(() => props.view.presentation?.props ?? {});
const detailTitle = computed(() => String(presentation.value.detailTitle ?? presentation.value.sectionTitle ?? t("account.entryDetails")));
const extraView = computed<FlarePluginViewModel>(() => ({ ...props.view, title: "", fields: [], actions: [], menuActions: [], inputs: [], blocks: extras.value, detail: false }));
const actionsView = computed<FlarePluginViewModel>(() => ({ ...props.view, title: "", fields: [], blocks: [], detail: false }));
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
    ...(entry.row.badge ? [{ label: t("account.type"), value: entry.row.badge.text }] : []),
    ...entry.block.columns.slice(1).map((column, offset) => { const index = offset + 1; const cell = entry.row.cells[index]; return { label: column.label, value: column.format === "time" && cell?.timeMs !== undefined ? flarePluginDateTime(cell.timeMs, Date.now(), { dateTime: t("pluginView.dateTime"), dateTimeYear: t("pluginView.dateTimeYear") }) : cell?.text ?? "" }; }),
    { label: String(presentation.value.rowKeyLabel ?? t("account.entryId")), value: entry.row.key },
  ], actions: entry.row.actions.flatMap(bound => { const action = entry.block.actions.find(action => action.id === bound.id); return action ? [action] : []; }) };
});
function detailAction(id: string, payload: FlarePluginActionPayload): void {
  const entry = active.value, bound = entry?.row.actions.find(action => action.id === id);
  if (entry && bound) emit("action", id, { ...payload, row: { key: entry.row.key, input: bound.input } });
}
</script>

<template>
  <div class="flare-account-view">
    <section v-if="view.fields.length" class="flare-account-view__balance" :aria-label="view.fields[0].label">
      <div class="flare-account-view__balance-label"><span>{{ view.fields[0].label }}</span><FlareIconButton :icon="hidden ? flareIcons['eye-off'] : flareIcons.eye" :ariaLabel="t(hidden ? 'account.showBalance' : 'account.hideBalance')" size="sm" @click="hidden = !hidden" /></div>
      <p class="flare-account-view__amount" :aria-label="hidden ? t('account.balanceHidden') : undefined" data-account-balance="true">{{ hidden ? '••••' : view.fields[0].value }}</p>
      <dl v-if="view.fields.length > 1" class="flare-account-view__stats"><div v-for="(field, index) in view.fields.slice(1)" :key="index"><dt>{{ field.label }}</dt><dd>{{ hidden ? '••••' : field.value }}</dd></div></dl>
    </section>
    <FlarePluginView v-if="urgent.length" :view="notices" embedded />
    <div v-if="view.actions.length || view.menuActions?.length" class="flare-account-view__navigation">
      <FlarePluginView :view="actionsView" embedded :busy-action-id="busyActionId" :error="active ? undefined : error" :form-errors="formErrors" :settle-token="settleToken" :members="members" @action="(id, payload) => emit('action', id, payload)" />
    </div>
    <section class="flare-account-view__ledger" :aria-label="t('account.transactions')">
      <h2 v-if="view.fields.length || presentation.sectionTitle">{{ typeof view.presentation?.props.sectionTitle === 'string' ? view.presentation.props.sectionTitle : t('account.transactions') }}</h2>
      <template v-for="(group, groupIndex) in groups" :key="`${group.key}-${groupIndex}`">
        <h3 v-if="presentation.groupByDate !== false" class="flare-account-view__date">{{ group.label }}</h3>
        <ul class="flare-account-view__list"><li v-for="entry in group.entries" :key="entry.key">
          <button type="button" class="flare-account-view__entry" :disabled="Boolean(busyActionId)" :data-account-entry="entry.row.key" @click="selected = entry.key">
            <span class="flare-account-view__entry-icon" :class="`is-${entry.row.badge?.tone ?? 'neutral'}`" aria-hidden="true"><FlareIcon name="wallet" :size="18" /></span>
            <span class="flare-account-view__entry-main"><strong>{{ entry.title }}</strong><span v-if="entry.subtitle">{{ entry.subtitle }}</span></span>
            <span class="flare-account-view__entry-value"><b :class="{ 'is-positive': entry.amount.trimStart().startsWith('+') }">{{ hidden && presentation.maskRowAmounts === true ? '••••' : entry.amount }}</b><time v-if="timeLabel(entry.atMs)" :datetime="new Date(entry.atMs!).toISOString()">{{ timeLabel(entry.atMs) }}</time></span>
            <FlareIcon name="chevron-right" :size="14" class="flare-account-view__chevron" aria-hidden="true" />
          </button>
        </li></ul>
      </template>
      <FlareEmptyState v-if="!entries.length" icon="wallet" :title="typeof presentation.emptyTitle === 'string' ? presentation.emptyTitle : t('account.empty')" :description="typeof presentation.emptyDescription === 'string' ? presentation.emptyDescription : t('account.emptyDescription')" data-account-empty="true" />
    </section>
    <details v-if="extras.length" class="flare-account-view__info"><summary>{{ t('account.information') }}<FlareIcon name="chevron-down" :size="16" aria-hidden="true" /></summary><FlarePluginView :view="extraView" embedded :resolve-user="resolveUser" :viewer-id="viewerId" /></details>
    <FlareBottomSheet :open="Boolean(active)" :title="detailTitle" show-close max-height="80vh" @close="selected = undefined">
      <div v-if="active && detailView" class="flare-account-view__detail"><p class="flare-account-view__detail-amount">{{ active.amount }}</p><FlarePluginView :view="detailView" embedded :busy-action-id="busyActionId" :error="error" :form-errors="formErrors" :settle-token="settleToken" :members="members" @action="detailAction" /></div>
    </FlareBottomSheet>
  </div>
</template>

<style scoped>
.flare-account-view { display: grid; gap: var(--flare-size-spacing-md); width: 100%; min-width: 0; }
.flare-account-view__balance { padding: var(--flare-size-spacing-2xl); border-radius: var(--flare-size-radius-lg); background: var(--flare-color-bg-primary); }
.flare-account-view__balance-label { display: flex; align-items: center; gap: var(--flare-size-spacing-xs); color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-md); }
.flare-account-view__amount { margin: var(--flare-size-spacing-xs) 0 var(--flare-size-spacing-2xl); color: var(--flare-color-text-primary); font-size: var(--flare-size-component-red-packet-amount-font-size); font-weight: var(--flare-size-font-weight-semibold); line-height: var(--flare-size-line-height-snug); font-variant-numeric: tabular-nums; overflow-wrap: anywhere; }
.flare-account-view__stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(min(100%, 6em), 1fr)); gap: var(--flare-size-spacing-md); padding-top: var(--flare-size-spacing-lg); border-top: 1px solid var(--flare-color-border-secondary); margin: 0; }
.flare-account-view__stats dt { color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); }
.flare-account-view__stats dd { margin: var(--flare-size-spacing-xs) 0 0; font-size: var(--flare-size-font-size-lg); font-weight: var(--flare-size-font-weight-medium); font-variant-numeric: tabular-nums; overflow-wrap: anywhere; }
.flare-account-view__navigation { padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg); border-radius: var(--flare-size-radius-lg); background: var(--flare-color-bg-primary); }
.flare-account-view__ledger { padding: var(--flare-size-spacing-lg); min-width: 0; border-radius: var(--flare-size-radius-lg); background: var(--flare-color-bg-primary); }
.flare-account-view__ledger h2 { margin: 0 0 var(--flare-size-spacing-lg); font-size: var(--flare-size-font-size-2xl); font-weight: var(--flare-size-font-weight-semibold); }
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
.flare-account-view__entry-main strong { font-size: var(--flare-size-font-size-lg); font-weight: var(--flare-size-font-weight-medium); overflow-wrap: anywhere; }
.flare-account-view__entry-main > span { font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-secondary); overflow-wrap: anywhere; }
.flare-account-view__entry-value { display: grid; flex: 0 1 auto; min-width: 0; max-width: 46%; justify-items: end; gap: var(--flare-size-spacing-2xs); text-align: end; font-variant-numeric: tabular-nums; }
.flare-account-view__entry-value b { font-size: var(--flare-size-font-size-2xl); font-weight: var(--flare-size-font-weight-semibold); overflow-wrap: anywhere; }
.flare-account-view__entry-value b.is-positive { color: var(--flare-color-success-text); }
.flare-account-view__entry-value time, .flare-account-view__chevron { color: var(--flare-color-text-tertiary); font-size: var(--flare-size-font-size-sm); }
.flare-account-view__chevron { flex: none; }
.flare-account-view__info { padding: var(--flare-size-spacing-md) var(--flare-size-spacing-lg); border-radius: var(--flare-size-radius-lg); background: var(--flare-color-bg-primary); }
.flare-account-view__info summary { display: flex; align-items: center; justify-content: space-between; min-height: var(--flare-size-layout-control-height-sm); color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-md); cursor: pointer; list-style: none; }
.flare-account-view__info summary::-webkit-details-marker { display: none; }
.flare-account-view__info[open] summary { margin-bottom: var(--flare-size-spacing-lg); }
.flare-account-view__detail { padding: var(--flare-size-spacing-md) var(--flare-size-spacing-lg) var(--flare-size-spacing-xl); }
.flare-account-view__detail-amount { margin: 0 0 var(--flare-size-spacing-xl); font-size: var(--flare-size-font-size-5xl); font-weight: var(--flare-size-font-weight-semibold); text-align: center; font-variant-numeric: tabular-nums; overflow-wrap: anywhere; }
@media (max-width: 599px) { .flare-account-view__balance { padding: var(--flare-size-spacing-lg); } .flare-account-view__ledger { padding: var(--flare-size-spacing-md); } }
</style>
