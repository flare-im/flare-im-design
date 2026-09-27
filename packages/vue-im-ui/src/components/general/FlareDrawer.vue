<script setup lang="ts">
// FlareDrawer — 从行尾(默认)或行首滑出的全高模态面板,承载长驻的次级内容:会话 / 群 /
// 联系人详情、设置栈、资料编辑。宽布局用它,手机形态下它占满整宽(宿主若按单栏布局
// 事实改走页面,那是宿主的决定)。
//
// 页内导航由宿主驱动:宿主在默认插槽里换页,并用 `showBack` 画返回键;此时 Escape 与
// 平台返回键发出 `back` 而不是 `close`,只有遮罩和关闭键关掉整个抽屉。换页后焦点回到
// 标题(或面本身),Tab 陷阱在焦点丢失时也会把它拉回来(useFlareModalSurface)。
//
// DOM 契约同 FlareModal:role="dialog"、aria-modal、aria-label(title → label → 兜底
// 「侧边面板」)、data-flare-presentation="drawer",遮罩带共用类 `flare-overlay-scrim`。
import { computed, getCurrentInstance, nextTick, ref, useSlots, watch } from "vue";
import FlareIconButton from "./FlareIconButton.vue";
import { flareIcons } from "../../shared/icons";
import { useFlareModalSurface } from "../../shared/useModalSurface";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformSafe } from "../../shared/platform/useFlarePlatform";

/** Edge the drawer docks to, in inline (RTL-aware) terms. */
export type FlareDrawerPlacement = "end" | "start";

const props = withDefaults(
  defineProps<{
    open: boolean;
    /** Optional header, also the accessible name; leads the header row. */
    title?: string;
    /** Use `title` as the accessible name only, without drawing the heading. */
    titleHidden?: boolean;
    /** Accessible name when there is no visible title (page content that brings its own header). */
    label?: string;
    placement?: FlareDrawerPlacement;
    /** Panel width as a CSS length; defaults to the sheetWidth token and always leaves a scrim gutter. */
    width?: string;
    /** Allow the scrim, Escape, platform back and the header buttons to close or go back. */
    dismissible?: boolean;
    /** Draw the header close button. */
    showClose?: boolean;
    /** Draw a leading back button; Escape and platform back then emit `back` instead of `close`. */
    showBack?: boolean;
  }>(),
  { titleHidden: false, placement: "end", dismissible: true, showClose: true, showBack: false },
);
const emit = defineEmits<{ (e: "close"): void; (e: "back"): void }>();
const slots = useSlots();
const instance = getCurrentInstance();
const { t } = useFlareI18nOptional();
const platform = useFlarePlatformSafe();
const surfaceEl = ref<HTMLElement | null>(null);
const headingEl = ref<HTMLElement | null>(null);

const accessibleName = computed(() => props.title || props.label || t("common.drawerLabel"));
const showTitle = computed(() => Boolean(props.title) && !props.titleHidden);
const hasHeader = computed(() => showTitle.value || props.showBack || props.showClose || Boolean(slots.actions));
// 手机形态下抽屉占满整宽:应用不必自己去算「现在是不是手机」。
const compact = computed(() => platform.capabilities.value.bottomSheet);

const surfaceStyle = computed(() => (props.width ? { "--flare-drawer-width": props.width } : {}));

function requestClose(): void {
  if (props.dismissible) emit("close");
}
function requestBack(): void {
  if (props.dismissible) emit("back");
}

// 平台返回键只在宿主接了 close 或 back 时才接管;按下时按当下的 showBack 决定是退一页还是关掉。
const { overlayContainer } = useFlareModalSurface({
  open: () => props.open,
  surface: surfaceEl,
  dismissible: () => props.dismissible,
  nativeBack: () => Boolean(instance?.vnode.props?.onClose || instance?.vnode.props?.onBack),
  onRequestClose: () => (props.showBack ? emit("back") : emit("close")),
});

// 宿主在抽屉里换了一页:返回键出现或消失时总把焦点送回标题;只换了标题时,仅在焦点跟着
// 旧页面一起丢了(落回 body 或遮罩后面)才送回来 —— 标题里带计数的页面不该在输入时被抢焦点。
watch(
  () => [props.showBack, props.title] as const,
  ([back], [previousBack]) => {
    if (!props.open) return;
    void nextTick(() => {
      const surface = surfaceEl.value;
      if (!surface) return;
      if (back === previousBack && surface.contains(document.activeElement)) return;
      (headingEl.value ?? surface).focus({ preventScroll: true });
    });
  },
);
</script>

<template>
  <Teleport :to="overlayContainer">
    <transition name="flare-drawer-fade">
      <div
        v-if="open"
        class="flare-overlay-scrim flare-drawer-scrim"
        :class="`flare-drawer-scrim--${placement}`"
        @click="requestClose"
      >
        <div
          ref="surfaceEl"
          class="flare-drawer"
          :class="[`flare-drawer--${placement}`, { 'flare-drawer--compact': compact }]"
          :style="surfaceStyle"
          role="dialog"
          aria-modal="true"
          :aria-label="accessibleName"
          tabindex="-1"
          data-flare-presentation="drawer"
          :data-flare-placement="placement"
          @click.stop
        >
          <!-- 页头控件标成 overlay chrome:打开时初始焦点先给内容,不落在返回或关闭键上。 -->
          <header v-if="hasHeader" class="flare-drawer__header" data-flare-overlay-chrome>
            <FlareIconButton
              v-if="showBack"
              class="flare-drawer__back"
              :icon="flareIcons.back"
              :ariaLabel="t('common.back')"
              :disabled="!dismissible"
              @click="requestBack"
            />
            <h2 v-if="showTitle" ref="headingEl" class="flare-drawer__title" tabindex="-1">{{ title }}</h2>
            <span v-else class="flare-drawer__spacer" aria-hidden="true" />
            <div v-if="$slots.actions" class="flare-drawer__actions"><slot name="actions" /></div>
            <FlareIconButton
              v-if="showClose"
              class="flare-drawer__close"
              :icon="flareIcons.close"
              :ariaLabel="t('common.close')"
              :disabled="!dismissible"
              @click="requestClose"
            />
          </header>
          <div class="flare-drawer__body" :class="{ 'flare-drawer__body--last': !$slots.footer }">
            <slot />
          </div>
          <footer v-if="$slots.footer" class="flare-drawer__footer">
            <slot name="footer" />
          </footer>
        </div>
      </div>
    </transition>
  </Teleport>
