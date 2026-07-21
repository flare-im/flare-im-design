<script setup lang="ts">
import { computed, ref } from "vue";
import { ChatbubbleOutline, ChevronDownOutline, InformationCircleOutline, LogInOutline, PersonOutline } from "../../shared/icon-glyphs";
import { NButton, NCollapseTransition, NForm, NFormItem, NIcon, NInput, NSelect } from "naive-ui";
import { useViewport } from "../../composables/useViewport";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

type AuthTransportMode = "websocket" | "quic" | "race";

const props = withDefaults(defineProps<{
  userId: string;
  token?: string;
  transportMode?: AuthTransportMode;
  wsUrl: string;
  quicUrl?: string;
  tlsCaCertPath?: string;
  httpUrl: string;
  dataUrl: string;
  tenantId: string;
  showTransportSelector?: boolean;
  loading?: boolean;
}>(), {
  token: "",
  transportMode: "websocket",
  quicUrl: "",
  tlsCaCertPath: "",
  showTransportSelector: false,
});

const emit = defineEmits<{
  (event: "update:userId", value: string): void;
  (event: "update:token", value: string): void;
  (event: "update:transportMode", value: AuthTransportMode): void;
  (event: "update:wsUrl", value: string): void;
  (event: "update:quicUrl", value: string): void;
  (event: "update:tlsCaCertPath", value: string): void;
  (event: "update:httpUrl", value: string): void;
  (event: "update:dataUrl", value: string): void;
  (event: "update:tenantId", value: string): void;
  (event: "generate-token"): void;
  (event: "login"): void;
}>();

const serverOpen = ref(false);
const transportSelectOpen = ref(false);
const { isDesktop } = useViewport();
const { t } = useFlareI18n();

const transportHint = computed(() => {
  if (props.transportMode === "quic") return t("login.transport.quicHint");
  if (props.transportMode === "race") return t("login.transport.raceHint");
  return t("login.transport.websocketHint");
});

const transportOptions = computed(() => [
  { label: t("login.transport.websocket"), value: "websocket" },
  { label: t("login.transport.quic"), value: "quic" },
  { label: t("login.transport.race"), value: "race" },
]);

function updateTransportSelectOpen(value: boolean): void {
  transportSelectOpen.value = value;
}

function updateTransportMode(value: string | number | boolean | null): void {
  transportSelectOpen.value = false;
  if (value === "quic" || value === "race") {
    emit("update:transportMode", value);
    return;
  }
  emit("update:transportMode", "websocket");
}
</script>

<template>
  <main class="auth-screen">
    <section class="auth-brand" aria-hidden="false">
      <div class="auth-brand__ambient" aria-hidden="true" />
      <div class="brand-lockup">
        <div class="brand-mark brand-mark--large" aria-hidden="true">
          <n-icon :component="ChatbubbleOutline" />
        </div>
        <div class="brand-lockup__text">
          <h1>{{ t("login.brandTitle") }}</h1>
          <p>{{ t("login.brandSubtitle") }}</p>
        </div>
      </div>
      <ul class="auth-brand__features" aria-label="Features">
        <li>Real-time sync across devices, resumable offline</li>
        <li>TLS-encrypted channel, auditable</li>
        <li>Conversations, unread and push unified</li>
      </ul>
    </section>

    <section class="auth-panel" :class="{ 'auth-panel--desktop': isDesktop }">
      <div class="auth-panel__scroll">
        <p class="auth-panel__desk-label">{{ t("login.workspaceLabel") }}</p>
        <header class="auth-panel__intro">
          <span class="auth-panel__eyebrow">{{ t("login.eyebrow") }}</span>
          <h2>{{ t("login.welcomeTitle") }}</h2>
          <p>{{ t("login.welcomeHint") }}</p>
        </header>
        <n-form class="auth-panel__form" label-placement="top" :show-feedback="false" @submit.prevent="emit('login')">
          <n-form-item :label="t('login.userIdLabel')">
            <n-input
              class="auth-user-input"
              :value="userId"
              :round="!isDesktop"
              size="large"
              :placeholder="t('login.userIdPlaceholder')"
              autocomplete="username"
              @update:value="emit('update:userId', $event)"
            >
              <template #prefix>
                <n-icon :component="PersonOutline" />
              </template>
            </n-input>
          </n-form-item>

          <div class="auth-hint">
            <n-icon :component="InformationCircleOutline" />
            <span>{{ t("login.userIdHint") }}</span>
          </div>

          <n-form-item v-if="showTransportSelector" class="auth-transport-field" :label="t('login.transport.label')">
            <div class="auth-transport-control">
              <n-select
                :value="transportMode"
                class="auth-transport-select"
                size="large"
                :options="transportOptions"
                :show="transportSelectOpen"
                :show-on-focus="false"
                :consistent-menu-width="true"
                :fallback-option="false"
                @update:show="updateTransportSelectOpen"
                @update:value="updateTransportMode"
              />
              <p class="auth-transport-hint">{{ transportHint }}</p>
            </div>
          </n-form-item>

          <button type="button" class="auth-server-toggle" @click="serverOpen = !serverOpen">
            <span>{{ t("login.serverToggle") }}</span>
            <n-icon :component="ChevronDownOutline" :class="{ 'is-open': serverOpen }" />
          </button>

          <n-collapse-transition :show="serverOpen">
            <div class="auth-server-fields">
              <n-form-item :label="t('login.wsUrlLabel')">
                <n-input :value="wsUrl" @update:value="emit('update:wsUrl', $event)" />
              </n-form-item>
              <n-form-item v-if="showTransportSelector" :label="t('login.quicUrlLabel')">
                <n-input :value="quicUrl" placeholder="quic://127.0.0.1:60052" @update:value="emit('update:quicUrl', $event)" />
              </n-form-item>
              <n-form-item v-if="showTransportSelector" :label="t('login.tlsCaCertPathLabel')">
                <n-input
                  :value="tlsCaCertPath"
                  placeholder="/path/to/flare-im-core/certs/server.crt"
                  @update:value="emit('update:tlsCaCertPath', $event)"
                />
              </n-form-item>
              <n-form-item :label="t('login.httpUrlLabel')">
                <n-input :value="httpUrl" placeholder="/__flare-media-api" @update:value="emit('update:httpUrl', $event)" />
              </n-form-item>
              <n-form-item :label="t('login.tenantLabel')">
                <n-input :value="tenantId" @update:value="emit('update:tenantId', $event)" />
              </n-form-item>
              <n-form-item :label="t('login.dataUrlLabel')">
                <n-input :value="dataUrl" @update:value="emit('update:dataUrl', $event)" />
              </n-form-item>
              <n-form-item :label="t('login.tokenLabel')">
                <n-input
                  :value="token"
                  type="password"
                  show-password-on="click"
                  autocomplete="current-password"
                  @update:value="emit('update:token', $event)"
                />
              </n-form-item>
              <n-button secondary block @click="emit('generate-token')">{{ t("login.generateToken") }}</n-button>
            </div>
          </n-collapse-transition>

          <n-button class="auth-login-btn" type="primary" size="large" block :loading="loading" attr-type="button" @click="emit('login')">
            <template #icon>
              <n-icon :component="LogInOutline" />
            </template>
            {{ t("login.loginButton") }}
          </n-button>
        </n-form>

        <footer class="auth-panel__footer">
          <p class="auth-footnote">Your ID is assigned by an admin and shown in the invite email</p>
          <p class="auth-footnote auth-footnote--muted">ID sign-in only · secure connection enabled</p>
        </footer>
      </div>
    </section>
  </main>
</template>
