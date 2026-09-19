<script setup lang="ts">
/**
 * The row list every scene panel (members, devices, media, storage) renders.
 *
 * It used to draw its own title, its own `<progress>`, its own empty paragraph
 * and its own bordered buttons — a fourth dialect of loading / empty / failure
 * sitting next to a `FlareSettingsList` on the same screen. Now the states go
 * through `WorkspacePane` like every other surface and the rows are built from
 * kit parts: the settings group card, the contact-row anatomy, `FlareButton`.
 */
import { computed } from "vue";
import FlareButton from "../general/FlareButton.vue";
import WorkspacePane from "../layout/WorkspacePane.vue";
import FlareSkeleton from "../general/FlareSkeleton.vue";
import type { SceneEntry } from "../../shared/contracts/scenes";
import type { WorkspacePaneState } from "../../shared/contracts/conversation-workspace";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

const props = defineProps<{
  title: string;
  items: SceneEntry[];
  loading?: boolean;
  error?: string;
  emptyText?: string;
  retryText?: string;
}>();
// Optional: a scene panel can be mounted on its own, and a missing provider
// must not blank the list — the runtime locale answers instead.
const { t } = useFlareI18nOptional();
const strings = computed(() => ({
  emptyText: props.emptyText ?? t("sceneList.empty"),
  retryText: props.retryText ?? t("sceneList.retry"),
}));
const emit = defineEmits<{ action: [value: { id: string; action: string }]; reload: [] }>();

/**
 * The panel's own flags mapped onto the shared pane contract, in the order the
 * user cares about: a failure outranks a spinner, a spinner outranks emptiness.
 */
const paneState = computed<WorkspacePaneState>(() => {
  if (props.error) return { status: "failure", message: props.error, actionLabel: props.loading ? undefined : strings.value.retryText };
  if (props.loading) return { status: "loading" };
  if (!props.items.length) return { status: "empty", message: strings.value.emptyText };
  return { status: "ready" };
});
</script>

<template>
  <section class="scene-list" :aria-label="title">
    <h3 class="scene-list__title">{{ title }}</h3>
    <WorkspacePane
      :state="paneState"
      skeleton="conversation"
      :skeleton-rows="4"
      empty-icon="folder"
      :empty-text="strings.emptyText"
      :failure-text="strings.emptyText"
      :has-retry="true"
      @retry="emit('reload')"
    >
      <div class="scene-list__items">
        <article v-for="item in items" :key="item.id" class="scene-list__row">
          <div class="scene-list__body">
            <p class="scene-list__heading">
              <strong class="scene-list__name">{{ item.title }}</strong>
              <small v-if="item.badge" class="scene-list__badge">{{ item.badge }}</small>
            </p>
            <p class="scene-list__detail">{{ item.detail }}</p>
            <p v-if="item.error" class="scene-list__error" role="alert">{{ item.error }}</p>
            <FlareSkeleton v-if="item.busy" variant="text" :rows="1" :aria-label="item.title" role="status" />
          </div>
          <div v-if="item.actions.some(a => a.label.trim())" class="scene-list__actions">
            <FlareButton
              v-for="a in item.actions.filter(a => a.label.trim())"
              :key="a.id"
              size="sm"
              :variant="a.destructive ? 'danger' : 'secondary'"
              :label="a.label"
              :disabled="item.busy || a.disabled"
              @click="emit('action', { id: item.id, action: a.id })"
            />
          </div>
        </article>
      </div>
    </WorkspacePane>
  </section>
</template>

<style scoped>
.scene-list {
  min-width: 0;
  color: var(--flare-color-text-primary);
}
/* The 12px group title of a settings card, not a 16px page heading. */
.scene-list__title {
  margin: 0 0 var(--flare-size-spacing-sm);
  padding-inline: var(--flare-size-spacing-md);
  color: var(--flare-color-text-tertiary);
  font-size: var(--flare-size-font-size-sm);
  font-weight: 600;
}
.scene-list__items {
  max-height: 60vh;
  overflow: auto;
  overscroll-behavior: contain;
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-primary);
}
.scene-list__row {
  display: flex;
  gap: var(--flare-size-spacing-md);
  align-items: center;
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  min-height: var(--flare-size-layout-touch-target);
  border-bottom: 1px solid var(--flare-color-border-primary);
}
.scene-list__row:last-child { border-bottom: none; }
.scene-list__body { flex: 1; min-width: 0; }
.scene-list__heading { display: flex; align-items: baseline; gap: var(--flare-size-spacing-sm); margin: 0; }
.scene-list__name { font-size: var(--flare-size-font-size-lg); font-weight: 500; overflow-wrap: anywhere; }
.scene-list__badge { color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); }
.scene-list__detail {
  margin: 2px 0 0;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-sm);
  overflow-wrap: anywhere;
}
.scene-list__error { margin: 4px 0 0; color: var(--flare-color-error-text); font-size: var(--flare-size-font-size-sm); }
.scene-list__actions { display: flex; flex-wrap: wrap; gap: var(--flare-size-spacing-sm); }
</style>
