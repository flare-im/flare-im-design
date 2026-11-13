<script setup lang="ts">
/**
 * One plugin web bundle (design 8.4 to 8.6) in a sandboxed frame: `allow-scripts allow-forms`, never same-origin, so
 * the document has an opaque origin apart from the app and from every other bundle. The kit moves envelopes only:
 * every message the frame posts (checked to come from this frame's own window) goes to the host's bridge with the
 * host's record of a recent gesture, and what the bridge answers is posted back. The bridge checks everything; the kit
 * draws the requests the engine leaves to the host: toast, confirm, title, resize, close, navigate, an external link
 * (confirmed first, https only) and a clipboard write.
 *
 * The session ends when the component unmounts or the document unloads (`bridge.close`). A `close` from the bridge
 * (the bundle withdrawn, the plugin disabled, a newer page took the slot) ends the page: `closed` lets the container
 * fall back to the declarative variant.
 */
import { computed, onBeforeUnmount, onMounted, ref, shallowRef, watch } from "vue";
import FlareButton from "../general/FlareButton.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import FlareModal from "../general/FlareModal.vue";
import FlareToast from "../general/FlareToast.vue";
import FlareScreen from "../layout/FlareScreen.vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import {
  FLARE_PLUGIN_BUNDLE_HELLO_TIMEOUT_MS,
  FLARE_PLUGIN_BUNDLE_SANDBOX,
  createFlarePluginBundleGesture,
  flarePluginBundleAnswer,
  flarePluginBundleEvent,
  flarePluginBundleExternalUrl,
  flarePluginBundleHostResponse,
  flarePluginBundleMessage,
  flarePluginBundleText,
  flarePluginBundleToastVariant,
  type FlarePluginBundleBridge,
  type FlarePluginBundleEnvelope,
  type FlarePluginBundleHostError,
  type FlarePluginBundleHostRequest,
  type FlarePluginBundlePresentation,
  type FlarePluginBundleTheme,
} from "./pluginBundleHost";

const props = withDefaults(
  defineProps<{
    /**
     * The bundle's file base, ending in `/` (Web: the sandbox domain's `…/b/{sha256}/`; Tauri: `flare-plugin://{key}/`),
     * or the entry's full address when `entry` is omitted.
     */
    files: string;
    /** The entry document, relative to `files` (`bundle.json` `entry`, default `index.html`). */
    entry?: string;
    /** The host's bridge for this page; null while it opens (the kit shows loading). */
    bridge: FlarePluginBundleBridge | null;
    /** The app's theme; a change is sent as `theme.changed`. */
    theme?: FlarePluginBundleTheme;
    /** The app's locale; a change is sent as `locale.changed`. */
    locale?: string;
    /** Where the page shows. A `page` draws the kit screen with its title and back key; the others fill their container. */
    presentation?: FlarePluginBundlePresentation;
    /** The title until the bundle sets its own (`ui.setTitle`). */
    title?: string;
    /** Draw the back key on a page (emits `back`). */
    back?: boolean;
    /** Open a confirmed https link; defaults to a new browsing context without opener or referrer. */
    openExternal?: (url: string) => void | Promise<void>;
    /** Write text to the clipboard; defaults to `navigator.clipboard.writeText`. */
    writeClipboard?: (text: string) => Promise<void>;
    /** A host-side failure to show instead of the frame (opening failed); `retry` asks the host to open again. */
    error?: string;
  }>(),
  { entry: "index.html", presentation: "page", back: false, theme: undefined, locale: undefined, title: "", error: undefined, openExternal: undefined, writeClipboard: undefined },
);
const emit = defineEmits<{
  back: [];
  /** `ui.close`: the page is done; on a composer form `result` is the operation result. */
  close: [result?: unknown];
  /** `ui.navigate`: open a declarative page of this plugin (`page`, `arguments`) or a route of this bundle (`bundleRoute`). */
  navigate: [target: { page?: string; arguments?: Record<string, unknown>; bundleRoute?: string }];
  /** `ui.setTitle`. */
  title: [title: string];
  /** `ui.resize` (half-height sheets only): the height the bundle asks for, in CSS pixels. */
  resize: [height: number];
  /** The bridge ended the page (withdrawn, suspended, disabled, replaced, evicted, signedOut). */
  closed: [reason: string];
  /** The bundle did not answer in time or its frame failed; counted by the container (three in a session fall back). */
  failed: [];
  /** Retry after a failure (the host opens again). */
  retry: [];
}>();

