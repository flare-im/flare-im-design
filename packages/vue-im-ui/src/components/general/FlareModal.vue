<script setup lang="ts">
// FlareModal — 遮罩上的居中面板,给聚焦任务用(全局搜索、较宽的编辑流程)。
//
// 它是 kit 里唯一的「居中模态框」实现:FlareBottomSheet 的 auto 在非手机形态下把内容
// 交给它(委托,不是第二套对话框),宿主要一个居中框也直接用它。滚动锁、焦点陷阱、
// Escape、平台返回键与传送目标都来自 useFlareModalSurface,和别的模态面共用一个栈。
//
// DOM 契约(测试与宿主样式都依赖):面上有 role="dialog"、aria-modal、aria-label
// (title → label → 兜底「对话框」)与 data-flare-presentation="dialog";遮罩带共用类
// `flare-overlay-scrim`。组件根是 Teleport,宿主传来的属性会被丢掉,所以这些都由这里自己画。
import { computed, getCurrentInstance, ref, useSlots } from "vue";
import FlareIconButton from "./FlareIconButton.vue";
import { flareIcons } from "../../shared/icons";
import { useFlareModalSurface } from "../../shared/useModalSurface";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformSafe } from "../../shared/platform/useFlarePlatform";

const props = withDefaults(
  defineProps<{
    open: boolean;
    /** Optional header, also the accessible name; leads the header row. */
    title?: string;
    /** Use `title` as the accessible name only, without drawing the heading. */
    titleHidden?: boolean;
    /** Accessible name when there is no visible title. */
    label?: string;
    /** Box width as a CSS length; defaults to the sheetDialogWidth token and never exceeds the window gutter. */
    width?: string;
    /** Height cap as a CSS length. */
    maxHeight?: string;
    /** Fixed-height mode: the box takes its whole `maxHeight`, so page-like content does not resize as it loads. */
    fill?: boolean;
    /** Allow the scrim, Escape, platform back and the close button to close the modal. */
    dismissible?: boolean;
    /** Draw the header close button; disabled while not dismissible or busy. */
    showClose?: boolean;
    /** An operation owns the modal: every way of closing it is disabled. */
    busy?: boolean;
    /** The body scrolls; false hands the content a bounded box and lets it own its scrolling. */
    scrollable?: boolean;
  }>(),
  { titleHidden: false, maxHeight: "72vh", fill: false, dismissible: true, showClose: true, busy: false, scrollable: true },
);
const emit = defineEmits<{ (e: "close"): void }>();
const slots = useSlots();
const instance = getCurrentInstance();
const { t } = useFlareI18nOptional();
const platform = useFlarePlatformSafe();
const surfaceEl = ref<HTMLElement | null>(null);

const canDismiss = computed(() => props.dismissible && !props.busy);
const accessibleName = computed(() => props.title || props.label || t("common.modalLabel"));
const showTitle = computed(() => Boolean(props.title) && !props.titleHidden);
const hasHeader = computed(() => showTitle.value || props.showClose || Boolean(slots.actions));
// 手机形态下(本来就很少走到这里,auto 会给底部面板)底部按钮行竖排、占满整行。
const compact = computed(() => platform.capabilities.value.bottomSheet);

const surfaceStyle = computed(() => {
  const style: Record<string, string> = { maxHeight: props.maxHeight };
  if (props.fill) style.height = props.maxHeight;
  if (props.width) style["--flare-modal-width"] = props.width;
  return style;
});

function requestClose(): void {
  if (canDismiss.value) emit("close");
}

// 平台返回键只在宿主真的接了 close 时才接管:没人听的模态不该把返回键吞掉。
const { overlayContainer } = useFlareModalSurface({
  open: () => props.open,
  surface: surfaceEl,
  dismissible: () => canDismiss.value,
  nativeBack: () => Boolean(instance?.vnode.props?.onClose),
  onRequestClose: () => emit("close"),
});
</script>

