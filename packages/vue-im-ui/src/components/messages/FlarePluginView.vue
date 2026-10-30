<script setup lang="ts">
import FlareUserIdentity from "../data/FlareUserIdentity.vue";
import { computed, getCurrentInstance, reactive, ref, shallowReactive, watch } from "vue";
import FlareActionMenu from "../general/FlareActionMenu.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareIcon from "../general/FlareIcon.vue";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";
import FlareDangerConfirm from "../scenes/FlareDangerConfirm.vue";
import type { SchemaSelection, SchemaSelectionLabels } from "../form/schema-selections";
import FlarePluginForm from "../form/FlarePluginForm.vue";
import PluginChoicesBlock from "./plugin/PluginChoicesBlock.vue";
import PluginEntriesBlock from "./plugin/PluginEntriesBlock.vue";
import PluginPeopleBlock from "./plugin/PluginPeopleBlock.vue";
import PluginRowsBlock from "./plugin/PluginRowsBlock.vue";
import PluginSimpleBlock from "./plugin/PluginSimpleBlock.vue";
import PluginTextBlock from "./plugin/PluginTextBlock.vue";
import PluginTimeBlock from "./plugin/PluginTimeBlock.vue";
import { flareIcons, type FlareIconName } from "../../shared/icons";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { useFlareContentSelection, useFlareMessageQuote } from "../../shared/message-renderers";
import MessageCardQuote from "./MessageCardQuote.vue";
import FlareResolvedPresentation from "./presentation/FlareResolvedPresentation.vue";
import type { FlareActionItem } from "../../shared/contracts/action-menu";
import {
  flarePluginChoiceCapped,
  flarePluginFallbackName,
  flarePluginReasonLine,
  flarePluginShowsDetailKey,
  flarePluginUnavailableKey,
  flarePluginWithinCap,
  type FlarePluginAction,
  type FlarePluginActionPayload,
  type FlarePluginBlock,
  type FlarePluginChoicesBlock,
  type FlarePluginFormError,
  type FlarePluginInput,
  type FlarePluginMember,
  type FlarePluginResolveUser,
  type FlarePluginRow,
  type FlarePluginRowsLayout,
  type FlarePluginStrings,
  type FlarePluginUser,
  type FlarePluginViewInset,
  type FlarePluginViewModel,
} from "../../shared/contracts/plugin-ui";

// A plugin card: the core SDK's resolved view drawn as a kit business card (spec PluginView,
// spec/plugin-view-vectors.json). Inert: nothing here reads paths, evaluates or calls the network;
// actions go out as opaque ids with the viewer's selection or form values, and the host invokes.
// The shell is the message's card surface (the timeline draws no bubble around it); menu actions open
// from the title row's ⋯ key; an unavailable reason adds its line, led by the envelope's displayName.
const props = withDefaults(
  defineProps<{
    view: FlarePluginViewModel;
    /** Kit icon name before the title. */
    icon?: string;
    /** The envelope's displayName (the plugin's name): leads the unavailable reason line. */
    displayName?: string;
    /** The viewer's user id: their entries rows carry the "me" tag. */
    viewerId?: string;
    /** The whole card is busy: every action, choice and submit is disabled. */
    busy?: boolean;
    /** The action in flight: its key spins; leaving the action settles it as a fallback for `settleToken`. */
    busyActionId?: string;
    /** Failure text from the host. */
    error?: string;
    /** No card shell or title row (detail sheet, admin page). */
    embedded?: boolean;
    /**
     * Where the view sits: `sheet` gives it the bottom-sheet insets (md / lg / xl) for a view put straight into a sheet,
     * `sheetTop` the same without the bottom one for a view with more of the sheet under it (a preface above
     * PluginForm). Pads every state: the embedded body, available or not, and a card shell kept in a sheet.
     */
    inset?: FlarePluginViewInset;
    /** How a rows block draws: the kit DataTable (console admin lists) or one item per row (plugin pages). */
    rowsLayout?: FlarePluginRowsLayout;
    resolveUser?: FlarePluginResolveUser;
    /** Candidates for members inputs in action forms. */
    members?: FlarePluginMember[];
    /** The host's validation errors for the open action form. */
    formErrors?: FlarePluginFormError[];
    /** Initial values for the action/row selected by the user; captured once when opening. */
    formInitialValues?: (actionId: string, row?: {key: string; input: unknown}) => Record<string, unknown> | undefined;
    formSelections?: Record<string, SchemaSelection>;
    formChangeActions?: ReadonlyArray<string>;
    selectionLabels?: SchemaSelectionLabels;
    /**
     * The host's settle signal: incremented once per finished action, after that result's `error` / `formErrors`
     * are set. Each change settles the optimistic choice and a submitted form (spec rules.settle).
     */
    settleToken?: number;
  }>(),
  {
    icon: undefined, displayName: undefined, viewerId: undefined, busy: false, busyActionId: undefined, error: undefined, embedded: false, inset: "none",
    rowsLayout: "table", resolveUser: undefined, members: () => [], formErrors: () => [], settleToken: 0,
  },
);
const emit = defineEmits<{
  action: [actionId: string, payload: FlarePluginActionPayload];
  /** "See all", the card's view details key (or a row of an admin table, with its key and the detail operation's input). */
  openDetail: [row?: { key: string; input: unknown }];
  /** Admin tables: the next page from `cursor` of operation `source`. */
  loadMore: [cursor: string, source: string];
  selectionSearch: [id: string, query: string];
  selectionRetry: [id: string];
  selectionMore: [id: string];
}>();
const { t } = useFlareI18nOptional();

