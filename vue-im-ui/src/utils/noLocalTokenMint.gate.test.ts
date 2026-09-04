import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";

/**
 * 客户端不再本地签发接入 token（那等于把签名密钥放进浏览器）。
 * 两条路：SDK 托管——login 不传 token，把网关地址交给核心（sdkConfig.auth.tokenEndpoint）；
 * 应用托管——高级区粘贴 token 原样传。kit 里不能再出现签名密钥或本地签发。
 */
const read = (rel: string) => readFileSync(fileURLToPath(new URL(rel, import.meta.url)), "utf8");

describe("kit 不本地签发 token", () => {
  it("组合式没有签名密钥、没有 generateCoreToken", () => {
    const ts = read("../composables/useFlareCoreClient.ts");
    expect(ts).not.toMatch(/generateCoreToken|VITE_FLARE_TOKEN_SECRET|tokenSecret|MissingTokenSecretError/);
  });

  it("没有 token 时把网关地址交给核心（SDK 托管），有 token 时原样传（应用托管）", () => {
    const ts = read("../composables/useFlareCoreClient.ts");
    expect(ts).toContain("...(token ? {} : { auth: sdkManagedAuth(request.httpUrl) })");
    expect(ts).toContain("client.login(token ? { userId: request.userId, token } : { userId: request.userId })");
    expect(ts).toContain("export function sdkManagedAuth(httpUrl: string)");
  });

  it("登录组件没有签名密钥输入，也没有「生成测试 Token」按钮", () => {
    const vue = read("../components/shell/FlareAuthScreen.vue");
    expect(vue).not.toMatch(/tokenSecret|generate-token/);
    const m = read("../shared/i18n/messages.ts");
    expect(m).not.toMatch(/tokenSecretLabel|missingTokenSecret|generateToken:/);
  });
});
