import type { FlareWasmRuntime } from "@flare-im/sdk/web";

type CoreWasmModule = {
  default?: (options?: { module_or_path?: string | URL | Request }) => Promise<unknown> | unknown;
  createWasmRuntime: () => FlareWasmRuntime;
};

export type WasmLoaderResult = {
  runtime: FlareWasmRuntime & {
    setEventCallback?: (callback: ((event: unknown) => void) | null) => void;
  };
  source: string;
  status: "active" | "planned" | "unavailable";
};

const WASM_BINDING_PUBLIC_BASE = "flare-core-wasm";
const WASM_BINDING_SOURCE = "flare-im-core-sdk/bindings/wasm/pkg";

/**
 * WASM 产物的构建版本（由 @flare-im/sdk 的 vite 插件按 pkg 内容哈希注入）。
 *
 * 两个文件都不带内容哈希名，生产 nginx 又给 *.wasm 打了一年 immutable：
 * 发新 WASM 后浏览器继续用旧 .wasm 配新胶水 JS，表现为
 * "wasm.__wasm_bindgen_func_elem_NNNN is not a function"（生产实测）。
 * 把版本挂进查询串，缓存键随内容变，旧缓存自然失效。
 */
const WASM_BUILD_ID: string = String(import.meta.env.VITE_FLARE_WASM_BUILD_ID ?? "").trim();

export function resolveWasmBindingAssetUrl(fileName: string): string {
  const baseUrl = import.meta.env.BASE_URL.endsWith("/")
    ? import.meta.env.BASE_URL
    : `${import.meta.env.BASE_URL}/`;
  const url = `${baseUrl}${WASM_BINDING_PUBLIC_BASE}/${fileName}`;
  return WASM_BUILD_ID ? `${url}?v=${encodeURIComponent(WASM_BUILD_ID)}` : url;
}

function createWasmLoadError(error: unknown, moduleUrl: string, wasmUrl: string): Error {
  const message = error instanceof Error ? error.message : String(error);
  return Object.assign(new Error(`WASM runtime unavailable: ${message}`), {
    code: "runtimeUnavailable",
    operation: "wasm.load",
    retryable: true,
    details: {
      source: WASM_BINDING_SOURCE,
      moduleUrl,
      wasmUrl,
    },
  });
}

/**
 * Web example wasm loader — injected at infrastructure boundary, not in chat UI.
 * Falls back to typed unavailable when pkg is missing.
 */
export async function loadFlareWasmRuntime(): Promise<WasmLoaderResult> {
  const source = WASM_BINDING_SOURCE;
  const moduleUrl = resolveWasmBindingAssetUrl("flare_im_core_sdk.js");
  const wasmUrl = resolveWasmBindingAssetUrl("flare_im_core_sdk_bg.wasm");
  try {
    const mod = await import(/* @vite-ignore */ moduleUrl) as CoreWasmModule;
    await mod.default?.({ module_or_path: wasmUrl });
    if (typeof mod.createWasmRuntime !== "function") {
      throw new Error("flare_im_core_sdk.js does not export createWasmRuntime()");
    }
    return {
      runtime: mod.createWasmRuntime(),
      source,
      status: "active",
    };
  } catch (error) {
    throw createWasmLoadError(error, moduleUrl, wasmUrl);
  }
}