const strings = computed<FlarePluginStrings>(() => ({
  deadlinePassed: t("pluginView.deadlinePassed"),
  remaining: t("pluginView.remaining"),
  dateTime: t("pluginView.dateTime"),
  dateTimeYear: t("pluginView.dateTimeYear"),
  days: t("pluginView.days"),
  hours: t("pluginView.hours"),
  minutes: t("pluginView.minutes"),
  required: t("pluginForm.required"),
  tooLong: t("pluginForm.tooLong"),
  outOfRange: t("pluginForm.outOfRange"),
  tooFewItems: t("pluginForm.tooFewItems"),
  tooManyItems: t("pluginForm.tooManyItems"),
  duplicateItem: t("pluginForm.duplicateItem"),
  invalid: t("pluginForm.invalid"),
}));

const KNOWN = new Set<string>(["text", "fields", "choices", "entries", "people", "status", "progress", "time", "divider", "note", "rows"]);
/** Blocks the kit knows, in order; a kind from a newer protocol is skipped. */
const blocks = computed<FlarePluginBlock[]>(() => (props.view.blocks ?? []).filter((block) => KNOWN.has((block as { kind: string }).kind)));
const titleIcon = computed(() => (props.icon && props.icon in flareIcons ? (props.icon as FlareIconName) : undefined));
// A timeline row that replies: the quote goes inside this shell, at the top (the row then draws none).
const rowQuote = useFlareMessageQuote();
if (rowQuote && !props.embedded) rowQuote.claim();
const quoteShown = computed(() => (!props.embedded && rowQuote?.active() ? rowQuote : null));
// In a selecting timeline row the card is inert: a tap selects the row.
const specialPresentation = computed(() => props.view.available && ['redPacket.card','redPacket.composer','redPacket.pay','payment.confirm','redPacket.detail'].includes(props.view.presentation?.renderer ?? '') && (props.view.presentation?.renderer !== 'redPacket.detail' || Boolean(props.view.presentation.props.details)));
function presentationRequest(id: string): void { const action = props.view.actions.find(a => a.id === id); if (action) run(action, {}); }
const selecting = useFlareContentSelection();
const locked = computed(() => props.busy || Boolean(props.busyActionId) || selecting());
// The reason line (spec rules.unavailableReason): the reason's copy, led by the envelope's displayName.
const reasonLine = computed(() => {
  const reason = props.view.unavailableReason;
  if (!reason) return "";
  return flarePluginReasonLine(t(flarePluginUnavailableKey(reason)), props.displayName);
});
// Menu actions (spec rules.menuActions): the title row's ⋯ key on a card, keys after the actions when embedded.
const menuActions = computed<FlarePluginAction[]>(() => (props.view.available ? [...(props.view.menuActions ?? [])] : []));
const menuItems = computed<FlareActionItem[]>(() => menuActions.value.map((action) => ({
  id: action.id,
  label: action.label,
  danger: action.style === "danger",
  enabled: !locked.value,
})));
function runMenu(id: string): void {
  const action = menuActions.value.find((candidate) => candidate.id === id);
  if (action) run(action, {});
}
const footerActions = computed<FlarePluginAction[]>(() => (props.embedded ? [...props.view.actions, ...menuActions.value] : [...props.view.actions]));
// The card's view details key (spec rules.detailKey): a detail no entries block offers, and a host that listens
// for openDetail (read at render: listeners are not reactive props).
const instance = getCurrentInstance();
const detailKey = () => flarePluginShowsDetailKey(props.view, props.embedded) && Boolean(instance?.vnode.props?.onOpenDetail);

