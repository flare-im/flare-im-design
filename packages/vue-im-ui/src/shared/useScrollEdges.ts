// 一条横向滚动条「两头还有没有内容藏着」的事实。
//
// 纯 CSS 画不出诚实的滚动提示:一条固定的渐隐在什么都没藏住时也会把最后一个键蒙掉一角,
// 而 `animation-timeline: scroll()` 在 Tauri 的 WKWebView 里没有。所以由 JS 读三个几何量,
// 组件只按 `data-scroll-end` 之类的属性去画。1px 容差吃掉亚像素;`Math.abs` 是因为 RTL
// 下 scrollLeft 为负 —— kit 今天不支持 RTL,但这一笔不花钱。
import { onScopeDispose, onUpdated, ref, toValue, watch, type MaybeRefOrGetter, type Ref } from "vue";

export interface FlareScrollEdges {
  /** 起始侧还有内容(已经滚过去了一些)。 */
  start: boolean;
  /** 末端还有内容(还能继续滚)。 */
  end: boolean;
}

export function scrollEdges(metrics: { scrollLeft: number; clientWidth: number; scrollWidth: number }): FlareScrollEdges {
  const left = Math.abs(metrics.scrollLeft);
  return { start: left > 1, end: left + metrics.clientWidth < metrics.scrollWidth - 1 };
}

/**
 * 跟着 `el` 的滚动与尺寸变化更新两头的事实;`enabled` 为假时两个值都回到 false 并拆掉监听
 * (非滚动形态下什么都不该画)。
 *
 * 监听挂在 `[el, enabled]` 上而不是只在 enabled 上:一挂载就是滚动形态的工具条,setup 期间
 * `el` 还是 null,只看 enabled 的 immediate 那一次会永远挂不上监听。
 */
export function useFlareScrollEdges(el: Ref<HTMLElement | null>, enabled: MaybeRefOrGetter<boolean>): { start: Ref<boolean>; end: Ref<boolean> } {
  const start = ref(false);
  const end = ref(false);
  let node: HTMLElement | null = null;
  let observer: ResizeObserver | undefined;

  function measure(): void {
    if (!node) return;
    const edges = scrollEdges(node);
    start.value = edges.start;
    end.value = edges.end;
  }

  function detach(): void {
    if (node) {
      node.removeEventListener("scroll", measure);
      observer?.disconnect();
    }
    observer = undefined;
    node = null;
    start.value = false;
    end.value = false;
  }

  watch(
    [el, () => toValue(enabled)],
    ([next, on]) => {
      detach();
      if (!on || !next || typeof window === "undefined") return;
      node = next;
      node.addEventListener("scroll", measure, { passive: true });
      if (typeof ResizeObserver !== "undefined") {
        observer = new ResizeObserver(measure);
        observer.observe(node);
      }
      measure();
    },
    { immediate: true, flush: "post" },
  );
  // 能力或 busy 变了会改内容宽度,ResizeObserver 只看盒子自己,所以每次更新后再量一次。
  onUpdated(measure);
  onScopeDispose(detach);

  return { start, end };
}
