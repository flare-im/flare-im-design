<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from "vue";
import FlareSearchBar from "../general/FlareSearchBar.vue";
import FlareFilterTabs from "../general/FlareFilterTabs.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareIcon from "../general/FlareIcon.vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { useFlareSheetOwnHeader } from "../../shared/sheetHeader";
import {
  matchesFlareContactPickerEntry,
  type FlareContactPickerEntry,
  type FlareContactPickerGroup,
} from "../../shared/contracts/contact-picker";

// Choose the person a contact card names: tabs for the groups the host passes (friends, group members —
// one group shows no tabs), a search over names and subtitles, and a list that only renders the rows on
// screen once it grows long. One tap answers in single mode; multiple mode toggles rows and answers
// from the confirm key. The signed-in user stays selectable and reads "(me)". While the host sends the card
// (`sending`, the same meaning as LocationPicker's), the tapped row — or, in multiple mode, the confirm key — spins and
// the rows take no taps; cleared, single mode forgets that row and multiple mode keeps its choice for a retry.
const props = withDefaults(
  defineProps<{
    groups: FlareContactPickerGroup[];
    searchable?: boolean;
    multiple?: boolean;
    /** Header title; the kit's "Choose a contact" when omitted. */
    title?: string;
    /** The host is sending the card: the tapped row (multiple mode: the confirm key) spins; rows take no taps. */
    sending?: boolean;
  }>(),
  { searchable: true, multiple: false, title: undefined, sending: false },
);
const emit = defineEmits<{
  (e: "select", entries: FlareContactPickerEntry[]): void;
  (e: "cancel"): void;
}>();

const { t } = useFlareI18n();
// The header row (Cancel, the title, confirm) is the picker's own: a kit sheet in fill mode draws no second title.
useFlareSheetOwnHeader();

/** Lists longer than this render only the rows in view (plus a margin). */
const VIRTUALIZE_ABOVE = 60;
const OVERSCAN = 6;
const FALLBACK_ROW_HEIGHT = 60;

const activeGroupId = ref(props.groups[0]?.id ?? "");
watch(() => props.groups, (groups) => {
  if (!groups.some((group) => group.id === activeGroupId.value)) activeGroupId.value = groups[0]?.id ?? "";
});
const query = ref("");
const chosen = ref<string[]>([]);
// The row a single-mode tap answered with: it spins while the host sends, and is forgotten once the send settles.
const pendingId = ref<string | null>(null);
watch(() => props.sending, (now, before) => {
  if (before && !now) pendingId.value = null;
});

const groupLabel = (group: FlareContactPickerGroup): string => {
  if (group.label) return group.label;
  if (group.id === "friends") return t("contactPicker.friends");
  if (group.id === "groupMembers") return t("contactPicker.groupMembers");
  return group.id;
};
const tabs = computed(() => props.groups.map((group) => ({ value: group.id, label: groupLabel(group) })));
const activeGroup = computed(() => props.groups.find((group) => group.id === activeGroupId.value) ?? props.groups[0]);
const filtered = computed(() => {
  const entries = activeGroup.value?.entries ?? [];
  return props.searchable && query.value.trim()
    ? entries.filter((entry) => matchesFlareContactPickerEntry(entry, query.value))
    : entries;
});

// ── windowing ─────────────────────────────────────────────────────────────
const listEl = ref<HTMLElement | null>(null);
const scrollTop = ref(0);
const viewportHeight = ref(0);
const rowHeight = ref(FALLBACK_ROW_HEIGHT);
const virtualized = computed(() => filtered.value.length > VIRTUALIZE_ABOVE);
const startIndex = computed(() =>
  virtualized.value ? Math.max(0, Math.floor(scrollTop.value / rowHeight.value) - OVERSCAN) : 0,
);
const endIndex = computed(() => {
  if (!virtualized.value) return filtered.value.length;
  const viewport = viewportHeight.value || rowHeight.value * 12;
  return Math.min(filtered.value.length, Math.ceil((scrollTop.value + viewport) / rowHeight.value) + OVERSCAN);
});
const visible = computed(() => filtered.value.slice(startIndex.value, endIndex.value));
const topSpacer = computed(() => startIndex.value * rowHeight.value);
const bottomSpacer = computed(() => (filtered.value.length - endIndex.value) * rowHeight.value);