// ── users ────────────────────────────────────────────────────────────────
const users = shallowReactive(new Map<string, FlarePluginUser | null>());
function request(userId: string): void {
  if (users.has(userId) || !props.resolveUser) return;
  users.set(userId, null);
  try {
    const answer = props.resolveUser(userId);
    if (answer && typeof (answer as Promise<unknown>).then === "function") {
      (answer as Promise<FlarePluginUser | undefined>).then(
        (user) => { if (user) users.set(userId, user); },
        () => undefined,
      );
    } else if (answer) users.set(userId, answer as FlarePluginUser);
  } catch {
    /* the fallback stands */
  }
}
const userIds = computed(() => {
  const ids = new Set<string>();
  for (const block of blocks.value) {
    if (block.kind === "people") for (const group of block.groups) for (const id of group.userIds) ids.add(id);
    if (block.kind === "entries") for (const entry of block.items) if (entry.userId && !entry.name) ids.add(entry.userId);
  }
  return [...ids];
});
// Answers are kept per id for the card's life: hosts pass resolvers inline, so a new function is not a
// new directory, and asking again on every render would loop.
watch([userIds, () => Boolean(props.resolveUser)], () => { for (const id of userIds.value) request(id); }, { immediate: true });
/** The resolved user of an id, or the fallback: initials and the id's last 4 characters. */
function userOf(userId: string): FlarePluginUser {
  return users.get(userId) ?? { name: flarePluginFallbackName(userId) };
}

// ── choices: drafts (multiple) and the optimistic submit ─────────────────
const drafts = reactive(new Map<number, number[]>());
const pending = ref<{ block: number; actionId: string; selection: number[] } | null>(null);
const viewSelection = (block: FlarePluginChoicesBlock) => block.options.filter((o) => o.selected).map((o) => o.index);
const sameSet = (a: ReadonlyArray<number>, b: ReadonlyArray<number>) => a.length === b.length && [...a].sort().join() === [...b].sort().join();
function choicesInteractive(block: FlarePluginChoicesBlock, index: number): boolean {
  return Boolean(block.action) && !block.closed && !locked.value && pending.value?.block !== index;
}
function shownSelection(block: FlarePluginChoicesBlock, index: number): number[] {
  if (pending.value?.block === index) return pending.value.selection;
  if (block.multiple && block.action && !block.closed) return drafts.get(index) ?? viewSelection(block);
  return viewSelection(block);
}
function submitEnabled(block: FlarePluginChoicesBlock, index: number): boolean {
  const draft = drafts.get(index) ?? viewSelection(block);
  return draft.length > 0 && !sameSet(draft, viewSelection(block)) && flarePluginWithinCap(block, draft);
}
/** Options the cap holds back (spec rules.maxSelections): the multiple draft is full and does not hold them. */
function cappedOptions(block: FlarePluginChoicesBlock, index: number): number[] {
  if (!block.multiple || pending.value?.block === index) return [];
  const draft = drafts.get(index) ?? viewSelection(block);
  return block.options.map((o) => o.index).filter((option) => flarePluginChoiceCapped(block, draft, option));
}
function pick(block: FlarePluginChoicesBlock, index: number, option: number): void {
  if (!choicesInteractive(block, index) || !block.action) return;
  if (block.multiple) {
    if (cappedOptions(block, index).includes(option)) return;
    const draft = new Set(drafts.get(index) ?? viewSelection(block));
    if (draft.has(option)) draft.delete(option); else draft.add(option);
    drafts.set(index, [...draft].sort((a, b) => a - b));
    return;
  }
  const current = viewSelection(block);
  if (current.length === 1 && current[0] === option) return;
  submitChoices(block, index, [option]);
}
function submitChoices(block: FlarePluginChoicesBlock, index: number, selection: number[]): void {
  const action = block.action;
  if (!action) return;
  const sorted = [...selection].sort((a, b) => a - b);
  run(action, { selection: sorted }, () => { pending.value = { block: index, actionId: action.id, selection: sorted }; });
}
function revert(): void {
  if (!pending.value) return;
  drafts.delete(pending.value.block);
  pending.value = null;
}
// A new view is the truth; a failure reverts.
watch(() => props.view, () => { pending.value = null; drafts.clear(); });
watch(() => props.error, (error, before) => { if (error && error !== before) revert(); });

