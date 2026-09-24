// 模态面的唯一实现 —— 一个栈、一把滚动锁、一套焦点与键盘规则。
//
// 从前每张「模态」各写一遍,而且写得不一样:底部面板有引用计数的滚动锁和 Tab 陷阱,
// 图片/视频预览直接 `document.body.style.overflow = ''`,命令面板两样都没有。三份
// 实现互相踩:
//   - 面板开着,从里面点开图片预览,再关掉预览 —— 预览把 overflow 清空,于是面板
//     还开着,背后的页面却又能滚了(引用计数被外人清零);
//   - 一次 Escape 同时关掉预览和它下面的面板 —— 两边各自监听 document,又各自以为
//     自己在最上面(面板的栈里根本没有预览);
//   - 命令面板写死 `Teleport to="body"`,宿主把浮层限定到某个容器时它逃出去。
// 所以栈、锁、键盘、返回键、传送目标都收在这里。每张模态只声明「我是一张模态」。
import {
  nextTick,
  onBeforeUnmount,
  toValue,
  watch,
  type MaybeRefOrGetter,
  type Ref,
} from "vue";
import { useFlareOverlayContainer, type FlareOverlayTarget } from "./useOverlayContainer";
import { useFlarePlatformSafe } from "./platform/useFlarePlatform";
import { claimNativeBack } from "./platform/useFlareNativeBack";

/** 所有模态面共用的一个栈,叠起来时最上面那张才收键盘。 */
const stack: symbol[] = [];
let lockCount = 0;
let priorOverflow = "";

const FOCUSABLE = 'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])';

export interface FlareModalSurfaceOptions {
  /** 这张面开着没有。 */
  open: MaybeRefOrGetter<boolean>;
  /** 面板根元素:焦点送进它,Tab 关在它里面。 */
  surface: Ref<HTMLElement | null>;
  /** Escape / 平台返回键要求关闭时调用。 */
  onRequestClose: () => void;
  /** 为 false 时 Escape 与返回键被吃掉而不是关闭(操作进行中)。缺省 true。 */
  dismissible?: MaybeRefOrGetter<boolean>;
  /** 打开时把焦点送进面板。缺省 true。 */
  autoFocus?: MaybeRefOrGetter<boolean>;
  /** 打开时接管平台返回键。缺省 true。 */
  nativeBack?: MaybeRefOrGetter<boolean>;
  /**
   * 这张面自己的快捷键(图片预览的方向键与缩放一类)。只在它是栈顶时才会被调用,
   * Escape 和 Tab 已经在这里处理掉,不会传下去。
   */
  onKeydown?: (event: KeyboardEvent) => void;
}

/**
 * 有没有模态面开着。给非模态的上下文层(useContextualLayer.ts)用:它和模态面都听 Escape,
 * 只靠 `defaultPrevented` 分不清先后 —— 同一目标上先注册的先跑,晚开的模态会排在它后面。
 * 栈是共享的事实,不依赖注册顺序。
 */
export function hasFlareModalSurface(): boolean {
  return stack.length > 0;
}

export interface FlareModalSurface {
  /** Teleport 目标:宿主提供的容器,缺省 "body"。 */
  overlayContainer: Ref<FlareOverlayTarget>;
  /** 这张面是不是栈顶(叠了好几层时只有它该响应)。 */
  isTopmost: () => boolean;
}

/**
 * 把一个元素登记成模态面:滚动锁、焦点、Tab 陷阱、Escape、平台返回键和传送目标
 * 都由这里统一提供。调用方只负责画自己的内容。
 */
export function useFlareModalSurface(options: FlareModalSurfaceOptions): FlareModalSurface {
  const platform = useFlarePlatformSafe();
  const overlayContainer = useFlareOverlayContainer();
  const id = Symbol("flare-modal-surface");

  let opener: HTMLElement | null = null;
  let holdsLock = false;
  let releaseBack: (() => void) | undefined;

  const isTopmost = (): boolean => stack.at(-1) === id;
  const dismissible = (): boolean => toValue(options.dismissible ?? true);

  // 引用计数的滚动锁:第一张面锁上时记下原值,最后一张面解锁时还回去。
  // 中间任何一张关掉都不该让背后的页面重新滚动起来。
  function lockScroll(): void {
    if (typeof document === "undefined" || holdsLock) return;
    if (lockCount === 0) {
      priorOverflow = document.body.style.overflow;
      document.body.style.overflow = "hidden";
    }
    stack.push(id);
    lockCount += 1;
    holdsLock = true;
  }

  function unlockScroll(): void {
    if (typeof document === "undefined" || !holdsLock) return;
    holdsLock = false;
    const index = stack.indexOf(id);
    if (index !== -1) stack.splice(index, 1);
    lockCount = Math.max(0, lockCount - 1);
    if (lockCount === 0) document.body.style.overflow = priorOverflow;
  }

  function focusables(): HTMLElement[] {
    if (!options.surface.value) return [];
    return Array.from(options.surface.value.querySelectorAll<HTMLElement>(FOCUSABLE))
      .filter((el) => !el.hasAttribute("disabled"));
  }

  function onKeydown(event: KeyboardEvent): void {
    if (!isTopmost()) return;
    if (event.key === "Escape") {
      event.preventDefault();
      if (dismissible()) options.onRequestClose();
      return;
    }
    if (event.key === "Tab" && options.surface.value) {
      const items = focusables();
      if (items.length === 0) {
        event.preventDefault();
        options.surface.value.focus();
        return;
      }
      const first = items[0];
      const last = items[items.length - 1];
      const active = document.activeElement as HTMLElement | null;
      if (event.shiftKey && (active === first || !options.surface.value.contains(active))) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && active === last) {
        event.preventDefault();
        first.focus();
      }
      return;
    }
    options.onKeydown?.(event);
  }

  watch(
    () => toValue(options.open),
    (isOpen) => {
      if (typeof document === "undefined") return;
      releaseBack?.();
      releaseBack = undefined;
      if (isOpen) {
        if (toValue(options.nativeBack ?? true)) {
          releaseBack = claimNativeBack(platform, () => {
            if (dismissible()) options.onRequestClose();
          });
        }
        opener = document.activeElement as HTMLElement | null;
        lockScroll();
        document.addEventListener("keydown", onKeydown);
        if (toValue(options.autoFocus ?? true)) {
          void nextTick(() => (focusables()[0] ?? options.surface.value)?.focus());
        }
      } else {
        document.removeEventListener("keydown", onKeydown);
        unlockScroll();
        opener?.focus?.();
        opener = null;
      }
    },
    { immediate: true },
  );

  onBeforeUnmount(() => {
    releaseBack?.();
    if (typeof document === "undefined") return;
    document.removeEventListener("keydown", onKeydown);
    unlockScroll();
  });

  return { overlayContainer, isTopmost };
}