function measure(): void {
  const list = listEl.value;
  if (!list) return;
  viewportHeight.value = list.clientHeight;
  const row = list.querySelector<HTMLElement>(".flare-contact-picker__row");
  if (row?.offsetHeight) rowHeight.value = row.offsetHeight;
}
function onScroll(): void {
  scrollTop.value = listEl.value?.scrollTop ?? 0;
}
let observer: ResizeObserver | null = null;
onMounted(() => {
  void nextTick(measure);
  if (typeof ResizeObserver !== "undefined" && listEl.value) {
    observer = new ResizeObserver(measure);
    observer.observe(listEl.value);
  }
});
onBeforeUnmount(() => observer?.disconnect());
watch([activeGroupId, query], () => {
  scrollTop.value = 0;
  if (listEl.value) listEl.value.scrollTop = 0;
  void nextTick(measure);
});

// ── choosing ──────────────────────────────────────────────────────────────
const isChosen = (entry: FlareContactPickerEntry): boolean => chosen.value.includes(entry.userId);
const isPending = (entry: FlareContactPickerEntry): boolean =>
  props.sending && !props.multiple && pendingId.value === entry.userId;
function tap(entry: FlareContactPickerEntry): void {
  if (props.sending) return;
  if (!props.multiple) {
    pendingId.value = entry.userId;
    emit("select", [entry]);
    return;
  }
  chosen.value = isChosen(entry) ? chosen.value.filter((id) => id !== entry.userId) : [...chosen.value, entry.userId];
}
function confirm(): void {
  if (props.sending) return;
  const everyone = props.groups.flatMap((group) => group.entries);
  const picked = chosen.value
    .map((id) => everyone.find((entry) => entry.userId === id))
    .filter((entry): entry is FlareContactPickerEntry => Boolean(entry));
  if (picked.length) emit("select", picked);
}
</script>

<template>
  <section class="flare-contact-picker" :aria-label="title ?? t('contactPicker.title')">
    <header class="flare-contact-picker__head">
      <button type="button" class="flare-contact-picker__cancel" @click="emit('cancel')">{{ t("contactPicker.cancel") }}</button>
      <h2 class="flare-contact-picker__title">{{ title ?? t("contactPicker.title") }}</h2>
      <span class="flare-contact-picker__head-end">
        <FlareButton
          v-if="multiple"
          size="sm"
          :label="chosen.length ? `${t('contactPicker.confirm')} (${chosen.length})` : t('contactPicker.confirm')"
          :disabled="!chosen.length"
          :loading="sending"
          @click="confirm"
        />
      </span>
    </header>

    <div v-if="searchable" class="flare-contact-picker__search">
      <FlareSearchBar v-model="query" :placeholder="t('contactPicker.search')" />
    </div>
    <FlareFilterTabs
      v-if="groups.length > 1"
      v-model="activeGroupId"
      class="flare-contact-picker__tabs"
      appearance="quiet"
      :options="tabs"
      :aria-label="title ?? t('contactPicker.title')"
    />

    <div
      ref="listEl"
      class="flare-contact-picker__list"
      :role="multiple ? 'group' : 'listbox'"
      :aria-label="activeGroup ? groupLabel(activeGroup) : undefined"
      :aria-multiselectable="multiple ? undefined : 'false'"
      @scroll.passive="onScroll"
    >
      <FlareEmptyState v-if="!filtered.length" :title="t('contactPicker.empty')" :icon="query.trim() ? 'search' : 'people'" />
      <template v-else>
        <div v-if="topSpacer" :style="{ height: `${topSpacer}px` }" aria-hidden="true" />
        <button
          v-for="entry in visible"
          :key="entry.userId"
          type="button"
          class="flare-contact-picker__row"
          :class="{ 'is-chosen': multiple && isChosen(entry), 'is-pending': isPending(entry) }"
          :role="multiple ? 'checkbox' : 'option'"
          :aria-checked="multiple ? isChosen(entry) : undefined"
          :aria-selected="multiple ? undefined : isPending(entry)"
          :aria-busy="isPending(entry) ? 'true' : undefined"
          :disabled="sending"
          :data-user-id="entry.userId"
          @click="tap(entry)"
        >
          <span v-if="multiple" class="flare-contact-picker__check" :class="{ 'is-on': isChosen(entry) }" aria-hidden="true">
            <FlareIcon v-if="isChosen(entry)" name="check" :size="12" />
          </span>
          <FlareAvatar :user-id="entry.userId" :display-name="entry.name" :avatar-url="entry.avatarUrl" :size="40" />
          <span class="flare-contact-picker__body">
            <span class="flare-contact-picker__name">
              <span class="flare-contact-picker__name-text">{{ entry.name }}</span>
              <span v-if="entry.isSelf" class="flare-contact-picker__self">{{ t("contactPicker.selfSuffix") }}</span>
            </span>
            <span v-if="entry.subtitle" class="flare-contact-picker__sub">{{ entry.subtitle }}</span>
          </span>
          <span v-if="isPending(entry)" class="flare-contact-picker__spinner" aria-hidden="true" />
        </button>
        <div v-if="bottomSpacer" :style="{ height: `${bottomSpacer}px` }" aria-hidden="true" />
      </template>
    </div>
  </section>
