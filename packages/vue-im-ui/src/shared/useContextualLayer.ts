// 上下文层:占着一个可以退出的状态、却不是模态的那种面 —— 今天只有消息多选的工具条。
//
// 它是 useModalSurface 的非模态对应物:一个模块级的栈、一套「谁收 Escape / 谁收平台返回」
// 的规则,组件只声明「我挂着的时候这层就活着」。从前这套规则写在 web app 里(window 监听 +
// isSelectionExitKey + useFlareNativeBack 三件套),tauri 一件都没有 —— 同一个工具条在两个
// 宿主里一个能按 Escape 退出、一个不能,这就是「胶水其实是 kit 缺口」。
//
// 契约(消费 Escape 的层必须 preventDefault):本层挂在 **window 的冒泡阶段**,晚于所有
// document 与元素级处理器,所以不论注册先后,`defaultPrevented` 都可信 —— 动作菜单、composer
// 的面板/编辑/回复、Select/DatePicker 的桌面弹层关掉自己时都 preventDefault,本层就不会跟着退。
// 挂 document 不行:useModalSurface 也挂 document,晚开的模态排在本层之后跑,本层先看到的永远是
// false,那就是 useModalSurface 头注释里「一次 Escape 关两层」的坑;模态栈另外用共享事实兜底。
//
// 宿主须用 v-if 挂载这层的组件:v-show 藏起来的层仍在栈里,Escape 由可见性守卫挡住,但平台
// 返回在 web 适配器里只问最后一个认领者,藏起来的层只能放行(返回 false),没法把返回交给下一层。
import { onScopeDispose, toValue, watch, type MaybeRefOrGetter, type Ref } from "vue";
import { useFlarePlatformSafe } from "./platform/useFlarePlatform";
import { claimNativeBack } from "./platform/useFlareNativeBack";
import { hasFlareModalSurface } from "./useModalSurface";
import { resolveContextualLayerEscape } from "./contracts/contextual-layer";

interface ContextualLayer {
  id: symbol;
  root: Ref<HTMLElement | null>;
  dismissible: () => boolean;
  onDismiss: () => void;
}

/** 所有上下文层共用的一个栈,后活的在上面。 */
const layers: ContextualLayer[] = [];

/**
 * 元素还画在屏上。`getClientRects()` 对任何祖先 display:none 的元素都返回空,而且在 Safari 16.2
 * (kit 的下限)上就有;`checkVisibility()` 要 Safari 17.4。没有根元素的层按可见算。
 */
function isVisible(el: HTMLElement | null): boolean {
  if (!el) return true;
  return el.isConnected && el.getClientRects().length > 0;
}

function topLayer(within?: Element | null): ContextualLayer | undefined {
  for (let index = layers.length - 1; index >= 0; index -= 1) {
    const layer = layers[index];
    if (!isVisible(layer.root.value)) continue;
    if (within && !(layer.root.value && within.contains(layer.root.value))) continue;
    return layer;
  }
  return undefined;
}

/** 任何**可见**的 aria-modal 对话框(naive-ui 的 NModal / NDrawer 都画这个属性;留在 DOM 里的隐藏对话框不算)。 */
export function hasForeignModal(doc: Document): boolean {
  return Array.from(doc.querySelectorAll<HTMLElement>('[aria-modal="true"]')).some((el) => el.getClientRects().length > 0);
}

const NON_TEXT_INPUT_TYPES = new Set(["button", "submit", "reset", "checkbox", "radio", "range", "color", "file", "image"]);
const EDITABLE_ROLES = new Set(["textbox", "searchbox", "combobox", "spinbutton"]);

/** 焦点在一个会自己用 Escape 的可编辑控件里(输入框的 Escape 归输入框:取消候选、清空搜索、composer 的 blur)。 */
export function isEditableTarget(target: EventTarget | null): boolean {
  if (!(target instanceof Element)) return false;
  const el = target as HTMLElement;
  if (el.isContentEditable) return true;
  if (el.tagName === "TEXTAREA" || el.tagName === "SELECT") return true;
  if (el.tagName === "INPUT") return !NON_TEXT_INPUT_TYPES.has(((el as HTMLInputElement).type || "text").toLowerCase());
  const role = el.getAttribute("role");
  return role !== null && EDITABLE_ROLES.has(role);
}

/** 一个「页面」或「面」的边界:焦点所在的这一层如果不包含本层的根,本层就在它下面。 */
const SURFACE_SELECTOR = '.flare-screen, [role="dialog"], .flare-app-layout__overlay, .flare-app-layout__detail-overlay';

