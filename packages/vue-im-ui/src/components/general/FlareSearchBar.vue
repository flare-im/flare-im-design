<script setup lang="ts">
import { computed, getCurrentInstance, onBeforeUnmount, onMounted, ref } from "vue";
import FlareIcon from "./FlareIcon.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
const props = withDefaults(
  defineProps<{
    modelValue?: string;
    placeholder?: string;
    loading?: boolean;
    autofocus?: boolean;
    /** Entry mode: the same bar without a text field (no caret, no clear). With an `activate` listener it is one button that opens search; without one it only displays. */
    readOnly?: boolean;
    /**
     * Milliseconds of quiet before `search` fires with the settled query (FR-098): every app was
     * writing this timer itself. 0 fires on every keystroke. Clearing, submitting or unmounting
     * cancels whatever is pending, so a search never runs for words nobody is looking at any more.
     */
    debounce?: number;
  }>(),
  { modelValue: "", loading: false, autofocus: false, readOnly: false, debounce: 300 },
);
const { t } = useFlareI18n();
const strings = computed(() => ({
  placeholder: props.placeholder ?? t("searchBar.placeholder"),
  clear: t("searchBar.clear"),
  cancel: t("searchBar.cancel"),
  entry: props.placeholder || t("searchBar.placeholder"),
}));
const emit = defineEmits<{
  (e: "update:modelValue", v: string): void;
  (e: "submit"): void;
  (e: "clear"): void;
  (e: "activate"): void;
  /** The typing settled (or the person pressed Return): search for this. */
  (e: "search", query: string): void;
  /** The person left search: a host closes its panel and drops what is in flight. */
  (e: "cancel"): void;
}>();
const instance = getCurrentInstance();
const canActivate = computed(() => Boolean(instance?.vnode.props?.onActivate));
/** The bar searches only for a host that listens; otherwise it is a plain field. */
const searches = computed(() => Boolean(instance?.vnode.props?.onSearch));
/** The cancel key exists only where leaving search means something to the host. */
const canCancel = computed(() => Boolean(instance?.vnode.props?.onCancel));
// The autofocus attribute is ignored for fields inserted after the page loaded (a panel that opens
// later), so focus it when it mounts.
const input = ref<HTMLInputElement | null>(null);
onMounted(() => {
  if (props.autofocus && !props.readOnly) input.value?.focus({ preventScroll: true });
});
// One timer, owned here: the bar is the only thing that knows when the typing settled.
let pending: ReturnType<typeof setTimeout> | null = null;
function cancelPending(): void {
  if (pending === null) return;
  clearTimeout(pending);
  pending = null;
}
function scheduleSearch(query: string): void {
  cancelPending();
  if (!searches.value) return;
  if (props.debounce <= 0) { emit("search", query); return; }
  pending = setTimeout(() => { pending = null; emit("search", query); }, props.debounce);
}
onBeforeUnmount(cancelPending);

function onInput(e: Event) {
  const value = (e.target as HTMLInputElement).value;
  emit("update:modelValue", value);
  scheduleSearch(value);
}
function clear() {
  cancelPending();
  emit("update:modelValue", "");
  emit("clear");
  if (searches.value) emit("search", "");
}
function submit(event: KeyboardEvent) {
  if (event.isComposing || event.keyCode === 229) return;
  // Return means now: whatever was waiting for the typing to settle happens at once.
  cancelPending();
  emit("submit");
  if (searches.value) emit("search", props.modelValue);
}
function cancel() {
  cancelPending();
  emit("cancel");
}
</script>

