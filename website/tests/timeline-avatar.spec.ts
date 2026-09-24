import { expect, test } from "@playwright/test";

/**
 * 时间线头像:一个尺寸、顶对齐。
 *
 * 改前 Vue 是四端里唯一的异类:34px(容器 ≥900 时 36px),用四个魔数(16/24/17/25)把头像
 * 底边对到单行气泡的底边 —— 一行以上的消息,头像就飘在半空;三个原生端都是顶对齐。现在四端同读
 * `sizes.component.messageAvatarSize`(40 = 单行气泡高),头像顶边 = 这一行内容的顶边:普通行贴着
 * 气泡顶,有发送者名字行的群聊首行贴着名字行。happy-dom 没有布局,这些只能在真引擎里量。
 */
for (const width of [390, 1024]) {
  test(`the avatar is 40px, top-aligned to the row's content, at ${width}`, async ({ page }) => {
    await page.setViewportSize({ width, height: 900 });
    await page.goto(`/embed/component-frame?name=ChatWorkspace&viewport=${width < 600 ? "mobile" : "desktop"}`);
    const first = page.locator(".message-row--with-avatar").first();
    await first.waitFor();
    const rows = await page.locator(".message-row--with-avatar").evaluateAll((nodes) =>
      (nodes as HTMLElement[]).map((row) => {
        const box = (el: Element | null) => (el ? el.getBoundingClientRect() : null);
        const avatar = box(row.querySelector(".message-avatar"))!;
        const meta = box(row.querySelector(".message-meta"));
        const bubble = box(row.querySelector(".message-bubble"))!;
        return {
          withMeta: row.classList.contains("message-row--with-meta"),
          avatar: { w: Math.round(avatar.width), h: Math.round(avatar.height), top: Math.round(avatar.top) },
          contentTop: Math.round((meta ?? bubble).top),
          gutter: Math.round(bubble.left - avatar.left),
        };
      }),
    );
    expect(rows.length).toBeGreaterThan(0);
    for (const row of rows) {
      expect(row.avatar.w, "avatar width").toBe(40);
      expect(row.avatar.h, "avatar height").toBe(40);
      // 顶边对齐这一行的第一样内容:有名字行时是名字行,否则是气泡。
      expect(Math.abs(row.avatar.top - row.contentTop), `avatar top vs content top (withMeta=${row.withMeta})`).toBeLessThanOrEqual(1);
      // 槽宽 = 头像 + spacing.sm,任何宽度一样。
      expect(row.gutter, "avatar gutter").toBe(48);
    }
  });
}

/**
 * 上面的夹具是群聊 —— 每一行头像都带名字行,只测它们的话,普通行(单聊,头像贴气泡顶)的规则坏了
 * 也看不见:反向验证时把普通行的 top 改回 16px,群聊用例照样绿。MessageBubble 的 demo 里有一个
 * 单聊舞台正好补上这一半;先断言它确实有不带名字行的头像行,否则这条什么也证明不了。
 */
test("a direct chat's avatar sits flush with the bubble's top", async ({ page }) => {
  await page.setViewportSize({ width: 1024, height: 900 });
  await page.goto("/embed/component-frame?name=MessageBubble&viewport=desktop");
  await page.locator(".message-row--with-avatar:not(.message-row--with-meta) .message-avatar").first().waitFor();
  const rows = await page.locator(".message-row--with-avatar:not(.message-row--with-meta)").evaluateAll((nodes) =>
    (nodes as HTMLElement[]).map((row) => {
      const avatar = row.querySelector(".message-avatar")!.getBoundingClientRect();
      const bubble = row.querySelector(".message-bubble")!.getBoundingClientRect();
      return { size: [Math.round(avatar.width), Math.round(avatar.height)], topGap: Math.round(avatar.top - bubble.top), gutter: Math.round(bubble.left - avatar.left) };
    }),
  );
  expect(rows.length, "the demo renders plain avatar rows").toBeGreaterThan(0);
  for (const row of rows) {
    expect(row.size).toEqual([40, 40]);
    expect(Math.abs(row.topGap), "avatar top vs bubble top").toBeLessThanOrEqual(1);
    expect(row.gutter).toBe(48);
  }
});
