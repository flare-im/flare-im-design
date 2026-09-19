import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";

const composerSource = readFileSync(
  fileURLToPath(new URL("./EnhancedComposer.vue", import.meta.url)),
  "utf8",
);

/**
 * 提及的两条约束，钉的是**源码形态**而非运行时：
 * 真正的失败要在群会话里点开提及菜单、选人、发出去、再到另一端看正文才暴露，
 * 单测里复现代价过高；而形态判据是确定的。
 */
describe("提及插入", () => {
  it("正文里放显示名，不放内部 user id", () => {
    const body = composerSource.slice(
      composerSource.indexOf("function selectMention("),
      composerSource.indexOf("function selectMentionEveryone("),
    );
    expect(body).toContain("candidate.label");
    expect(
      /insertAtCursor\(`@\$\{userId\}/.test(body),
      "插入原始 user id 会让用户在自己的消息里看到 `@webtest2` 这种内部标识",
    ).toBe(false);
  });

  it("提及菜单有 @全员 入口", () => {
    // 曾经把常驻 @全员 复选框删掉，理由是"直接打 @全员 就能触发"——那个前提当时不成立。
    // 现在核心认得 all/everyone/全员/所有人，但菜单入口仍必须在，否则用户无从发现。
    expect(composerSource).toContain("selectMentionEveryone");
    expect(composerSource).toContain('t("mention.everyone")');
  });

  it("插入的 @全员 记号必须是核心认得的那几个之一", () => {
    // 核心 content::mention 的记号表：all / everyone / 全员 / 所有人。
    // i18n 里 mention.everyone 的两个取值必须落在这张表里，否则点了没效果。
    const messages = readFileSync(
      fileURLToPath(new URL("../../shared/i18n/messages.ts", import.meta.url)),
      "utf8",
    );
    const known = ["all", "everyone", "全员", "所有人"];
    const values = [...messages.matchAll(/everyone:\s*"([^"]+)"/g)].map((m) => m[1]);
    expect(values.length).toBeGreaterThan(0);
    for (const value of values) {
      expect(
        known.some((token) => token.toLowerCase() === value.toLowerCase()),
        `mention.everyone = "${value}" 不在核心的 @全员 记号表里，点了不会生效`,
      ).toBe(true);
    }
  });
});
