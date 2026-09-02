import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const source = readFileSync(
  fileURLToPath(new URL("./useFlareCoreClient.ts", import.meta.url)),
  "utf-8",
);

/**
 * 打开会话时的历史回填不能对每个会话都触发。
 *
 * 原判据是 `minSeq > 1`，对任何有历史的会话恒成立：2 万条消息的会话每次打开都会
 * 同步拉最多 8 页 × 200 = 1600 条，占满 WASM 的单槽 invoke 链。实测代价是
 * 开完会话的第一次发送 Enter→上屏 **1299ms**，而同一会话第二次发送只要 **61ms**。
 *
 * 判据必须包含「这一页都没装满」这一条 —— 那才是真的不够用。
 */
describe("打开会话时的历史回填", () => {
  const body = (() => {
    const start = source.indexOf("function shouldRepairInitialTimelineHistory");
    expect(start, "找不到 shouldRepairInitialTimelineHistory").toBeGreaterThan(-1);
    const rest = source.slice(start);
    return rest.slice(0, rest.indexOf("\n  }") + 4);
  })();

  it("必须有「未装满一页」这道闸，不能只看 minSeq", () => {
    expect(
      /count\s*>=\s*MESSAGE_PAGE_SIZE/.test(body),
      "缺少 count >= MESSAGE_PAGE_SIZE 的提前返回：回填会对每个会话都触发",
    ).toBe(true);
  });

  it("仍保留 minSeq > 1，避免对已到顶的会话做无谓回填", () => {
    expect(/minSeq\s*>\s*1/.test(body)).toBe(true);
  });

  it("回填页数与单页上限必须有界", () => {
    const num = (name: string) => {
      const m = new RegExp(`const ${name} = ([0-9_]+)`).exec(source);
      expect(m, `未找到 ${name}`).not.toBeNull();
      return Number(m![1].replace(/_/g, ""));
    };
    // 一次打开最多同步拉取 页数 × 单页 条。原来是 8 × 200 = 1600，
    // 把 WASM 的单槽 invoke 链占满，用户开完会话的第一次发送要等 1.3 秒。
    const pages = num("INITIAL_HISTORY_REPAIR_MAX_PAGES");
    const limit = num("INITIAL_HISTORY_REPAIR_SYNC_LIMIT");
    expect(pages).toBeLessThanOrEqual(2);
    // 单页上限同时是用户发送的**最坏等待**：桥接层已把后台批量读降级，
    // 但正在执行的那一次不会被打断。200 条约 500ms，100 条把上界砍半。
    expect(limit).toBeLessThanOrEqual(100);
    expect(pages * limit).toBeLessThanOrEqual(200);
  });
});
