<script setup lang="ts">
// Reusable adaptive surface for short, focused tasks — Select, TimePicker, DatePicker, forms,
// confirms and prompts. `presentation="auto"` is a bottom sheet on the phone form factor and
// otherwise hands the same content to FlareModal (delegation, not a second dialog). A centered
// box on its own is FlareModal; a side panel is FlareDrawer — the former `dialog` / `drawer`
// values are gone, so there is one implementation of each.
// 滚动锁、焦点陷阱、Escape、平台返回键、传送目标都来自 `useFlareModalSurface` —— 那一份
// 实现为所有模态面共用。底部面板那一支在这里登记自己的面;交给 FlareModal 时由它登记,
// 这里不再重复登记(否则栈、锁计数与返回键认领都会翻倍)。
import { computed, getCurrentInstance, ref, watch } from "vue";
import FlareModal from "./FlareModal.vue";
import { useFlareModalSurface } from "../../shared/useModalSurface";
import { useFlarePlatformSafe } from "../../shared/platform/useFlarePlatform";

/** How the surface appears: `auto` is a bottom sheet on phones and a FlareModal elsewhere; `sheet` always a sheet. */
export type FlareSheetPresentation = "auto" | "sheet";

const props = withDefaults(
  defineProps<{
    open: boolean;
    /** Prevent closing while an operation owns the draft. */
    dismissible?: boolean;
    /** Optional header: centered on a sheet, leading when handed to FlareModal. */
    title?: string;
    /**
     * 只把 `title` 当可及名称用，不画那行可见标题。
     * 动作面板就是这种：底下每一条都是一句完整的动作，上面再写一遍面板叫什么
     * （「新建」）只是重复了刚才点的那颗按钮 —— 但读屏仍然需要这个名字。
     */
    titleHidden?: boolean;
    /** Cap the surface height (e.g. "72vh"). */
    maxHeight?: string;
    /**
     * 交给 FlareModal 时这张面有多宽(转成 FlareModal 的 `width`)。
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
const emit = defineEmits<{ (e: "close"): void }>();
const instance = getCurrentInstance();
const platform = useFlarePlatformSafe();
const sheetEl = ref<HTMLElement | null>(null);

function resolvePresentation(): "sheet" | "dialog" {
  if (props.presentation === "sheet") return "sheet";
  return platform.capabilities.value.bottomSheet ? "sheet" : "dialog";
}
// auto 在打开的那一刻判定一次,关掉之前不变:开着时跨过断点(或壳层切了形态)若换成另一支,
// 插槽会被重挂载 —— 输入框里的字、滚动位置、选择器的搜索词都会丢,出场动画也会重播。
// 同步 watch:在这一次渲染之前就换好,打开那一帧画的就是新判定的那一支。
const resolvedPresentation = ref(resolvePresentation());
watch(
  () => props.open,
  (isOpen) => {
    if (isOpen) resolvedPresentation.value = resolvePresentation();
  },
  { flush: "sync" },
);

const sheetStyle = computed(() => ({ maxHeight: props.maxHeight }));

// 平台返回键只在宿主真的接了 close 时才接管:会话行各自挂着一张关着的面板,
// 没人听 close 的那些不该把返回键吞掉。交给 FlareModal 时也一样:只有宿主听了 close,
// 才把监听转给它 —— FlareModal 的认领条件看的正是自己有没有 onClose。
function hostListensClose(): boolean {
  return Boolean(instance?.vnode.props?.onClose);
}
function modalListeners(): Record<string, () => void> {
  return hostListensClose() ? { onClose: () => emit("close") } : {};
}

const { overlayContainer } = useFlareModalSurface({
  open: () => props.open && resolvedPresentation.value === "sheet",
  surface: sheetEl,
  dismissible: () => props.dismissible,
  nativeBack: hostListensClose,
  onRequestClose: () => emit("close"),
});
</script>

<template>
  <FlareModal
    v-if="resolvedPresentation === 'dialog'"
    :open="open"
    :title="title"
    :title-hidden="titleHidden"
    :dismissible="dismissible"
    :max-height="maxHeight"
    :width="dialogWidth"
    :show-close="false"
    v-bind="modalListeners()"
  >
    <slot />
  </FlareModal>
  <Teleport v-else :to="overlayContainer">
    <transition name="flare-sheet-fade">
      <div v-if="open" class="flare-overlay-scrim flare-sheet-scrim" @click="dismissible && emit('close')">
        <div
          ref="sheetEl"
          class="flare-sheet"
          :style="sheetStyle"
          role="dialog"
          :aria-label="title"
          aria-modal="true"
          tabindex="-1"
          data-flare-presentation="sheet"
          @click.stop
        >
          <div class="flare-sheet__grip" aria-hidden="true" />
          <div v-if="title && !titleHidden" class="flare-sheet__title">{{ title }}</div>
          <slot />
        </div>
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
  background: var(--flare-color-scrim);
}
.flare-sheet {
  box-sizing: border-box;
  min-width: 0;
  width: 100%;
  max-width: var(--flare-size-layout-bubble-max-width);
  display: flex;
  flex-direction: column;
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-sm) calc(var(--flare-size-spacing-sm) + env(safe-area-inset-bottom, 0px));
  background: var(--flare-color-bg-primary);
  border-radius: var(--flare-size-radius-2xl) var(--flare-size-radius-2xl) 0 0;
  box-shadow: var(--flare-shadow-lg);
  outline: none;
  /* 这张面自己封了高度,那就得自己负责滚 —— 不然内容比上限高时,底下那几行谁也够不着
     (消息长按操作表就这么把「删除」挡在过 482px 的外面)。内部已经有滚动容器的宿主不受
     影响:它撑不出去,这一层永远不会出现第二根滚动条。 */
  overflow-y: auto;
  overscroll-behavior: contain;
}
.flare-sheet__grip { width: 36px; height: 4px; border-radius: 999px; background: var(--flare-color-border-primary); margin: 6px auto 8px; flex: 0 0 auto; }
.flare-sheet__title { padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-md) var(--flare-size-spacing-sm); font-size: var(--flare-size-font-size-md); font-weight: 500; color: var(--flare-color-text-tertiary); text-align: center; }

/* 面的升起跟着遮罩的过渡类走:嵌套的 <transition> 在外层 v-if 离场时不会播放自己的 leave,
   面板会一下子消失。遮罩与面用同一时长,Vue 按遮罩的过渡结束移除节点。 */
.flare-sheet-fade-enter-active { transition: opacity var(--flare-transition-slow); }
.flare-sheet-fade-leave-active { transition: opacity var(--flare-transition-normal); }
.flare-sheet-fade-enter-from,
.flare-sheet-fade-leave-to { opacity: 0; }
.flare-sheet-fade-enter-active .flare-sheet { transition: transform var(--flare-transition-slow); }
.flare-sheet-fade-leave-active .flare-sheet { transition: transform var(--flare-transition-normal); }
.flare-sheet-fade-enter-from .flare-sheet,
.flare-sheet-fade-leave-to .flare-sheet { transform: translateY(100%); }
/* 减少动态效果:不升起、遮罩也瞬间出现(契约 reducedMotionBehavior)。 */
@media (prefers-reduced-motion: reduce) {
  .flare-sheet-fade-enter-active,
  .flare-sheet-fade-leave-active,
  .flare-sheet-fade-enter-active .flare-sheet,
  .flare-sheet-fade-leave-active .flare-sheet { transition: none; }
}
</style>