<template>
  <Teleport :to="overlayContainer">
    <transition name="flare-modal-fade">
      <div v-if="open" class="flare-overlay-scrim flare-modal-scrim" @click="requestClose">
        <div
          ref="surfaceEl"
          class="flare-modal"
          :class="{ 'flare-modal--fill': fill, 'flare-modal--compact': compact }"
          :style="surfaceStyle"
          role="dialog"
          aria-modal="true"
          :aria-label="accessibleName"
          :aria-busy="busy || undefined"
          tabindex="-1"
          data-flare-presentation="dialog"
          @click.stop
        >
          <!-- 页头控件标成 overlay chrome:打开时初始焦点先给内容,不落在关闭键上。 -->
          <header v-if="hasHeader" class="flare-modal__header" data-flare-overlay-chrome>
            <h2 v-if="showTitle" class="flare-modal__title">{{ title }}</h2>
            <span v-else class="flare-modal__spacer" aria-hidden="true" />
            <div v-if="$slots.actions" class="flare-modal__actions"><slot name="actions" /></div>
            <FlareIconButton
              v-if="showClose"
              class="flare-modal__close"
              :icon="flareIcons.close"
              :ariaLabel="t('common.close')"
              :disabled="!canDismiss"
              @click="requestClose"
            />
          </header>
          <div class="flare-modal__body" :class="{ 'flare-modal__body--fixed': !scrollable }">
            <slot />
          </div>
          <footer v-if="$slots.footer" class="flare-modal__footer">
            <slot name="footer" />
          </footer>
        </div>
      </div>
    </transition>
  </Teleport>
</template>

<style scoped>
.flare-modal-scrim {
  position: fixed;
  inset: 0;
  z-index: var(--flare-z-index-modal);
  display: flex;
  align-items: center;
  justify-content: center;
  box-sizing: border-box;
  padding: var(--flare-size-spacing-xl);
  background: var(--flare-color-scrim);
}
.flare-modal {
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  min-width: 0;
  /* 实例宽度(width prop)优先;否则是宿主作用域里可改的组件令牌 --flare-component-sheet-dialog-width
     (2.0 公开的缝,宽一些的搜索面板就改它),它默认就是 sheetDialogWidth 尺寸令牌。 */
  width: min(var(--flare-modal-width, var(--flare-component-sheet-dialog-width, var(--flare-size-component-sheet-dialog-width))), 100%);
  padding: var(--flare-size-spacing-sm);
  background: var(--flare-color-bg-primary);
  border-radius: var(--flare-size-radius-xl);
  box-shadow: var(--flare-shadow-lg);
  outline: none;
}
.flare-modal__header {
  flex: 0 0 auto;
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
}
.flare-modal__title {
  flex: 1 1 auto;
  min-width: 0;
  margin: 0;
  padding: var(--flare-size-spacing-md) var(--flare-size-spacing-lg) var(--flare-size-spacing-xs);
  font-size: var(--flare-size-font-size-lg);
  font-weight: 600;
  color: var(--flare-color-text-primary);
  text-align: start;
  overflow-wrap: anywhere;
}
.flare-modal__spacer { flex: 1 1 auto; }
.flare-modal__actions {
  flex: 0 0 auto;
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
}
.flare-modal__close { flex: 0 0 auto; }
/* 封了高度的面自己负责滚,否则内容比上限高时末几行谁也够不着;页头与底部按钮行留在原位。 */
.flare-modal__body {
  flex: 1 1 auto;
  min-height: 0;
  overflow-y: auto;
  overscroll-behavior: contain;
}
/* 内容自己管滚动(列表、搜索结果):给它一个有界的盒子,不再套第二层滚动。 */
.flare-modal__body--fixed {
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.flare-modal__footer {
  flex: 0 0 auto;
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-end;
  gap: var(--flare-size-spacing-sm);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg) var(--flare-size-spacing-xs);
}
.flare-modal--compact .flare-modal__footer {
  flex-direction: column-reverse;
  align-items: stretch;
}

/* 面的出场跟着遮罩的过渡类走:嵌套的 <transition> 在外层 v-if 离场时不会播放自己的 leave。 */
.flare-modal-fade-enter-active,
.flare-modal-fade-leave-active { transition: opacity var(--flare-transition-normal); }
.flare-modal-fade-enter-from,
.flare-modal-fade-leave-to { opacity: 0; }
.flare-modal-fade-enter-active .flare-modal,
.flare-modal-fade-leave-active .flare-modal { transition: transform var(--flare-transition-normal); }
.flare-modal-fade-enter-from .flare-modal,
.flare-modal-fade-leave-to .flare-modal { transform: scale(0.96); }
@media (prefers-reduced-motion: reduce) {
  .flare-modal-fade-enter-active,
  .flare-modal-fade-leave-active,
  .flare-modal-fade-enter-active .flare-modal,
  .flare-modal-fade-leave-active .flare-modal { transition: none; }
}
</style>
