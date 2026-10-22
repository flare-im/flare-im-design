<script setup lang="ts">
import { computed } from "vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import FlarePluginView from "./FlarePluginView.vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { usePluginPaging } from "./plugin/pluginPaging";
import {
  type FlarePluginActionPayload,
  type FlarePluginFormError,
  type FlarePluginMember,
  type FlarePluginResolveUser,
  type FlarePluginViewModel,
} from "../../shared/contracts/plugin-ui";

// "See all" of a plugin card: the kit bottom sheet with the detail view (core SDK plugin_detail) as an
// embedded PluginView, a spinner while it loads, and the host's error with a retry key when it fails.
// Actions run from the detail spin, fail, collect their forms and settle inside the sheet: busyActionId,
// actionError, formErrors, members and settleToken go to the embedded view unchanged. A detail with a next
// page (view.nextCursor) offers load more under the view; the host fetches it and passes back the merged view.
const props = withDefaults(
  defineProps<{
    open: boolean;
    /** Title while there is no view (the card's); the view's title wins. */
    title?: string;
    view?: FlarePluginViewModel;
    loading?: boolean;
    /** Loading failed: the host's text with a retry key. */
    error?: string;
    resolveUser?: FlarePluginResolveUser;
    /** The viewer's user id: their rows in grouped entries carry the "me" tag. */
    viewerId?: string;
    busyActionId?: string;
    /** Failure of an action run from the detail, shown inside the sheet (the view's error), never on the card. */
    actionError?: string;
    /** The host's validation errors for a form opened from the detail. */
    formErrors?: FlarePluginFormError[];
    /** Candidates for members inputs in the detail's action forms. */
    members?: FlarePluginMember[];
    /** The host's settle signal for actions run from the detail (PluginView settleToken). */
    settleToken?: number;
    /** The host is fetching the next page: the load-more key spins and is disabled. */
    loadingMore?: boolean;
  }>(),
  {
    title: "", view: undefined, loading: false, error: undefined, resolveUser: undefined, viewerId: undefined, busyActionId: undefined,
    actionError: undefined, formErrors: () => [], members: () => [], settleToken: 0, loadingMore: false,
  },
);
const emit = defineEmits<{
  retry: [];
  close: [];
  action: [actionId: string, payload: FlarePluginActionPayload];
  /** The next page after `cursor` (the view's nextCursor); the host passes back the merged view. */
  loadMore: [cursor: string];
}>();
const { t } = useFlareI18nOptional();
const heading = computed(() => props.view?.title || props.title);
const state = computed(() => (props.loading ? "loading" : props.error ? "error" : props.view ? "loaded" : "loading"));

// ── paging ───────────────────────────────────────────────────────────────
const { nextCursor, pageBusy, loadMore } = usePluginPaging({
  view: () => props.view,
  loadingMore: () => props.loadingMore,
  settleToken: () => props.settleToken,
  actionError: () => props.actionError,
  request: (cursor) => emit("loadMore", cursor),
});
</script>

<template>
  <FlareBottomSheet :open="open" :title="heading" max-height="80vh" @close="emit('close')">
    <div class="flare-plugin-detail" :data-state="state" :aria-busy="state === 'loading'">
      <FlareEmptyState v-if="state === 'loading'" :title="t('pluginView.loading')" loading />
      <div v-else-if="state === 'error'" class="flare-plugin-detail__error">
        <p role="alert">{{ error }}</p>
        <FlareButton variant="secondary" :label="t('pluginView.retry')" data-detail-retry="true" @click="emit('retry')" />
      </div>
      <FlarePluginView
        v-else-if="view"
        :view="view"
        embedded
        :resolve-user="resolveUser"
        :viewer-id="viewerId"
        :busy-action-id="busyActionId"
        :error="actionError"
        :form-errors="formErrors"
        :members="members"
        :settle-token="settleToken"
        @action="(id: string, payload: FlarePluginActionPayload) => emit('action', id, payload)"
      />
      <div v-if="state === 'loaded' && nextCursor" class="flare-plugin-detail__more">
        <FlareButton
          variant="ghost"
          size="sm"
          block
          :label="t('pluginView.loadMore')"
          :loading="pageBusy"
          :disabled="pageBusy"
          data-detail-load-more="true"
          @click="loadMore"
        />
      </div>
    </div>
  </FlareBottomSheet>
</template>

<style scoped>
.flare-plugin-detail { box-sizing: border-box; width: 100%; min-height: 0; padding: var(--flare-size-spacing-md) var(--flare-size-spacing-lg) var(--flare-size-spacing-xl); overflow-y: auto; }
.flare-plugin-detail__more { padding-top: var(--flare-size-spacing-md); }
.flare-plugin-detail__error { display: grid; justify-items: center; gap: var(--flare-size-spacing-md); padding: var(--flare-size-spacing-xl) 0; text-align: center; }
.flare-plugin-detail__error p { margin: 0; font-size: var(--flare-size-font-size-lg); color: var(--flare-color-text-secondary); }
</style>