// ── actions, confirmation and forms ──────────────────────────────────────
const confirming = ref<{ action: FlarePluginAction; proceed: () => void } | null>(null);
const formAction = ref<FlarePluginAction | null>(null);
// What the action already carries when its form opens (a choices selection and its optimistic mark):
// the form adds its values to it, so every platform sends both.
const formCarry = ref<{ payload: FlarePluginActionPayload; before?: () => void } | null>(null);
const formSubmitted = ref(false);
const formValues = ref<Record<string, unknown> | undefined>();
const formInputs = computed<FlarePluginInput[]>(() => {
  const action = formAction.value;
  if (!action?.form) return [];
  return action.form.map((id) => props.view.inputs?.find((input) => input.id === id)).filter((input): input is FlarePluginInput => Boolean(input));
});
const formBusy = computed(() => props.busy || (Boolean(formAction.value) && props.busyActionId === formAction.value?.id));
// The row whose action went out last: only its key spins for busyActionId (spec rules.pageRows); the other rows
// offering the same action wait without spinning.
const rowInFlight = ref<string | null>(null);
function send(actionId: string, payload: FlarePluginActionPayload): void {
  rowInFlight.value = payload.row?.key ?? null;
  emit("action", actionId, payload);
}

/** Confirm, then collect the form, then hand the action over (`before` runs right before it goes out). */
function run(action: FlarePluginAction, payload: FlarePluginActionPayload, before?: () => void): void {
  if (locked.value) return;
  const proceed = () => {
    if (action.form?.length) {
      formSubmitted.value = false;
      formValues.value = props.formInitialValues?.(action.id, payload.row);
      formCarry.value = { payload, before };
      formAction.value = action;
      return;
    }
    before?.();
    send(action.id, payload);
  };
  if (action.confirm) confirming.value = { action, proceed };
  else proceed();
}
function confirmed(): void {
  const next = confirming.value;
  confirming.value = null;
  next?.proceed();
}
function submitForm(values: Record<string, unknown>): void {
  const action = formAction.value;
  if (!action) return;
  formSubmitted.value = true;
  const carry = formCarry.value;
  carry?.before?.();
  send(action.id, { ...(carry?.payload ?? {}), formValues: values });
}
function closeForm(): void {
  if (formBusy.value) return;
  formAction.value = null;
  formCarry.value = null;
  formSubmitted.value = false;
}
/**
 * The host finished an action (`actionId` when the fallback knows which one): an optimistic choice reverts when the
 * result carries an error or form errors and otherwise stays until the new view; a submitted form closes unless it
 * came back with errors. Settling twice is the same as once.
 */
function settle(actionId?: string): void {
  const failed = Boolean(props.error) || props.formErrors.length > 0;
  if (failed && pending.value && (!actionId || pending.value.actionId === actionId)) revert();
  if (formAction.value && formSubmitted.value && !failed && (!actionId || formAction.value.id === actionId)) {
    formAction.value = null;
    formCarry.value = null;
    formSubmitted.value = false;
  }
}
// The explicit signal: every change of the token settles (a same-frame busyActionId never shows a change).
watch(() => props.settleToken, (now, before) => { if (now !== before) settle(); });
// The fallback: busyActionId leaving the action.
watch(() => props.busyActionId, (now, before) => {
  if (!before || now === before) return;
  settle(before);
});

function rowAction(action: FlarePluginAction, row: FlarePluginRow, input: unknown): void {
  run(action, { row: { key: row.key, input } });
}
const variantOf = (action: FlarePluginAction) => (action.style === "danger" ? "danger" : action.style === "primary" ? "primary" : "secondary");
</script>

