/**
 * What an app shell tells the user about its IM connection. The kit owns the wording, the tone
 * and the way back, so every app says the same thing for the same state:
 * - connecting and reconnecting say so (the core retries on its own);
 * - offline waits for the network;
 * - disconnected may offer 重新连接 when the host can reconnect;
 * - kicked and expired are final (the core does not reconnect), so they always offer 重新登录.
 * Connected shows nothing.
 */
export type FlareConnectionPhase = "connected" | "connecting" | "reconnecting" | "offline" | "disconnected" | "kicked" | "expired";

export type FlareConnectionRecovery = "reconnect" | "signIn";

export interface FlareConnectionNotice {
  phase: Exclude<FlareConnectionPhase, "connected">;
  text: string;
  tone: "warning" | "danger";
  /** A connection attempt is under way. */
  pulse: boolean;
  recovery?: FlareConnectionRecovery;
  recoveryText?: string;
}

type Translate = (key: string, params?: Record<string, string | number>) => string;

export function connectionNotice(
  phase: FlareConnectionPhase,
  t: Translate,
  options: { reason?: string; canReconnect?: boolean } = {},
): FlareConnectionNotice | null {
  const reason = options.reason?.trim() ?? "";
  switch (phase) {
    case "connected":
      return null;
    case "connecting":
      return { phase, text: t("connection.connecting"), tone: "warning", pulse: true };
    case "reconnecting":
      return { phase, text: t("connection.reconnecting"), tone: "warning", pulse: true };
    case "offline":
      return { phase, text: t("connection.offline"), tone: "warning", pulse: false };
    case "disconnected":
      return {
        phase,
        text: reason ? t("connection.disconnectedReason", { reason }) : t("connection.disconnected"),
        tone: "warning",
        pulse: false,
        ...(options.canReconnect ? { recovery: "reconnect" as const, recoveryText: t("connection.reconnect") } : {}),
      };
    case "kicked":
      return { phase, text: reason || t("connection.kicked"), tone: "danger", pulse: false, recovery: "signIn", recoveryText: t("connection.signIn") };
    case "expired":
      return { phase, text: t("connection.expired"), tone: "danger", pulse: false, recovery: "signIn", recoveryText: t("connection.signIn") };
  }
}
