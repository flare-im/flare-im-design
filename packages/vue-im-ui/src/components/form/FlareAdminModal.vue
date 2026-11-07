<script setup lang="ts">
/** A focused admin task, rendered by real Naive Modal/Card; never owns a write. */
import { computed, getCurrentInstance, nextTick, ref, watch } from "vue";
import { NButton, NCard, NModal } from "naive-ui";
import { X } from "@lucide/vue";
import { useFlareModalSurface } from "../../shared/useModalSurface";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

defineOptions({ inheritAttrs: false });
const props = withDefaults(
  defineProps<{
    open: boolean;
    title?: string;
    label?: string;
    width?: string;
    dismissible?: boolean;
    showClose?: boolean;
  }>(),
  { width: "560px", dismissible: true, showClose: true },
);
const emit = defineEmits<{ close: [] }>();
const { t } = useFlareI18nOptional();
const instance = getCurrentInstance();
const surface = ref<HTMLElement | null>(null);
const accessibleName = computed(
  () => props.title || props.label || t("common.modalLabel"),
);
function requestClose() {
  if (props.dismissible) emit("close");
}
// One interaction owner across a detail drawer, this Native modal and its Popconfirm.
// Native still owns rendering/transition/mask; the existing Kit stack owns focus,
// scroll locks, Escape and platform back, rather than two competing focus traps.
const { overlayContainer, isTopmost } = useFlareModalSurface({
  open: () => props.open,
  surface,
  dismissible: () => props.dismissible,
  autoFocus: false,
  nativeBack: () => Boolean(instance?.vnode.props?.onClose),
  onRequestClose: requestClose,
});
function focusContent() {
  if (!props.open || !isTopmost() || !surface.value) return;
  if (surface.value.contains(document.activeElement)) return;
  const field = surface.value.querySelector<HTMLElement>(
    '.flare-admin-modal__body input:not([disabled]), .flare-admin-modal__body textarea:not([disabled]), .flare-admin-modal__body button:not([disabled]), .flare-admin-modal__body [tabindex="0"]',
  );
  (field ?? surface.value).focus({ preventScroll: true });
}
watch(surface, () => void nextTick(focusContent));
</script>

<template>
  <NModal
    :show="open"
    :to="overlayContainer"
    transform-origin="center"
    :mask-closable="dismissible"
    :close-on-esc="false"
    :trap-focus="false"
    :auto-focus="false"
    :block-scroll="false"
    @update:show="
      (show: boolean) => {
        if (!show) requestClose();
      }
    "
    @after-enter="focusContent"
  >
    <div
      ref="surface"
      v-bind="$attrs"
      class="flare-admin-modal"
      :style="{ '--flare-admin-modal-width': width }"
      role="dialog"
      aria-modal="true"
      :aria-label="accessibleName"
      tabindex="-1"
      data-flare-presentation="dialog"
    >
      <NCard
        class="flare-admin-modal__card"
        size="small"
        :bordered="false"
        :segmented="{ footer: true }"
        :content-style="{
          padding: '0',
          minHeight: '0',
          display: 'flex',
          flexDirection: 'column',
        }"
      >
        <template #header>
          <span class="flare-admin-modal__title">{{ accessibleName }}</span>
        </template>
        <template #header-extra>
          <div
            class="flare-admin-modal__header-actions"
            data-flare-overlay-chrome
          >
            <slot name="actions" />
            <NButton
              v-if="showClose"
              size="small"
              text
              :disabled="!dismissible"
              :aria-label="t('common.close')"
              @click="requestClose"
            >
              <X :size="16" aria-hidden="true" />
            </NButton>
          </div>
        </template>
        <div class="flare-admin-modal__body"><slot /></div>
        <template v-if="$slots.footer" #footer>
          <div class="flare-admin-modal__footer"><slot name="footer" /></div>
        </template>
      </NCard>
    </div>
  </NModal>
</template>

<style scoped>
.flare-admin-modal {
  width: min(
    var(--flare-admin-modal-width),
    calc(100vw - 2 * var(--flare-size-spacing-md))
  );
  max-height: calc(100vh - 2 * var(--flare-size-spacing-xl));
  max-height: calc(100dvh - 2 * var(--flare-size-spacing-xl));
  display: flex;
  min-width: 0;
  outline: none;
}
.flare-admin-modal__card {
  max-height: inherit;
  min-height: 0;
  min-width: 0;
}
.flare-admin-modal__card :deep(.n-card-header) {
  padding: var(--flare-size-spacing-md);
  gap: var(--flare-size-spacing-sm);
}
.flare-admin-modal__title {
  margin: 0;
  font-size: var(--flare-text-body-font-size);
  font-weight: 600;
  overflow-wrap: anywhere;
}
.flare-admin-modal__header-actions,
.flare-admin-modal__footer {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  flex-wrap: wrap;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
}
.flare-admin-modal__body {
  min-height: 0;
  min-width: 0;
  overflow: auto;
  overscroll-behavior: contain;
  overflow-wrap: anywhere;
  padding: var(--flare-size-spacing-md);
}
.flare-admin-modal__card :deep(.n-card__footer) {
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  flex: 0 0 auto;
  max-height: 35dvh;
  overflow: auto;
}
@media (max-width: 640px) {
  .flare-admin-modal {
    max-height: calc(100vh - 2 * var(--flare-size-spacing-md));
    max-height: calc(100dvh - 2 * var(--flare-size-spacing-md));
  }
}
</style>