<template>
  <section
    class="flare-plugin-view"
    :class="{ 'is-presentation': specialPresentation, 'is-embedded': embedded, 'is-inset-sheet': inset === 'sheet', 'is-inset-sheet-top': inset === 'sheetTop', 'is-unavailable': !view.available }"
    :aria-label="view.title || undefined"
    :aria-busy="busy || Boolean(busyActionId)"
  >
    <!-- A quoted reply sits inside the card shell, above the title row. -->
    <div v-if="($slots.quote || quoteShown) && !embedded" class="flare-plugin-view__quote" data-plugin-quote="true">
      <slot name="quote"><MessageCardQuote v-if="quoteShown" :preview="quoteShown.preview()" :locate="quoteShown.locate()" /></slot>
    </div>
    <header v-if="!embedded && !specialPresentation" class="flare-plugin-view__head">
      <FlareIcon v-if="titleIcon" class="flare-plugin-view__icon" :name="titleIcon" :size="18" />
      <strong class="flare-plugin-view__title">{{ view.title }}</strong>
      <FlareButton
        v-if="detailKey() && !footerActions.length"
        class="flare-plugin-view__detail"
        variant="quiet"
        size="sm"
        appearance="text"
        :disabled="locked"
        data-detail-key="true"
        @click="emit('openDetail')"
      >
        <span>{{ t('pluginView.detail') }}</span>
        <FlareIcon name="chevron-right" :size="14" aria-hidden="true" />
      </FlareButton>
      <FlareActionMenu
        v-if="menuItems.length"
        :items="menuItems"
        :label="t('pluginView.more')"
        placement="bottom-end"
        @select="runMenu"
      >
        <button
          type="button"
          class="flare-plugin-view__more"
          :aria-label="t('pluginView.more')"
          :title="t('pluginView.more')"
          :disabled="locked"
          data-plugin-menu="true"
        >
          <FlareIcon name="more" :size="18" />
        </button>
      </FlareActionMenu>
    </header>
    <!-- Embedded there is no title row: an unavailable view still says what it was. -->
    <p v-else-if="!view.available && view.title" class="flare-plugin-view__unavailable" data-unavailable-title="true">{{ view.title }}</p>
    <p v-if="!view.available && reasonLine" class="flare-plugin-view__reason" data-unavailable-reason="true">{{ reasonLine }}</p>
    <FlareResolvedPresentation v-if="specialPresentation" :view="view" :busy="locked" :error="error" :form-errors="formErrors" :settle-token="settleToken" :resolve-user="resolveUser" :members="members" @request="presentationRequest" @action="send" />
    <p v-if="specialPresentation && reasonLine" class="flare-plugin-view__reason" data-unavailable-reason="true">{{ reasonLine }}</p>
    <template v-if="view.available && !specialPresentation">
      <dl v-if="view.fields.length" class="flare-plugin-view__fields">
        <div v-for="(field, index) in view.fields" :key="index"><dt>{{ field.label }}</dt><dd><FlareUserIdentity v-if="field.user" :user="field.user" /><template v-else>{{ field.value }}</template></dd></div>
      </dl>
      <template v-for="(block, index) in blocks" :key="index">
        <PluginTextBlock v-if="block.kind === 'text'" :block="block" data-block="text" />
        <PluginChoicesBlock
          v-else-if="block.kind === 'choices'"
          :block="block"
          :selected="shownSelection(block, index)"
          :interactive="choicesInteractive(block, index)"
          :submit-enabled="submitEnabled(block, index)"
          :submit-loading="Boolean(block.action) && busyActionId === block.action?.id"
          :capped="cappedOptions(block, index)"
          data-block="choices"
          @pick="(option: number) => pick(block, index, option)"
          @submit="submitChoices(block, index, drafts.get(index) ?? [])"
        />
        <PluginEntriesBlock v-else-if="block.kind === 'entries'" :block="block" :user-of="userOf" :viewer-id="viewerId" data-block="entries" @see-all="emit('openDetail')" />
        <PluginPeopleBlock v-else-if="block.kind === 'people'" :block="block" :user-of="userOf" data-block="people" />
        <PluginTimeBlock v-else-if="block.kind === 'time'" :block="block" :strings="strings" data-block="time" />
        <PluginRowsBlock
          v-else-if="block.kind === 'rows'"
          :block="block"
          :strings="strings"
          :busy="locked"
          :busy-action-id="busyActionId"
          :busy-row="rowInFlight"
          :layout="rowsLayout"
          data-block="rows"
          @row-action="rowAction"
          @open-row="(row: FlarePluginRow) => emit('openDetail', { key: row.key, input: row.detailInput })"
          @load-more="(cursor: string) => emit('loadMore', cursor, block.source)"
        />
        <PluginSimpleBlock
          v-else-if="block.kind === 'fields' || block.kind === 'status' || block.kind === 'progress' || block.kind === 'divider' || block.kind === 'note'"
          :block="block"
          :data-block="block.kind"
        />
      </template>
      <footer v-if="footerActions.length" class="flare-plugin-view__footer">
        <div v-if="footerActions.length" class="flare-plugin-view__actions">
          <FlareButton
            v-for="action in footerActions"
            :key="action.id"
            :label="action.label"
            :variant="variantOf(action)"
            size="sm"
            appearance="text"
            :loading="busyActionId === action.id"
            :disabled="locked"
            :data-action-id="action.id"
            @click="run(action, {})"
          />
        </div>
        <FlareButton
          v-if="detailKey()"
          class="flare-plugin-view__detail"
          variant="quiet"
          size="sm"
          appearance="text"
          :disabled="locked"
          data-detail-key="true"
          @click="emit('openDetail')"
        >
          <span>{{ t('pluginView.detail') }}</span>
          <FlareIcon name="chevron-right" :size="14" aria-hidden="true" />
        </FlareButton>
      </footer>
      <!-- A forwarded or forged copy (unbound_copy): readable, read-only, and it says so. -->
      <p v-if="reasonLine" class="flare-plugin-view__reason flare-plugin-view__reason--copy" data-unavailable-reason="true">{{ reasonLine }}</p>
    </template>
    <FlareStatusBanner v-if="error" :text="error" tone="danger" />
    <FlareDangerConfirm
      v-if="confirming"
      :open="Boolean(confirming)"
      :title="confirming?.action.label ?? ''"
      :description="confirming?.action.confirm ?? ''"
      target=""
      :confirm-text="confirming?.action.label"
      @confirm="confirmed"
      @cancel="confirming = null"
    />
    <FlareBottomSheet v-if="formAction" :open="Boolean(formAction)" :title="formAction?.label" :dismissible="!formBusy" @close="closeForm">
      <FlarePluginForm
        :inputs="formInputs"
        :values="formValues"
        :require-change="formAction ? formChangeActions?.includes(formAction.id) : false"
        :selections="formSelections"
        :selection-labels="selectionLabels"
        @selection-search="(id: string, query: string) => emit('selectionSearch',id,query)"
        @selection-retry="(id: string) => emit('selectionRetry',id)"
        @selection-more="(id: string) => emit('selectionMore',id)"
        :errors="formSubmitted ? formErrors : []"
        :busy="formBusy"
        :error="formSubmitted ? error : undefined"
        :members="members"
        @submit="submitForm"
        @cancel="closeForm"
      />
    </FlareBottomSheet>
  </section>
