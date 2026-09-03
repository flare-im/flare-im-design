import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";

/**
 * 签名密钥必须是**运行时输入**：此前 kit 只认构建期 VITE_FLARE_TOKEN_SECRET，
 * 换服务器得改 .env.local 重新构建；而把密钥打进产物等于让任何拿到它的人伪造任意用户身份。
 * 登录页输入 + 本机持久化后，只输入 user id 就能登录（web / uni / tauri 三端同时受益）。
 */
const read = (rel: string) => readFileSync(fileURLToPath(new URL(rel, import.meta.url)), "utf8");

describe("运行时签名密钥", () => {
  it("登录组件露出密钥输入并向上抛出", () => {
    const vue = read("../components/shell/FlareAuthScreen.vue");
    expect(vue).toContain(`:value="tokenSecret"`);
    expect(vue).toContain(`emit('update:tokenSecret', $event)`);
  });

  it("签发时运行时密钥优先于构建期 env", () => {
    const ts = read("../composables/useFlareCoreClient.ts");
    expect(ts).toContain("runtimeSecret.trim() || env.VITE_FLARE_TOKEN_SECRET?.trim()");
    expect(ts).toContain("devCoreTokenRequest(env, identity.userId, identity.tenantId, form.tokenSecret)");
  });

  it("密钥进表单默认值并随会话档案持久化/恢复", () => {
    const ts = read("../composables/useFlareCoreClient.ts");
    expect(ts).toContain(`tokenSecret: readLoginEnvText(env.VITE_FLARE_TOKEN_SECRET, "")`);
    expect(ts).toContain("tokenSecret: form.tokenSecret,");
    expect(ts).toContain("if (profile.tokenSecret) form.tokenSecret = profile.tokenSecret;");
  });

  it("包装页把密钥绑到 sdk.form", () => {
    expect(read("../app/components/FlareLoginScreen.vue")).toContain(`v-model:token-secret="sdk.form.tokenSecret"`);
  });
});
