import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";

/**
 * 生产 nginx 给 *.wasm 打了一年 immutable，而 flare_im_core_sdk_bg.wasm 不带内容哈希名：
 * 发新 WASM 后浏览器继续用旧 .wasm 配新胶水，报 "wasm.__wasm_bindgen_func_elem_NNNN is not a function"。
 * 加载 URL 必须带构建版本查询串，且版本由 vite 插件按产物内容注入。
 */
const read = (rel: string) => readFileSync(fileURLToPath(new URL(rel, import.meta.url)), "utf8");

describe("WASM 产物缓存穿透", () => {
  it("加载端把 VITE_FLARE_WASM_BUILD_ID 挂进 ?v=", () => {
    const loader = read("../app/infrastructure/sdk/wasmLoader.ts");
    expect(loader).toContain("import.meta.env.VITE_FLARE_WASM_BUILD_ID");
    expect(loader).toMatch(/\?v=\$\{encodeURIComponent\(WASM_BUILD_ID\)\}/);
  });

  it("vite 插件按 pkg 内容注入构建 id", () => {
    const plugin = read(
      "../../../../flare-im-core-client-sdk/packages/flare-core-typescript-sdk/devtools/vite/flareCoreWebAppVite.js",
    );
    expect(plugin).toContain('"import.meta.env.VITE_FLARE_WASM_BUILD_ID": JSON.stringify(wasmBindingBuildId(wasmBindingRoot))');
    expect(plugin).toContain('hash.update(fs.readFileSync(filePath));');
  });
});