const { t } = useFlareI18nOptional();
const frame = ref<HTMLIFrameElement | null>(null);
const frameKey = ref(0);
const ready = ref(false);
const timedOut = ref(false);
const ended = ref<string>();
const ownTitle = ref("");
const height = ref<number>();
const toast = shallowRef<{ message: string; variant: "info" | "success" | "error"; key: number }>();
let toastTimer: ReturnType<typeof setTimeout> | undefined;
let helloTimer: ReturnType<typeof setTimeout> | undefined;
const confirming = shallowRef<{ request: FlarePluginBundleHostRequest; title: string; message: string; confirmLabel: string; destructive: boolean }>();
const external = shallowRef<{ request: FlarePluginBundleHostRequest; url: string }>();
let closed = false;
let unsubscribe: (() => void) | undefined;
const gesture = typeof window === "undefined" ? undefined : createFlarePluginBundleGesture();

const src = computed(() => {
  if (!props.bridge || !props.files) return "";
  return props.files.endsWith("/") ? `${props.files}${props.entry || "index.html"}` : props.files;
});
const heading = computed(() => ownTitle.value || props.title);
const state = computed(() => (props.error ? "error" : ended.value ? "ended" : timedOut.value ? "failed" : ready.value ? "ready" : "loading"));

function post(envelope: FlarePluginBundleEnvelope | undefined): void {
  const target = frame.value?.contentWindow;
  // The frame's origin is opaque: "*" is the only target that reaches it.
  if (envelope && target) target.postMessage(envelope, "*");
}

async function answerHost(request: FlarePluginBundleHostRequest, outcome: { result?: Record<string, unknown>; error?: FlarePluginBundleHostError }): Promise<void> {
  const bridge = props.bridge;
  if (!bridge || closed) return;
  if (!bridge.hostResult) { post(flarePluginBundleHostResponse(request, outcome)); return; }
  try {
    post(flarePluginBundleAnswer(await bridge.hostResult(request.id, outcome)).envelope);
  } catch { /* The session ended meanwhile; the page learns it from its next request. */ }
}

function showToast(message: string, variant: "info" | "success" | "error"): void {
  if (!message) return;
  clearTimeout(toastTimer);
  toast.value = { message, variant, key: (toast.value?.key ?? 0) + 1 };
  toastTimer = setTimeout(() => { toast.value = undefined; }, 3000);
}

/** The requests the engine leaves to the host. Each is answered exactly once. */
async function draw(request: FlarePluginBundleHostRequest): Promise<void> {
  const params = request.params ?? {};
  switch (request.method) {
    case "ui.toast":
      showToast(flarePluginBundleText(params.message), flarePluginBundleToastVariant(params.kind));
      return answerHost(request, { result: {} });
    case "ui.setTitle":
      ownTitle.value = flarePluginBundleText(params.title, 128);
      emit("title", ownTitle.value);
      return answerHost(request, { result: {} });
    case "ui.resize": {
      const value = Number(params.height);
      if (props.presentation === "page" || !Number.isFinite(value) || value <= 0) return answerHost(request, { error: "unavailable" });
      height.value = Math.min(Math.round(value), 4096);
      emit("resize", height.value);
      return answerHost(request, { result: {} });
    }
    case "ui.confirm":
      if (confirming.value) return answerHost(request, { error: "unavailable" });
      confirming.value = {
        request,
        title: flarePluginBundleText(params.title, 128),
        message: flarePluginBundleText(params.message),
        confirmLabel: flarePluginBundleText(params.confirmLabel, 32) || t("common.confirm"),
        destructive: params.destructive === true,
      };
      return;
    case "ui.openExternal": {
      const url = flarePluginBundleExternalUrl(params.url);
      if (!url) return answerHost(request, { error: "unavailable" });
      if (external.value) return answerHost(request, { error: "unavailable" });
      external.value = { request, url };
      return;
    }
    case "clipboard.write": {
      const text = typeof params.text === "string" ? params.text : "";
      try {
        await (props.writeClipboard ?? ((value: string) => navigator.clipboard.writeText(value)))(text);
        showToast(t("pluginBundle.copied"), "success");
        return answerHost(request, { result: {} });
      } catch {
        return answerHost(request, { error: "unavailable" });
      }
    }
    case "ui.navigate": {
      const target = {
        ...(typeof params.page === "string" ? { page: params.page } : {}),
        ...(typeof params.bundleRoute === "string" ? { bundleRoute: params.bundleRoute } : {}),
        ...(params.arguments && typeof params.arguments === "object" && !Array.isArray(params.arguments)
          ? { arguments: params.arguments as Record<string, unknown> } : {}),
      };
      await answerHost(request, { result: {} });
      emit("navigate", target);
      return;
    }
    case "ui.close":
      await answerHost(request, { result: {} });
      emit("close", params.result);
      return;
    default:
      return answerHost(request, { error: "unavailable" });
  }
}