</template>

<style scoped>
.flare-plugin-view {
  display: grid;
  gap: var(--flare-size-spacing-2sm);
  --flare-plugin-title-size: var(--flare-size-font-size-xl);
  --flare-plugin-body-size: var(--flare-size-font-size-lg);
  --flare-plugin-meta-size: var(--flare-size-font-size-sm);
  width: var(--flare-component-rich-card-width);
  max-width: 100%;
  min-width: 0;
  box-sizing: border-box;
  padding: var(--flare-size-spacing-md);
  border: 1px solid color-mix(in srgb, var(--flare-color-border-secondary) 60%, transparent);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-primary);
  box-shadow: none;
  color: var(--flare-color-text-primary);
  overflow-wrap: anywhere;
}
.flare-plugin-view.is-presentation { width: auto; padding: 0; border: 0; background: transparent; box-shadow: none; }
.flare-plugin-view.is-embedded { --flare-plugin-title-size: var(--flare-size-font-size-2xl); --flare-plugin-body-size: var(--flare-size-font-size-lg); --flare-plugin-meta-size: var(--flare-size-font-size-md); width: auto; padding: 0; border: 0; border-radius: 0; background: transparent; box-shadow: none; }
/* Straight into a bottom sheet: the sheet's insets, the same as PluginForm; sheetTop leaves the bottom one to what follows. */
.flare-plugin-view.is-embedded.is-inset-sheet { padding: var(--flare-size-spacing-md) var(--flare-size-spacing-lg) var(--flare-size-spacing-xl); }
.flare-plugin-view.is-embedded.is-inset-sheet-top { padding: var(--flare-size-spacing-md) var(--flare-size-spacing-lg) 0; }
/* A card shell kept in a sheet: the insets go around the shell, which keeps its own padding. */
.flare-plugin-view.is-inset-sheet:not(.is-embedded),
.flare-plugin-view.is-inset-sheet-top:not(.is-embedded) {
  max-width: calc(100% - 2 * var(--flare-size-spacing-lg));
  margin: var(--flare-size-spacing-md) var(--flare-size-spacing-lg) var(--flare-size-spacing-xl);
}
.flare-plugin-view.is-inset-sheet-top:not(.is-embedded) { margin-bottom: 0; }
.flare-plugin-view__unavailable { margin: 0; font-size: var(--flare-size-font-size-md); color: var(--flare-color-text-secondary); }
.flare-plugin-view__head { display: flex; align-items: center; gap: var(--flare-size-spacing-xs); min-width: 0; }
.flare-plugin-view__head .flare-plugin-view__title { flex: 1 1 auto; }
/* The ⋯ key: an icon-sized glyph whose target reaches the touch target around it. */
.flare-plugin-view__more {
  position: relative;
  flex: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  margin-inline-end: calc(var(--flare-size-spacing-xs) * -1);
  padding: var(--flare-size-spacing-2xs);
  border: 0;
  border-radius: var(--flare-size-radius-sm);
  background: transparent;
  color: var(--flare-color-text-secondary);
  cursor: pointer;
}
.flare-plugin-view__more::after {
  content: "";
  position: absolute;
  top: 50%;
  left: 50%;
  width: var(--flare-size-layout-touch-target);
  height: var(--flare-size-layout-touch-target);
  transform: translate(-50%, -50%);
}
.flare-plugin-view__more:disabled { cursor: default; opacity: 0.5; }
@media (hover: hover) {
  .flare-plugin-view__more:not(:disabled):hover { background: var(--flare-color-bg-hover); color: var(--flare-color-text-primary); }
}
.flare-plugin-view__more:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-plugin-view__reason { margin: 0; font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-secondary); }
.flare-plugin-view__reason--copy { color: var(--flare-color-text-tertiary); }
.flare-plugin-view__quote { min-width: 0; }
.flare-plugin-view__icon { flex: none; color: var(--flare-color-primary-text); }
.flare-plugin-view__title { min-width: 0; font-size: var(--flare-size-font-size-sm); font-weight: var(--flare-size-font-weight-medium); line-height: var(--flare-size-line-height-snug); color: var(--flare-color-text-secondary); }
.flare-plugin-view__fields { display: grid; gap: var(--flare-size-spacing-xs); margin: 0; font-size: var(--flare-size-font-size-md); }
.flare-plugin-view__fields > div { display: grid; grid-template-columns: minmax(4em, 1fr) minmax(0, 2fr); gap: var(--flare-size-spacing-md); }
.flare-plugin-view__fields dt { color: var(--flare-color-text-secondary); }
.flare-plugin-view__fields dd { margin: 0; }
.flare-plugin-view__footer {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  column-gap: var(--flare-size-spacing-sm);
  row-gap: var(--flare-size-spacing-2sm);
  min-width: 0;
  padding-block-start: var(--flare-size-spacing-2xs);
  border-top: 1px solid var(--flare-color-border-secondary);
}
.flare-plugin-view__actions { display: flex; flex-wrap: wrap; gap: var(--flare-size-spacing-md); min-width: 0; }
.flare-plugin-view__actions > * { flex: 0 1 auto; max-width: 100%; white-space: normal; height: auto; }
.flare-plugin-view__detail {
  flex: none;
  margin-inline-start: auto;
  padding-inline: var(--flare-size-spacing-2xs);
  font-size: var(--flare-size-font-size-sm);
  font-weight: var(--flare-size-font-weight-medium);
}
.flare-plugin-view__detail :deep(.flare-button__label) { display: inline-flex; align-items: center; gap: var(--flare-size-spacing-3xs); }
.flare-plugin-view.is-embedded .flare-plugin-view__footer { border-top: 0; padding-block-start: 0; }
@media (pointer: coarse) {
  .flare-plugin-view__footer { row-gap: var(--flare-size-spacing-md); }
}

</style>