</template>

<style scoped>
.flare-contact-picker {
  display: flex;
  flex-direction: column;
  width: 100%;
  height: 100%;
  min-height: 0;
  max-height: 100%;
  background: var(--flare-color-bg-primary);
  color: var(--flare-color-text-primary);
}
.flare-contact-picker__head {
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  align-items: center;
  min-height: var(--flare-size-layout-control-height-lg);
  padding: 0 var(--flare-size-spacing-md);
  flex: none;
}
.flare-contact-picker__cancel {
  justify-self: start;
  min-height: var(--flare-size-layout-touch-target-min);
  padding: 0 var(--flare-size-spacing-xs);
  border: 0;
  background: transparent;
  color: var(--flare-color-text-secondary);
  font: inherit;
  font-size: var(--flare-size-font-size-xl);
  cursor: pointer;
}
.flare-contact-picker__cancel:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; border-radius: var(--flare-size-radius-sm); }
.flare-contact-picker__title {
  margin: 0;
  font-size: var(--flare-size-font-size-2xl);
  font-weight: var(--flare-size-font-weight-bold);
}
.flare-contact-picker__head-end { justify-self: end; }
.flare-contact-picker__search { flex: none; padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-md); }
.flare-contact-picker__tabs { flex: none; padding: 0 var(--flare-size-spacing-md); }
.flare-contact-picker__list {
  flex: 1 1 auto;
  min-height: 160px;
  overflow-y: auto;
  overscroll-behavior: contain;
  padding-bottom: env(safe-area-inset-bottom, 0px);
}
.flare-contact-picker__row {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-md);
  width: 100%;
  min-height: 60px;
  padding: var(--flare-size-spacing-2sm) var(--flare-size-spacing-lg);
  border: 0;
  background: transparent;
  color: inherit;
  font: inherit;
  text-align: start;
  cursor: pointer;
}
.flare-contact-picker__row:hover { background: var(--flare-color-bg-hover); }
.flare-contact-picker__row:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
.flare-contact-picker__row.is-chosen { background: var(--flare-color-bg-selected); }
/* Sending: the rows take no taps; the one being sent keeps its highlight and spins at its end. */
.flare-contact-picker__row:disabled { cursor: default; }
.flare-contact-picker__row:disabled:hover { background: transparent; }
.flare-contact-picker__row.is-chosen:disabled:hover,
.flare-contact-picker__row.is-pending,
.flare-contact-picker__row.is-pending:hover { background: var(--flare-color-bg-selected); cursor: progress; }
.flare-contact-picker__spinner {
  flex: none;
  width: var(--flare-size-icon-size-sm);
  height: var(--flare-size-icon-size-sm);
  border-radius: 50%;
  border: 2px solid var(--flare-color-primary-text);
  border-right-color: transparent;
  animation: flare-contact-picker-spin 0.8s linear infinite;
}
@keyframes flare-contact-picker-spin { to { transform: rotate(360deg); } }
@media (prefers-reduced-motion: reduce) {
  .flare-contact-picker__spinner { animation-duration: 2s; }
}
.flare-contact-picker__check {
  flex: none;
  display: inline-grid;
  place-items: center;
  width: var(--flare-size-icon-size-md);
  height: var(--flare-size-icon-size-md);
  border-radius: 50%;
  border: 1.5px solid var(--flare-color-border-hover);
  color: var(--flare-color-bg-primary);
}
.flare-contact-picker__check.is-on { border-color: var(--flare-color-primary); background: var(--flare-color-primary); }
.flare-contact-picker__body { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: var(--flare-size-spacing-3xs); }
.flare-contact-picker__name { display: flex; min-width: 0; font-size: var(--flare-size-font-size-xl); }
.flare-contact-picker__name-text { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.flare-contact-picker__self { flex: none; color: var(--flare-color-text-tertiary); white-space: pre; }
.flare-contact-picker__sub { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-tertiary); }
</style>