function confirmDone(confirmed: boolean): void {
  const current = confirming.value;
  confirming.value = undefined;
  if (current) void answerHost(current.request, { result: { confirmed } });
}

async function externalDone(open: boolean): Promise<void> {
  const current = external.value;
  external.value = undefined;
  if (!current) return;
  if (!open) { void answerHost(current.request, { error: "cancelled" }); return; }
  try {
    if (props.openExternal) await props.openExternal(current.url);
    else window.open(current.url, "_blank", "noopener,noreferrer");
    void answerHost(current.request, { result: {} });
  } catch {
    void answerHost(current.request, { error: "unavailable" });
  }
}

async function onMessage(event: MessageEvent): Promise<void> {
  const envelope = flarePluginBundleMessage(event, frame.value?.contentWindow);
  const bridge = props.bridge;
  if (!envelope || !bridge || closed) return;
  if (envelope.type === "request" && envelope.method === "host.hello") {
    ready.value = true;
    timedOut.value = false;
    clearTimeout(helloTimer);
  }
  let answer;
  try {
    answer = flarePluginBundleAnswer(await bridge.request(envelope, { userGesture: gesture?.recent() ?? false }));
  } catch {
    return;
  }
  if (closed) return;
  if (answer.host) { void draw(answer.host); return; }
  post(answer.envelope);
}

function startHelloTimer(): void {
  clearTimeout(helloTimer);
  ready.value = false;
  timedOut.value = false;
  helloTimer = setTimeout(() => {
    if (ready.value || closed || !src.value) return;
    timedOut.value = true;
    emit("failed");
  }, FLARE_PLUGIN_BUNDLE_HELLO_TIMEOUT_MS);
}

function subscribe(bridge: FlarePluginBundleBridge | null): void {
  unsubscribe?.();
  unsubscribe = bridge?.subscribe?.((raw) => {
    const event = flarePluginBundleEvent(raw);
    if (event.envelope) post(event.envelope);
    if (event.close && !ended.value) {
      ended.value = event.close;
      emit("closed", event.close);
    }
  });
}

async function hostEvent(name: string, payload: Record<string, unknown>): Promise<void> {
  const bridge = props.bridge;
  if (!bridge?.hostEvent || closed) return;
  try {
    for (const envelope of await bridge.hostEvent(name, payload)) post(envelope);
  } catch { /* An event the session no longer takes. */ }
}

function onVisibility(): void {
  void hostEvent("visibility.changed", { visible: document.visibilityState === "visible" });
}

function end(): void {
  if (closed) return;
  closed = true;
  clearTimeout(helloTimer);
  clearTimeout(toastTimer);
  unsubscribe?.();
  unsubscribe = undefined;
  const pending = [confirming.value?.request, external.value?.request].filter(Boolean) as FlarePluginBundleHostRequest[];
  confirming.value = undefined;
  external.value = undefined;
  for (const request of pending) void answerHost(request, { error: "cancelled" });
  props.bridge?.close?.();
}

function reload(): void {
  if (props.error) { emit("retry"); return; }
  frameKey.value++;
  startHelloTimer();
}

watch(() => props.bridge, (bridge, previous) => {
  if (previous && previous !== bridge) previous.close?.();
  closed = !bridge;
  ended.value = undefined;
  ownTitle.value = "";
  subscribe(bridge);
  if (bridge) startHelloTimer();
}, { immediate: true });
watch(() => props.theme, (theme) => { if (theme) void hostEvent("theme.changed", { mode: theme.mode, tokens: theme.tokens ?? {} }); }, { deep: true });
watch(() => props.locale, (locale) => { if (locale) void hostEvent("locale.changed", { locale }); });

onMounted(() => {
  window.addEventListener("message", onMessage);
  window.addEventListener("pagehide", end);
  document.addEventListener("visibilitychange", onVisibility);
});
onBeforeUnmount(() => {
  window.removeEventListener("message", onMessage);
  window.removeEventListener("pagehide", end);
  document.removeEventListener("visibilitychange", onVisibility);
  gesture?.dispose();
  end();
});
defineExpose({ sandbox: FLARE_PLUGIN_BUNDLE_SANDBOX });
</script>

