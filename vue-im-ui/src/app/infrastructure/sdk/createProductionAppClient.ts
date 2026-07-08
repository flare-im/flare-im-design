import { DefaultEventsApi } from "flare-core-typescript-sdk/adapter/module/DefaultEventsApi";
import type { FlareImClient } from "flare-core-typescript-sdk/api";
import {
  WebFlareImClient,
  WebProductionBridge,
  wrapWebHostBridge,
  type WasmStorageHostFactory,
} from "flare-core-typescript-sdk/web";
import { loadFlareWasmRuntime } from "./wasmLoader";

export type ProductionAppClientFactory = () => FlareImClient;

/**
 * Local persistence backend for the WASM web client:
 * - `indexeddb` (default): web / H5 builds.
 * - `sqlite`: packaged desktop (Electron) builds — wa-sqlite + OPFS.
 * The transport is WebSocket either way (WASM has no QUIC; see the transport-storage design doc).
 */
export type ProductionStorageBackend = "indexeddb" | "sqlite";

let browserBridge: WebProductionBridge | null = null;
let clientFactory: ProductionAppClientFactory | null = null;
let storageBackend: ProductionStorageBackend = "indexeddb";
let storageHostFactory: WasmStorageHostFactory | null = null;

function createUnavailableSqliteStorageHost(): never {
  throw new Error(
    "SQLite storage backend selected but no host factory was provided. " +
      "Pass a SQLite storage host to configureProductionStorageBackend('sqlite', host) — " +
      "the shared package intentionally does not bundle wa-sqlite; the desktop app owns it.",
  );
}

export function configureProductionAppClientFactory(factory: ProductionAppClientFactory | null): void {
  clientFactory = factory;
}

/**
 * Select the persistence backend before the first `createProductionAppClient`.
 * `sqlite` requires an explicit host factory (e.g. the desktop app's wa-sqlite/OPFS host);
 * the shared package does not import wa-sqlite so web/H5 bundles stay clean.
 */
export function configureProductionStorageBackend(
  backend: ProductionStorageBackend,
  hostFactory?: WasmStorageHostFactory,
): void {
  storageBackend = backend;
  storageHostFactory = hostFactory ?? null;
}

export function createProductionAppClient(): FlareImClient {
  if (clientFactory) {
    return clientFactory();
  }
  if (!browserBridge) {
    browserBridge = new WebProductionBridge({
      loadRuntime: loadFlareWasmRuntime,
      ...(storageBackend === "sqlite"
        ? { createStorageHost: storageHostFactory ?? createUnavailableSqliteStorageHost }
        : {}),
    });
  }
  const client = new WebFlareImClient(wrapWebHostBridge(browserBridge));
  browserBridge.attachEventEmitter(client.events as DefaultEventsApi);
  return client;
}
