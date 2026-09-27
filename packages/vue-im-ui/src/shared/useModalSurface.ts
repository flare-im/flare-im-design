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

/**
 * 模态面页头控件(关闭、返回、页头 actions 的容器)上的标记:打开时的初始焦点跳过它们,
 * 先落到内容里第一个可聚焦元素上。FlareModal / FlareDrawer 的页头都带着它。
 */
export const FLARE_OVERLAY_CHROME = "data-flare-overlay-chrome";

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

  // 打开时焦点先给内容,再给页头那几颗键,最后才是面本身。页头的关闭键画在最前面,
  // 按「第一个可聚焦」走的话,表单打开时焦点落在 × 上而不是第一个字段 —— 所以页头
  // 控件带 `data-flare-overlay-chrome`,这里跳过它们。
  function initialFocusTarget(): HTMLElement | null {
    const items = focusables();
    const content = items.find((el) => !el.closest(`[${FLARE_OVERLAY_CHROME}]`));
    return content ?? items[0] ?? options.surface.value;
  }

  // 焦点还给打开它的那个元素 —— 只在它还在文档里时;不滚动,免得关掉面板页面跳一下。
  function restoreFocus(): void {
    const target = opener;
    opener = null;
    if (target && target.isConnected && typeof target.focus === "function") target.focus({ preventScroll: true });
  }

  function onKeydown(event: KeyboardEvent): void {
    if (!isTopmost()) return;
    if (event.key === "Escape") {
      // 面里的控件(Select / 日期 / 时间的弹层)已经用掉这下 Escape 了:只收它自己的弹层,
      // 面不能再跟着返回或关闭。它们在捕获阶段处理并 preventDefault。
      if (event.defaultPrevented) return;
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
      // 焦点不在面里(抽屉里换了一页、按着的那颗键被拿掉了,activeElement 退回 body)时,
      // 两个方向都要拉回来 —— 否则浏览器把 Tab 交给遮罩后面的第一个可聚焦元素。
      const outside = !options.surface.value.contains(active);
      if (event.shiftKey && (active === first || outside)) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && (active === last || outside)) {
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
          void nextTick(() => initialFocusTarget()?.focus());
        }
      } else {
        document.removeEventListener("keydown", onKeydown);
        const held = holdsLock;
        unlockScroll();
        if (held) restoreFocus();
        else opener = null;
      }
    },
    { immediate: true },
  );

  onBeforeUnmount(() => {
    releaseBack?.();
    if (typeof document === "undefined") return;
    document.removeEventListener("keydown", onKeydown);
    // 宿主直接用 v-if 拿掉一张还开着的面(没经过 open → false)时,焦点也得还回去,
    // 不然它留在一个已经不在文档里的元素上,键盘用户从 body 重新开始。只有真的开着
    // (持有锁)的那张才还 —— 关着的面从没拿走过焦点。
    const held = holdsLock;
    unlockScroll();
    if (held) restoreFocus();
    else opener = null;
  });

  return { overlayContainer, isTopmost };
}