<template>
  <component
    :is="presentation === 'page' ? FlareScreen : 'div'"
    class="flare-plugin-bundle-host"
    :class="`is-${presentation}`"
    v-bind="presentation === 'page' ? { title: heading, back, scroll: false, surface: 'surface' } : {}"
    :data-state="state"
    @back="emit('back')"
  >
    <div class="flare-plugin-bundle-host__stage" :style="height && presentation !== 'page' ? { height: `${height}px` } : undefined">
      <iframe
        v-if="src && !ended && !error"
        :key="frameKey"
        ref="frame"
        class="flare-plugin-bundle-host__frame"
        :class="{ 'is-hidden': !ready }"
        :src="src"
        :sandbox="FLARE_PLUGIN_BUNDLE_SANDBOX"
        referrerpolicy="no-referrer"
        allow=""
        loading="eager"
        :title="heading || t('pluginBundle.frameLabel')"
        data-bundle-frame="true"
        @error="() => { timedOut = true; emit('failed'); }"
      />
      <div v-if="state === 'loading'" class="flare-plugin-bundle-host__overlay">
        <FlareEmptyState :title="t('pluginBundle.loading')" loading />
      </div>
      <div v-else-if="state === 'failed' || state === 'error'" class="flare-plugin-bundle-host__overlay" role="alert">
        <FlareEmptyState :title="error || t('pluginBundle.failed')" icon="info" tone="error">
          <template #actions>
            <FlareButton variant="secondary" :label="t('common.retry')" data-bundle-retry="true" @click="reload" />
          </template>
        </FlareEmptyState>
      </div>
      <div v-else-if="state === 'ended'" class="flare-plugin-bundle-host__overlay">
        <FlareEmptyState :title="t('pluginBundle.ended')" icon="info" />
      </div>
      <FlareToast
        v-if="toast"
        :key="toast.key"
        class="flare-plugin-bundle-host__toast"
        :message="toast.message"
        :variant="toast.variant"
        @close="toast = undefined"
      />
    </div>
    <FlareModal :open="Boolean(confirming)" :title="confirming?.title || t('pluginBundle.confirmTitle')" :dismissible="true" @close="confirmDone(false)">
      <p v-if="confirming?.message" class="flare-plugin-bundle-host__text">{{ confirming.message }}</p>
      <template #footer>
        <FlareButton variant="secondary" :label="t('common.cancel')" data-bundle-confirm="cancel" @click="confirmDone(false)" />
        <FlareButton
          :variant="confirming?.destructive ? 'danger' : 'primary'"
          :label="confirming?.confirmLabel ?? t('common.confirm')"
          data-bundle-confirm="ok"
          @click="confirmDone(true)"
        />
      </template>
    </FlareModal>
    <FlareModal :open="Boolean(external)" :title="t('pluginBundle.openExternalTitle')" @close="externalDone(false)">
      <p class="flare-plugin-bundle-host__text">{{ t('pluginBundle.openExternalMessage') }}</p>
      <p class="flare-plugin-bundle-host__url" data-bundle-external-url="true">{{ external?.url }}</p>
      <template #footer>
        <FlareButton variant="secondary" :label="t('common.cancel')" data-bundle-external="cancel" @click="externalDone(false)" />
        <FlareButton :label="t('pluginBundle.openExternalConfirm')" data-bundle-external="open" @click="externalDone(true)" />
      </template>
    </FlareModal>
  </component>
</template>

<style scoped>
.flare-plugin-bundle-host {
  display: flex;
  flex-direction: column;
  min-height: 0;
  height: 100%;
}
.flare-plugin-bundle-host__stage {
  position: relative;
  flex: 1 1 auto;
  min-height: 0;
  background: var(--flare-color-bg-primary);
}
.flare-plugin-bundle-host.is-detail .flare-plugin-bundle-host__stage,
.flare-plugin-bundle-host.is-composerForm .flare-plugin-bundle-host__stage {
  min-height: var(--flare-size-component-rich-card-width);
}
.flare-plugin-bundle-host__frame {
  display: block;
  width: 100%;
  height: 100%;
  border: 0;
  background: transparent;
}
.flare-plugin-bundle-host__frame.is-hidden {
  visibility: hidden;
}
.flare-plugin-bundle-host__overlay {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--flare-color-bg-primary);
}
.flare-plugin-bundle-host__toast {
  position: absolute;
  left: 50%;
  bottom: var(--flare-size-spacing-lg);
  transform: translateX(-50%);
  max-width: calc(100% - 2 * var(--flare-size-spacing-lg));
}
.flare-plugin-bundle-host__text {
  margin: 0;
  color: var(--flare-color-text-primary);
}
.flare-plugin-bundle-host__url {
  margin: var(--flare-size-spacing-sm) 0 0;
  color: var(--flare-color-text-secondary);
  word-break: break-all;
}
</style>