export function isForeignSurface(target: EventTarget | null, root: HTMLElement | null): boolean {
  if (!(target instanceof Element) || !root) return false;
  const surface = target.closest(SURFACE_SELECTOR);
  return Boolean(surface && !surface.contains(root));
}

export interface FlareContextualLayerOptions {
  /** 这层活着没有。挂在宿主是否监听退出事件上(没人听的层既不吞键也不认领返回)。 */
  active: MaybeRefOrGetter<boolean>;
  /** 这层的根元素:可见性、页面归属、焦点归还都看它。 */
  root: Ref<HTMLElement | null>;
  /** 为 false 时 Escape 与平台返回被吃掉而不是退出(批量进行中)。缺省 true。 */
  dismissible?: MaybeRefOrGetter<boolean>;
  /** 要求退出这层时调用。 */
  onDismiss: () => void;
}

/**
 * 把一个组件登记成上下文层:Escape、平台返回、kit 返回控件的第一下都由这里按同一条规则处理。
 */
export function useFlareContextualLayer(options: FlareContextualLayerOptions): void {
  const platform = useFlarePlatformSafe();
  const layer: ContextualLayer = {
    id: Symbol("flare-contextual-layer"),
    root: options.root,
    dismissible: () => toValue(options.dismissible ?? true),
    onDismiss: options.onDismiss,
  };
  let opener: HTMLElement | null = null;
  let listening = false;
  let releaseBack: (() => void) | undefined;

  function onKeydown(event: KeyboardEvent): void {
    const target = (event.composedPath?.()[0] ?? event.target) as EventTarget | null;
    const intent = resolveContextualLayerEscape({
      key: event.key,
      composing: event.isComposing || event.keyCode === 229,
      defaultPrevented: event.defaultPrevented,
      modalOpen: hasFlareModalSurface() || hasForeignModal(document),
      editableTarget: isEditableTarget(target),
      foreignSurface: isForeignSurface(target, options.root.value),
      topmost: topLayer() === layer,
      visible: isVisible(options.root.value),
      busy: !layer.dismissible(),
    });
    if (intent === "ignore") return;
    event.preventDefault();
    if (intent === "exit") options.onDismiss();
  }

  function activate(): void {
    if (typeof document === "undefined" || layers.includes(layer)) return;
    layers.push(layer);
    const active = document.activeElement as HTMLElement | null;
    opener = active && active !== document.body && !options.root.value?.contains(active) ? active : null;
    window.addEventListener("keydown", onKeydown);
    listening = true;
    // 平台返回:与模态面同一条认领;busy 时吃掉(返回键此时也是禁用的),藏起来时放行。
    releaseBack = claimNativeBack(platform, () => {
      if (!isVisible(options.root.value)) return false;
      if (layer.dismissible()) options.onDismiss();
      return true;
    });
  }

  function deactivate(): void {
    if (typeof document === "undefined") return;
    if (listening) {
      window.removeEventListener("keydown", onKeydown);
      listening = false;
    }
    releaseBack?.();
    releaseBack = undefined;
    const index = layers.indexOf(layer);
    if (index !== -1) layers.splice(index, 1);
    // 退出键随这层一起卸载时焦点不该掉到 body 上:还给打开这层之前拿着焦点的那个控件。
    const activeEl = document.activeElement;
    if ((activeEl === document.body || Boolean(options.root.value?.contains(activeEl))) && opener?.isConnected) opener.focus();
    opener = null;
  }

  watch(
    () => Boolean(toValue(options.active)),
    (on) => {
      if (on) activate();
      else deactivate();
    },
    { immediate: true },
  );
  onScopeDispose(deactivate);
}

/**
 * kit 的可见返回控件(会话页头、FlareScreen、响应式布局的返回)按下时先问这里:`within` 之内最上面
 * 那层可见的上下文层要是存在,就关它并返回 true —— busy 的层也算「消费」了这一下(与平台返回一致,
 * 头部不能在批量进行中把人带出会话);没有这样的层返回 false,控件再做自己的返回。
 *
 * `within` 是必要的:栈是全文档一份,返回控件却属于某一页/某一栏 —— 详情栏里那一页的返回不该去关
 * 隔壁聊天栏的多选。
 */
export function dismissTopFlareContextualLayer(within?: Element | null): boolean {
  const top = topLayer(within);
  if (!top) return false;
  if (top.dismissible()) top.onDismiss();
  return true;
}
