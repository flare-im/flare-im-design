import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";

/**
 * 生产 web 页面上只输 user id 点登录，此前报的是 "set VITE_FLARE_TOKEN_SECRET in .env.local"：
 * 面向开发者的话，生产用户没有 Vite 项目可改。现在必须
 * ① 报面向用户的提示（i18n），② 让登录页识别这个错误并自动展开高级区，把密钥/token 输入框露出来。
 */
const read = (rel: string) => readFileSync(fileURLToPath(new URL(rel, import.meta.url)), "utf8");

describe("缺签名密钥时的登录体验", () => {
  it("错误是可识别的类型，且文案走 i18n 而不是提 .env.local", () => {
    const ts = read("../composables/useFlareCoreClient.ts");
    expect(ts).toContain("export class MissingTokenSecretError extends Error");
    expect(ts).toContain('throw new MissingTokenSecretError(translateFlare("login.missingTokenSecret"))');
    expect(ts).not.toMatch(/throw new Error\([^)]*\.env\.local/);
  });

  it("组合式暴露 tokenSecretMissing，并在缺密钥时置真", () => {
    const ts = read("../composables/useFlareCoreClient.ts");
    expect(ts).toContain("const tokenSecretMissing = ref(false);");
    expect(ts).toContain("tokenSecretMissing.value = error instanceof MissingTokenSecretError;");
    expect(ts).toMatch(/\n\s+tokenSecretMissing,\n/);
  });

  it("i18n 两种语言都有面向用户的提示", () => {
    const m = read("../shared/i18n/messages.ts");
    expect(m).toContain("missingTokenSecret: \"未配置签名密钥");
    expect(m).toContain("missingTokenSecret: \"No signing secret configured");
  });

  it("登录组件收到 advancedOpen 就展开高级区", () => {
    const vue = read("../components/shell/FlareAuthScreen.vue");
    expect(vue).toContain("advancedOpen?: boolean;");
    expect(vue).toContain("() => props.advancedOpen");
    expect(vue).toContain("if (open) serverOpen.value = true;");
  });

  it("包装页把 tokenSecretMissing 传给 advanced-open", () => {
    expect(read("../app/components/FlareLoginScreen.vue")).toContain(`:advanced-open="sdk.tokenSecretMissing.value"`);
  });
});
