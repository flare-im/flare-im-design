<script setup lang="ts">
// Reusable adaptive modal surface — the app-mode surface for Select, TimePicker,
// DatePicker, forms and secondary panels. It presents as a bottom sheet on phone
// form factors and as a centered dialog on pointer devices (`presentation="auto"`),
// or as a side drawer when asked.
// 滚动锁、焦点陷阱、Escape、平台返回键、传送目标都来自 `useFlareModalSurface` —— 那
// 一份实现为所有模态面(面板、命令面板、图片/视频预览)共用,所以叠起来时只有最上面
// 那张收键盘,锁也不会被别的浮层清掉。这里只负责画:scrim、抓手、标题和三种出场动画。
import { computed, getCurrentInstance, ref } from "vue";
import { useFlareModalSurface } from "../../shared/useModalSurface";
import { useFlarePlatformSafe } from "../../shared/platform/useFlarePlatform";

/** How the surface appears: `auto` is a bottom sheet on phones and a dialog on pointer devices. */
export type FlareSheetPresentation = "auto" | "sheet" | "dialog" | "drawer";

const props = withDefaults(
  defineProps<{
    open: boolean;
    /** Prevent closing while an operation owns the draft. */
    dismissible?: boolean;
    /** Optional header: centered on a sheet, leading on a dialog or drawer. */
    title?: string;
    /**
     * 只把 `title` 当可及名称用，不画那行可见标题。
     * 动作面板就是这种：底下每一条都是一句完整的动作，上面再写一遍面板叫什么
     * （「新建」）只是重复了刚才点的那颗按钮 —— 但读屏仍然需要这个名字。
     */
    titleHidden?: boolean;
    /** Cap the sheet or dialog height (e.g. "72vh"); a drawer is full height. */
    maxHeight?: string;
    /**
     * 弹窗形态下这张面有多宽,写进既有的 `--flare-component-sheet-dialog-width` 缝。
     *
     * 为什么要给个 prop:这个组件的根是 `<Teleport>`,Vue 无处安放透传属性,宿主写
     * 的 `class` 会连着一行告警被丢掉;而自定义属性顺 DOM 继承,面被传送到浮层容器
     * 之后也收不到宿主那边设的值。全局搜索的 720px 弹窗宽度就这么静默失效过。
     */
    dialogWidth?: string;
    presentation?: FlareSheetPresentation;
  }>(),
  { maxHeight: "72vh", dismissible: true, presentation: "auto", titleHidden: false },
);
const platform = useFlarePlatformSafe();
const resolvedPresentation = computed<Exclude<FlareSheetPresentation, "auto">>(() => {
  if (props.presentation !== "auto") return props.presentation;
  return platform.capabilities.value.bottomSheet ? "sheet" : "dialog";
});
const sheetStyle = computed(() => {
  const style: Record<string, string> = {};
  if (resolvedPresentation.value !== "drawer") style.maxHeight = props.maxHeight;
  if (props.dialogWidth) style["--flare-component-sheet-dialog-width"] = props.dialogWidth;
  return style;
});
const surfaceTransition = computed(() => ({ sheet: "flare-sheet-rise", dialog: "flare-sheet-pop", drawer: "flare-sheet-slide" })[resolvedPresentation.value]);
const emit = defineEmits<{ (e: "close"): void }>();
const instance = getCurrentInstance();
const sheetEl = ref<HTMLElement | null>(null);

// 平台返回键只在宿主真的接了 close 时才接管:会话行各自挂着一张关着的面板,
// 没人听 close 的那些不该把返回键吞掉。
const { overlayContainer } = useFlareModalSurface({
  open: () => props.open,
  surface: sheetEl,
  dismissible: () => props.dismissible,
  nativeBack: () => Boolean(instance?.vnode.props?.onClose),
  onRequestClose: () => emit("close"),
});
</script>

<template>
  <Teleport :to="overlayContainer">
    <transition name="flare-sheet-fade">
      <div v-if="open" class="flare-sheet-scrim" :class="`flare-sheet-scrim--${resolvedPresentation}`" @click="dismissible && emit('close')">
        <transition :name="surfaceTransition" appear>
          <div
            ref="sheetEl"
            class="flare-sheet"
            :class="`flare-sheet--${resolvedPresentation}`"
            :style="sheetStyle"
            role="dialog"
            :aria-label="title"
            aria-modal="true"
            tabindex="-1"
            :data-flare-presentation="resolvedPresentation"
            @click.stop
          >
            <div v-if="resolvedPresentation === 'sheet'" class="flare-sheet__grip" aria-hidden="true" />
            <div v-if="title && !titleHidden" class="flare-sheet__title">{{ title }}</div>
            <slot />
          </div>
        </transition>
      </div>
    </transition>
  </Teleport>
