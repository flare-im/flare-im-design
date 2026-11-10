import {expect, test} from "@playwright/test";
import {readFileSync} from "node:fs";
const vectors = JSON.parse(readFileSync(new URL("../../spec/wallet-record-vectors.json", import.meta.url), "utf8"));

for (const width of [320, 390, 1360]) for (const theme of ["light", "dark"] as const) {
  test(`wallet records stay readable at ${width}px ${theme}`, async ({page}, info) => {
    await page.setViewportSize({width, height: 1000});
    await page.emulateMedia({colorScheme: theme});
    await page.goto("/embed/component-frame?name=RedPacketCard&viewport=mobile");
    await page.locator(".flare-red-packet").first().waitFor();
    await page.evaluate(theme => {
      document.documentElement.dataset.flareTheme = theme;
      document.documentElement.classList.toggle("dark", theme === "dark");
    }, theme);
    for (let index = 0; index < vectors.cases.length; index++) {
      const item = vectors.cases[index];
      await page.evaluate(async index => {
        const fixture = await import("/tests/fixtures/wallet-records.ts");
        fixture.mountRecordFixture(index);
      }, index);
      await expect(page.locator(".flare-account-view")).toBeVisible();
      expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), `${item.id}/${item.variant}/${item.locale}`).toBe(true);
      const rows = item.view.blocks?.filter((block: {kind: string}) => block.kind === "rows").flatMap((block: {rows: unknown[]}) => block.rows) ?? [];
      if (item.view.presentation?.props.layout === "ledger") {
        await expect(page.locator('[data-account-entry]')).toHaveCount(rows.length);
        for (const row of rows) {
          const entry = page.locator(`[data-account-entry="${row.key}"]`);
          await expect(entry.locator("strong")).toHaveText(row.cells[1].text);
          if (row.badge) await expect(entry.locator('[data-account-badge]')).toHaveText(row.badge.text);
          expect(await entry.locator("b").evaluate(node => getComputedStyle(node).textOverflow)).not.toBe("ellipsis");
        }
        if (rows.length && item.view.presentation.props.rowEntryAction) {
          const row = rows[0], bound = row.actions.find((action: {id: string}) => action.id === item.view.presentation.props.rowEntryAction);
          await page.locator('[data-account-entry]').first().click();
          const calls = await page.evaluate(async () => (await import("/tests/fixtures/wallet-records.ts")).recordRequests());
          expect(calls).toEqual([{kind: "action", id: bound.id, payload: {page: {pluginId: "flare.wallet", page: item.page}, data: item.sourceData, row: {key: row.key, input: bound.input}}}]);
          await expect(page.locator('[role="dialog"]')).toHaveCount(0);
        }
        const field = item.view.inputs?.find((input: {kind: string; id: string}) => input.kind === "select" && item.view.blocks.some((block: {kind: string; filters?: string[]}) => block.kind === "rows" && block.filters?.includes(input.id)));
        if (field?.choices?.length) {
          const choice = field.choices.find((choice: {value: string}) => choice.value !== item.filters[field.id]);
          if (choice) {
            await page.locator(`[data-page-filter="${field.id}"]`).getByRole("tab", {name: choice.label, exact: true}).click();
            const requests = await page.evaluate(async () => (await import("/tests/fixtures/wallet-records.ts")).recordRequests());
            expect(requests.at(-1)).toEqual({kind: "filter", filters: {...item.filters, [field.id]: choice.value}});
          }
        }
      } else if (item.view.presentation?.props.layout === "flow") {
        const blocks = item.view.blocks.filter((block: {kind: string}) => block.kind === "rows");
        for (const block of blocks) for (const row of block.rows) {
          const entry = page.locator(`[data-row-key="${row.key}"]`);
          await expect(entry.locator('[data-row-primary-label]')).toHaveText(block.columns[0].label);
          await expect(entry.locator('[data-row-primary]')).toHaveText(row.cells[0].text);
        }
      }
      if (item.locale === "zh-CN") await page.screenshot({path: info.outputPath(`${item.id}-${item.variant}.png`), fullPage: true});
    }
    const index = vectors.cases.findIndex((item: {id: string; locale: string}) => item.id === "history" && item.locale === "zh-CN");
    for (const mode of ["loading", "error", "empty", "readError"] as const) {
      await page.evaluate(async ({index, mode}) => (await import("/tests/fixtures/wallet-records.ts")).mountRecordFixture(index, mode), {index, mode});
      if (mode === "error") await expect(page.locator('[data-page-retry]')).toBeVisible();
      if (mode === "empty") await expect(page.locator('[data-account-empty]')).toBeVisible();
      if (mode === "readError") {
        await expect(page.locator('[data-account-entry]')).toHaveCount(3);
        await page.locator('.flare-status-banner__action').click();
        expect(await page.evaluate(async () => (await import("/tests/fixtures/wallet-records.ts")).recordRequests())).toEqual([{kind: "refresh"}]);
      }
      await page.screenshot({path: info.outputPath(`history-${mode}.png`), fullPage: true});
    }
    await page.evaluate(async index => (await import("/tests/fixtures/wallet-records.ts")).mountRecordFixture(index, "longAmount"), index);
    const amount = page.locator('[data-account-entry]').first().locator("b");
    await expect(amount).toHaveText("+123,456,789,012,345,678,901,234,567.89");
    expect(await amount.evaluate(node => node.scrollWidth <= node.clientWidth + 1)).toBe(true);
    const title = page.locator('[data-account-entry]').first().locator("strong");
    expect(await title.evaluate(node => node.getBoundingClientRect().height < Number.parseFloat(getComputedStyle(node).fontSize) * 2)).toBe(true);
    expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth)).toBe(true);
    await page.screenshot({path: info.outputPath("history-synthetic-longAmount.png"), fullPage: true});
  });
}
