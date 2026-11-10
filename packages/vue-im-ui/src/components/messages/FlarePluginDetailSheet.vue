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
  type FlarePluginProtectedMediaRead,
  type FlarePluginProtectedMediaState,
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
    /** Keep action failure/settlement state while the host presents its own notification. */
    errorPresentation?: "inline" | "external";
    notePresentation?: "tinted" | "plain";
    /** The host's validation errors for a form opened from the detail. */
    formErrors?: FlarePluginFormError[];
    /** Candidates for members inputs in the detail's action forms. */
    members?: FlarePluginMember[];
    membersLoading?: boolean;
    membersRevision?: number;
    membersError?: string;
    onMemberSearch?: (query: string) => void;
    onMembersRetry?: () => void;
    /** The host's settle signal for actions run from the detail (PluginView settleToken). */
    settleToken?: number;
    /** The host is fetching the next page: the load-more key spins and is disabled. */
    loadingMore?: boolean;
    /** The scale the host knows for an asset (PluginView assetScale). */
    assetScale?: (assetId: string) => number | undefined;
    /** What the host has for each protected media item of the detail (PluginView protectedMedia). */
    protectedMedia?: Record<string, FlarePluginProtectedMediaState>;
  }>(),
  {
    title: "", view: undefined, loading: false, error: undefined, resolveUser: undefined, viewerId: undefined, busyActionId: undefined,
    actionError: undefined, errorPresentation: "inline", formErrors: () => [], members: () => [], settleToken: 0, loadingMore: false,
    assetScale: undefined, protectedMedia: undefined,
  },
);
const emit = defineEmits<{
  retry: [];
  close: [];
  action: [actionId: string, payload: FlarePluginActionPayload];
  /** The next page after `cursor` (the view's nextCursor); the host passes back the merged view. */
  loadMore: [cursor: string];
  /** A protected media read of the detail with its reason: the host runs and audits it, then fills `protectedMedia`. */
  protectedMediaRead: [read: FlarePluginProtectedMediaRead];
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
  <FlareBottomSheet show-close :open="open" :title="heading" max-height="80vh" @close="emit('close')">
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
        :error-presentation="errorPresentation"
        :note-presentation="notePresentation"
        :form-errors="formErrors"
        :members="members" :members-loading="membersLoading" :members-revision="membersRevision" :members-error="membersError" :on-member-search="onMemberSearch" :on-members-retry="onMembersRetry"
        :settle-token="settleToken"
        :asset-scale="assetScale"
        :protected-media="protectedMedia"
        @action="(id: string, payload: FlarePluginActionPayload) => emit('action', id, payload)"
        @protected-media-read="(read: FlarePluginProtectedMediaRead) => emit('protectedMediaRead', read)"
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
      <footer v-if="state === 'loaded' && $slots.footer" class="flare-plugin-detail__footer"><slot name="footer" /></footer>
    </div>
  </FlareBottomSheet>
</template>

<style scoped>
.flare-plugin-detail { box-sizing: border-box; width: 100%; min-height: 0; padding: var(--flare-size-spacing-md) var(--flare-size-spacing-lg) var(--flare-size-spacing-xl); overflow-y: auto; }
.flare-plugin-detail__footer { position: sticky; bottom: 0; padding-block: var(--flare-size-spacing-md); background: var(--flare-color-bg-primary); border-top: 1px solid var(--flare-color-border-secondary); }
.flare-plugin-detail__more { padding-top: var(--flare-size-spacing-md); }
.flare-plugin-detail__error { display: grid; justify-items: center; gap: var(--flare-size-spacing-md); padding: var(--flare-size-spacing-xl) 0; text-align: center; }
.flare-plugin-detail__error p { margin: 0; font-size: var(--flare-size-font-size-lg); color: var(--flare-color-text-secondary); }
</style>
