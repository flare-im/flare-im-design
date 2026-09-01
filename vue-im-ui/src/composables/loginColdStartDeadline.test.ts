import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const source = readFileSync(
  fileURLToPath(new URL("./useFlareCoreClient.ts", import.meta.url)),
  "utf-8",
);

const readTimeout = (name: string): number => {
  const m = new RegExp(`const ${name} = ([0-9_]+);`).exec(source);
  expect(m, `未找到常量 ${name}`).not.toBeNull();
  return Number(m![1].replace(/_/g, ""));
};

/**
 * 冷启动登录的死线量的是用户网速，不是处理耗时。
 *
 * 首个 invoke 会触发下载 1.55MB（gzip）的 wasm，这段时间记在 login.init 名下。
 * 实测 ~40KB/s 的链路上，光 wasm 就要 34s；8s 的旧值只够 200KB/s 以上的链路，
 * 慢一点就随机失败，且失败时客户端一个网络包都没发出去（连接建立在 wasm
 * 之后），表象是「服务端不可达」。
 */
describe("登录冷启动死线", () => {
  // ~200KB/s 链路上取 wasm 的耗时；低于它的死线会把慢网用户全挡在门外。
  const WASM_FETCH_ON_SLOW_LINK_MS = 9_130;

  it("login.init 死线必须显著宽于慢网取 wasm 的耗时", () => {
    const loginStep = readTimeout("CORE_LOGIN_STEP_TIMEOUT_MS");
    expect(loginStep).toBeGreaterThan(WASM_FETCH_ON_SLOW_LINK_MS * 1.5);
  });

  it("不得再引入 init 前的热身调用（会与 client.init 自锁）", () => {
    // 用 diagnostics 之类的操作去「预热」运行时，会一直等到 client.init() 返回，
    // 而 init 排在热身之后 —— 实测把总耗时从 9.1s 恶化到 33.5s。
    expect(source).not.toContain("warmUpCoreRuntime");
  });
});
