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

export function resolveWasmBindingAssetUrl(fileName: string): string {
  const baseUrl = import.meta.env.BASE_URL.endsWith("/")
    ? import.meta.env.BASE_URL
    : `${import.meta.env.BASE_URL}/`;
  return `${baseUrl}${WASM_BINDING_PUBLIC_BASE}/${fileName}`;
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