</template>

<style scoped>
.flare-drawer-scrim {
  position: fixed;
  inset: 0;
  z-index: var(--flare-z-index-modal);
  display: flex;
  align-items: stretch;
  background: var(--flare-color-scrim);
}
.flare-drawer-scrim--end { justify-content: flex-end; }
.flare-drawer-scrim--start { justify-content: flex-start; }
.flare-drawer {
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  min-width: 0;
  height: 100%;
  /* 实例宽度(width prop)优先;否则是组件令牌 --flare-component-sheet-width,默认即 sheetWidth 尺寸令牌。
     无论给多宽,总留一条触达尺寸宽的遮罩可点。 */
  width: min(var(--flare-drawer-width, var(--flare-component-sheet-width, var(--flare-size-component-sheet-width))), calc(100% - var(--flare-size-layout-touch-target)));
  padding-top: env(safe-area-inset-top, 0px);
  padding-left: env(safe-area-inset-left, 0px);
  padding-right: env(safe-area-inset-right, 0px);
  background: var(--flare-color-bg-primary);
  box-shadow: var(--flare-shadow-lg);
  outline: none;
}
.flare-drawer--end {
  border-start-start-radius: var(--flare-size-radius-xl);
  border-end-start-radius: var(--flare-size-radius-xl);
}
.flare-drawer--start {
  border-start-end-radius: var(--flare-size-radius-xl);
  border-end-end-radius: var(--flare-size-radius-xl);
}
.flare-drawer--compact {
  width: 100%;
  border-radius: 0;
}
.flare-drawer__header {
  flex: 0 0 auto;
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
  padding: var(--flare-size-spacing-sm);
}
.flare-drawer__title {
  flex: 1 1 auto;
  min-width: 0;
  margin: 0;
  padding-inline: var(--flare-size-spacing-sm);
  font-size: var(--flare-size-font-size-lg);
  font-weight: 600;
  color: var(--flare-color-text-primary);
  text-align: start;
  overflow-wrap: anywhere;
  outline: none;
}
.flare-drawer__spacer { flex: 1 1 auto; }
.flare-drawer__actions {
  flex: 0 0 auto;
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
}
.flare-drawer__back,
.flare-drawer__close { flex: 0 0 auto; }
.flare-drawer__body {
  flex: 1 1 auto;
  min-height: 0;
  display: flex;
  flex-direction: column;
  overflow-y: auto;
  overscroll-behavior: contain;
}
.flare-drawer__body--last { padding-bottom: env(safe-area-inset-bottom, 0px); }
.flare-drawer__footer {
  flex: 0 0 auto;
  display: flex;
  justify-content: flex-end;
  gap: var(--flare-size-spacing-sm);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md) calc(var(--flare-size-spacing-sm) + env(safe-area-inset-bottom, 0px));
  border-top: 1px solid var(--flare-color-border-primary);
}

/* 面的出场跟着遮罩的过渡类走:嵌套的 <transition> 在外层 v-if 离场时不会播放自己的 leave,
   抽屉就会一下子消失。两者用同一时长,Vue 按遮罩的过渡结束移除节点。 */
.flare-drawer-fade-enter-active,
.flare-drawer-fade-leave-active { transition: opacity var(--flare-transition-normal); }
.flare-drawer-fade-enter-from,
.flare-drawer-fade-leave-to { opacity: 0; }
.flare-drawer-fade-enter-active .flare-drawer,
.flare-drawer-fade-leave-active .flare-drawer { transition: transform var(--flare-transition-normal); }
.flare-drawer-fade-enter-from .flare-drawer--end,
.flare-drawer-fade-leave-to .flare-drawer--end { transform: translateX(100%); }
.flare-drawer-fade-enter-from .flare-drawer--start,
.flare-drawer-fade-leave-to .flare-drawer--start { transform: translateX(-100%); }
.flare-drawer-fade-enter-from .flare-drawer--end:dir(rtl),
.flare-drawer-fade-leave-to .flare-drawer--end:dir(rtl) { transform: translateX(-100%); }
.flare-drawer-fade-enter-from .flare-drawer--start:dir(rtl),
.flare-drawer-fade-leave-to .flare-drawer--start:dir(rtl) { transform: translateX(100%); }
/* 减少动态效果:不滑、遮罩也瞬间出现。 */
@media (prefers-reduced-motion: reduce) {
  .flare-drawer-fade-enter-active,
  .flare-drawer-fade-leave-active,
  .flare-drawer-fade-enter-active .flare-drawer,
  .flare-drawer-fade-leave-active .flare-drawer { transition: none; }
}
</style>