</template>

<style scoped>
.flare-sheet-scrim {
  position: fixed;
  inset: 0;
  z-index: var(--flare-z-index-modal);
  display: flex;
  align-items: flex-end;
  justify-content: center;
  background: rgba(21, 18, 32, 0.44);
}
.flare-sheet {
  box-sizing: border-box;
  min-width: 0;
  width: 100%;
  max-width: 640px;
  display: flex;
  flex-direction: column;
  padding: 8px 8px calc(8px + env(safe-area-inset-bottom, 0px));
  background: var(--flare-color-bg-primary);
  border-radius: 20px 20px 0 0;
  box-shadow: var(--flare-shadow-lg);
  outline: none;
  /* 这张面自己封了高度,那就得自己负责滚 —— 不然内容比上限高时,底下那几行谁也够不着
     (消息长按操作表就这么把「删除」挡在过 482px 的外面)。内部已经有滚动容器的宿主不受
     影响:它撑不出去,这一层永远不会出现第二根滚动条。抽屉本来就是这么做的。 */
  overflow-y: auto;
  overscroll-behavior: contain;
}
.flare-sheet__grip { width: 36px; height: 4px; border-radius: 999px; background: var(--flare-color-border-primary); margin: 6px auto 8px; flex: 0 0 auto; }
.flare-sheet__title { padding: 4px 12px 8px; font-size: 13px; font-weight: 500; color: var(--flare-color-text-tertiary); text-align: center; }

/* Dialog: centered on pointer devices, all corners rounded, no grip. */
.flare-sheet-scrim--dialog { align-items: center; padding: var(--flare-size-spacing-xl); box-sizing: border-box; }
.flare-sheet--dialog { max-width: var(--flare-component-sheet-dialog-width); padding: var(--flare-size-spacing-sm); border-radius: var(--flare-size-radius-xl); }

/* Drawer: full height at the inline end, for longer secondary panels. */
.flare-sheet-scrim--drawer { align-items: stretch; justify-content: flex-end; }
.flare-sheet--drawer { max-width: 420px; height: 100%; padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-sm) calc(var(--flare-size-spacing-sm) + env(safe-area-inset-bottom, 0px)); border-radius: 0; border-start-start-radius: var(--flare-size-radius-xl); border-end-start-radius: var(--flare-size-radius-xl); }

.flare-sheet--dialog .flare-sheet__title,
.flare-sheet--drawer .flare-sheet__title { padding: var(--flare-size-spacing-md) var(--flare-size-spacing-lg) var(--flare-size-spacing-xs); font-size: var(--flare-size-font-size-lg); font-weight: 600; color: var(--flare-color-text-primary); text-align: start; }

.flare-sheet-fade-enter-active, .flare-sheet-fade-leave-active { transition: opacity 0.22s ease; }
.flare-sheet-fade-enter-from, .flare-sheet-fade-leave-to { opacity: 0; }
.flare-sheet-rise-enter-active { transition: transform 0.28s cubic-bezier(0.16, 1, 0.3, 1); }
.flare-sheet-rise-leave-active { transition: transform 0.2s ease; }
.flare-sheet-rise-enter-from, .flare-sheet-rise-leave-to { transform: translateY(100%); }
.flare-sheet-pop-enter-active, .flare-sheet-pop-leave-active { transition: opacity var(--flare-transition-normal), transform var(--flare-transition-normal); }
.flare-sheet-pop-enter-from, .flare-sheet-pop-leave-to { opacity: 0; transform: scale(0.96); }
.flare-sheet-slide-enter-active, .flare-sheet-slide-leave-active { transition: transform var(--flare-transition-normal); }
.flare-sheet-slide-enter-from, .flare-sheet-slide-leave-to { transform: translateX(100%); }
:dir(rtl) .flare-sheet-slide-enter-from, :dir(rtl) .flare-sheet-slide-leave-to { transform: translateX(-100%); }
@media (prefers-reduced-motion: reduce) {
  .flare-sheet-rise-enter-active, .flare-sheet-rise-leave-active,
  .flare-sheet-pop-enter-active, .flare-sheet-pop-leave-active,
  .flare-sheet-slide-enter-active, .flare-sheet-slide-leave-active { transition: none; }
}
</style>
