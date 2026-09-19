import { describe, expect, it } from "vitest";
import { resolveFlareMessage } from "../shared/i18n/messages";
import { connectionNotice } from "./connectionNotice";

const zh = (key: string, params?: Record<string, string | number>) => resolveFlareMessage("zh-CN", key, params);

describe("connectionNotice", () => {
  it("shows nothing when connected and says what is happening otherwise", () => {
    expect(connectionNotice("connected", zh)).toBeNull();
    expect(connectionNotice("reconnecting", zh)).toMatchObject({ text: "连接已断开，正在重连…", tone: "warning", pulse: true });
    expect(connectionNotice("offline", zh)).toMatchObject({ tone: "warning", pulse: false });
    expect(connectionNotice("offline", zh)?.recovery).toBeUndefined();
  });

  it("offers reconnect only when the host can, and names the reason", () => {
    expect(connectionNotice("disconnected", zh)?.recovery).toBeUndefined();
    expect(connectionNotice("disconnected", zh, { reason: "网络超时", canReconnect: true })).toMatchObject({
      text: "连接已断开：网络超时", recovery: "reconnect", recoveryText: "重新连接",
    });
  });

  it("always offers sign in again for the final states", () => {
    expect(connectionNotice("kicked", zh)).toMatchObject({ text: "账号已在其他设备登录", tone: "danger", recovery: "signIn", recoveryText: "重新登录" });
    expect(connectionNotice("kicked", zh, { reason: "在 iPad 上登录" })?.text).toBe("在 iPad 上登录");
    expect(connectionNotice("expired", zh)).toMatchObject({ text: "登录已过期", recovery: "signIn" });
  });
});
