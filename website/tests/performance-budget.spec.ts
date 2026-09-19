import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { expect, test } from "@playwright/test";
import contract from "../../spec/performance-contract.json" with { type: "json" };

// DoD 27 — the budgets, measured. The old gate grepped the source for the word
// "virtualItems" and called that proof; this mounts 1000 conversations and 5000
// messages and counts what the kit actually put in the DOM.
const budgets = contract.measuredBudgets;
const reportDir = join(dirname(fileURLToPath(import.meta.url)), "..", "test-results");

test("@perf the list budgets hold at 1000 conversations and 5000 messages", async ({ page }) => {
  test.setTimeout(5 * 60 * 1000);
  await page.setViewportSize({ width: 1440, height: 900 });
  const failures: string[] = [];
  page.on("pageerror", (error) => failures.push(error.message));

  await page.goto(
    `/resources/performance-regression?conversations=${budgets.conversationList.items}&messages=${budgets.messageList.items}`,
    { waitUntil: "domcontentloaded" },
  );
  await page.locator('[data-perf-ready="true"]').waitFor({ timeout: 120000 });

  const measured = await page.evaluate(() => {
    const conversations = document.querySelector('[data-perf-case="conversations"]')!;
    const messages = document.querySelector('[data-perf-case="messages"]')!;
    const messageRows = messages.querySelectorAll(".message-row").length;
    return {
      mountMs: (window as unknown as { __flarePerf: { mountMs: number } }).__flarePerf.mountMs,
      conversationRows: conversations.querySelectorAll(".im-conv-item").length,
      conversationNodes: conversations.querySelectorAll("*").length,
      messageRows,
      messageNodes: messages.querySelectorAll("*").length,
      nodesPerMessageRow: messageRows ? messages.querySelectorAll("*").length / messageRows : 0,
      // A scroll container that grew to its content cannot scroll, and the
      // virtual window then covers the whole list.
      conversationScrollerBounded: (() => {
        const node = conversations.querySelector<HTMLElement>(".im-conv-list");
        return node ? node.clientHeight < node.scrollHeight : false;
      })(),
    };
  });

  mkdirSync(reportDir, { recursive: true });
  writeFileSync(join(reportDir, "performance.json"), `${JSON.stringify({ budgets, measured }, null, 2)}\n`);

  expect(failures, "the fixture must mount without a page error").toEqual([]);

  // The conversation list windows: a screenful, not the backing collection.
  expect(measured.conversationScrollerBounded, "the conversation list must bound its own height").toBe(true);
  expect(measured.conversationRows).toBeGreaterThan(0);
  expect(measured.conversationRows).toBeLessThanOrEqual(budgets.conversationList.maxRenderedRows);

  // The message list does not window on purpose; the budget is the per-row cost,
  // and the bound on the timeline belongs to the host's paging window.
  expect(measured.messageRows).toBe(budgets.messageList.items);
  expect(measured.nodesPerMessageRow).toBeLessThanOrEqual(budgets.messageList.maxNodesPerRow);

  expect(measured.mountMs).toBeLessThanOrEqual(budgets.mount.maxMs);
});

test("@perf a host-sized timeline stays well inside the DOM budget", async ({ page }) => {
  test.setTimeout(3 * 60 * 1000);
  await page.setViewportSize({ width: 1440, height: 900 });
  // What a paging host actually holds. The 5000-message case above is the
  // stress load; this is the one users meet.
  const loaded = budgets.messageList.hostMaxLoadedMessages;
  await page.goto(`/resources/performance-regression?conversations=200&messages=${loaded}`, { waitUntil: "domcontentloaded" });
  await page.locator('[data-perf-ready="true"]').waitFor({ timeout: 60000 });

  const nodes = await page.evaluate(() => document.querySelectorAll('[data-perf-case="messages"] *').length);
  // 400 rows at the per-row budget, with room for the day separators.
  expect(nodes).toBeLessThanOrEqual(loaded * budgets.messageList.maxNodesPerRow);
});
