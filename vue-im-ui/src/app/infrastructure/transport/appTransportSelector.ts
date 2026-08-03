import {
  transportProfileFor,
  type TransportProfile,
} from "@flare-im/sdk/transport";

export interface AppTransportSelectorOptions {
  enabled: boolean;
  tlsCaCertPath?: string;
  runtimeStatus?: "tauri-native" | "electron-native" | "uni-native";
}

let transportSelectorOptions: AppTransportSelectorOptions = { enabled: false };

export function configureAppTransportSelector(options: AppTransportSelectorOptions): void {
  transportSelectorOptions = {
    enabled: options.enabled,
    tlsCaCertPath: String(options.tlsCaCertPath ?? "").trim() || undefined,
    runtimeStatus: options.runtimeStatus,
  };
}

export function isAppTransportSelectorEnabled(): boolean {
  return transportSelectorOptions.enabled;
}

export function appTransportSelectorTlsCaCertPath(): string {
  return transportSelectorOptions.tlsCaCertPath ?? "";
}

export function appTransportSelectorRuntimeStatus(): NonNullable<AppTransportSelectorOptions["runtimeStatus"]> {
  return transportSelectorOptions.runtimeStatus ?? "tauri-native";
}

/**
 * The SDK-owned capability profile for the current runtime (transports/storage/native).
 * Capability authority — combine with `isAppTransportSelectorEnabled()` (runtime availability)
 * before offering QUIC in the UI.
 */
export function appTransportSelectorProfile(): TransportProfile {
  return transportProfileFor(appTransportSelectorRuntimeStatus());
}
