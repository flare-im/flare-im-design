import { describe, expect, it } from "vitest";
import { keepArchivedConversations } from "./useFlareCoreClient";

describe("keepArchivedConversations", () => {
  it("只保留已归档的会话", () => {
    const kept = keepArchivedConversations([
      { id: "a", isArchived: true },
      { id: "b", isArchived: false },
      { id: "c", isArchived: true },
    ]);
    expect(kept.map((c) => c.id)).toEqual(["a", "c"]);
  });

  it("未归档的一条都不放过——这正是原先的失效方式", () => {
    // 原实现直接用 includeArchived 当筛选，于是归档筛选原样返回全部会话：
    // 高亮切了、内容一条没少，看起来像是"这些会话都归档了"。
    const all = [
      { id: "a", isArchived: false },
      { id: "b", isArchived: false },
    ];
    expect(keepArchivedConversations(all)).toHaveLength(0);
    expect(keepArchivedConversations(all)).not.toHaveLength(all.length);
  });

  it("把缺失的 isArchived 当作未归档", () => {
    expect(keepArchivedConversations([{ id: "a" }, { id: "b", isArchived: true }])).toEqual([
      { id: "b", isArchived: true },
    ]);
  });

  it("不改动传入的数组", () => {
    const input = [{ id: "a", isArchived: false }];
    keepArchivedConversations(input);
    expect(input).toHaveLength(1);
  });
});
