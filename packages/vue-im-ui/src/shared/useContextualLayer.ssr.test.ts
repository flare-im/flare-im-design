// @vitest-environment node
import { describe, expect, it } from "vitest";
import { createSSRApp, defineComponent, h, ref } from "vue";
import { renderToString } from "vue/server-renderer";
import { useFlareContextualLayer } from "./useContextualLayer";

/**
 * 这层用 `watch(…, { immediate: true })` 登记自己,immediate 那一次在 setup 里同步跑 ——
 * check-ssr-safety 把 watch 算作「延后」,所以门禁看不见这里对 window / document 的访问。
 * 服务端渲染一张带工具条的页面不能因此抛 `window is not defined`。
 */
describe("useFlareContextualLayer under server rendering", () => {
  it("renders without touching window or document", async () => {
    const Layer = defineComponent({
      setup() {
        const root = ref<HTMLElement | null>(null);
        useFlareContextualLayer({ active: true, root, onDismiss: () => undefined });
        return () => h("div", { ref: root }, "layer");
      },
    });
    const html = await renderToString(createSSRApp(Layer));
    expect(html).toContain("layer");
  });
});