<template>
  <component
    :is="canActivate ? 'button' : 'div'"
    v-if="readOnly"
    :type="canActivate ? 'button' : undefined"
    class="flare-search is-entry"
    :class="{ 'is-interactive': canActivate }"
    :aria-label="canActivate ? strings.entry : undefined"
    @click="canActivate && emit('activate')"
  >
    <span class="flare-search__ico" aria-hidden="true"><FlareIcon name="search" :size="16" /></span>
    <span class="flare-search__text" :class="{ 'is-placeholder': !modelValue }">{{ modelValue || strings.entry }}</span>
  </component>
  <div v-else class="flare-search-row" :class="{ 'has-cancel': canCancel }">
  <div class="flare-search">
    <span class="flare-search__ico" aria-hidden="true"><FlareIcon name="search" :size="16" /></span>
    <input
      ref="input"
      type="search"
      class="flare-search__input"
      :value="modelValue"
      :placeholder="strings.placeholder"
      :aria-label="strings.placeholder"
      :autofocus="autofocus"
      @input="onInput"
      @keydown.enter.prevent="submit"
    />
    <span v-if="loading" class="flare-search__spin" role="status" :aria-label="t('common.loading')" />
    <button v-else-if="modelValue" type="button" class="flare-search__clear" :aria-label="strings.clear" @click="clear">
      <FlareIcon name="close" :size="14" aria-hidden="true" />
    </button>
  </div>
  <!-- Leaving search is its own key, beside the field, where a phone keyboard cannot hide it. -->
  <button v-if="canCancel" type="button" class="flare-search__cancel" @click="cancel">{{ strings.cancel }}</button>
  </div>
</template>

<style scoped>
.flare-search-row { display: flex; align-items: center; gap: var(--flare-size-spacing-sm); }
.flare-search-row.has-cancel .flare-search { flex: 1; min-width: 0; }
.flare-search__cancel {
  flex: none;
  min-height: var(--flare-size-layout-touch-target-min, 44px);
  padding: 0 var(--flare-size-spacing-sm);
  border: 0;
  background: none;
  color: var(--flare-color-primary-text);
  font-size: var(--flare-size-font-size-lg);
  cursor: pointer;
}
.flare-search {
  box-sizing: border-box;
  min-width: 0;
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  width: 100%;
  min-height: var(--flare-size-layout-touch-target);
  padding: 0 var(--flare-size-spacing-md);
  border: 1px solid transparent;
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-secondary);
}
.flare-search:not(.is-entry):focus-within {
  border-color: var(--flare-color-border-selected);
  box-shadow: 0 0 0 2px var(--flare-color-focus-ring);
}
/* Entry button: a button focus ring, not the look of a focused text field. */
.flare-search.is-interactive {
  font: inherit;
  text-align: start;
  cursor: pointer;
  transition: background var(--flare-transition-fast);
}
.flare-search.is-interactive:hover { background: var(--flare-color-bg-hover); }
.flare-search.is-interactive:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-search__ico { color: var(--flare-color-text-tertiary); }
.flare-search__input {
  flex: 1;
  min-width: 0;
  width: 100%;
  border: none;
  outline: none;
  background: none;
  font-size: 14px;
  color: var(--flare-color-text-primary);
}
.flare-search__input::-webkit-search-cancel-button { display: none; }
/* Same box as the native search input (1px 2px) so both modes line up. */
.flare-search__text {
  flex: 1;
  min-width: 0;
  padding: 1px 2px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: var(--flare-size-font-size-lg);
  color: var(--flare-color-text-primary);
}
.flare-search__text.is-placeholder { color: var(--flare-color-text-tertiary); }
.flare-search__clear {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: var(--flare-size-layout-touch-target);
  height: var(--flare-size-layout-touch-target);
  margin-right: calc(-1 * var(--flare-size-spacing-md));
  padding: 0;
  border: 0;
  color: var(--flare-color-text-tertiary);
  background: transparent;
  cursor: pointer;
}
.flare-search__clear:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -4px; border-radius: var(--flare-size-radius-md); }
.flare-search__spin {
  width: 14px; height: 14px; border-radius: 50%;
  border: 2px solid var(--flare-color-border-primary);
  border-top-color: var(--flare-color-text-tertiary);
  animation: flare-spin 0.8s linear infinite;
}
@keyframes flare-spin { to { transform: rotate(360deg); } }
@media (prefers-reduced-motion: reduce) {
  .flare-search__spin { animation: none; }
  .flare-search.is-interactive { transition: none; }
}
</style>
