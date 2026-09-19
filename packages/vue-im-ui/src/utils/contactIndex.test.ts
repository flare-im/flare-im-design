import { describe, expect, it } from "vitest";
import { compareContactIndexLetters, compareContactNames, contactIndexLetter } from "./contactIndex";

describe("contactIndexLetter", () => {
  it("indexes Chinese names by the pinyin initial of the first character", () => {
    const names: Record<string, string> = {
      林夏: "L", 周屿: "Z", 产品设计组: "C", 苏晚晴: "S", 何川: "H", 陈默: "C", 唐果: "T", 徐知远: "X",
      家人: "J", 欧阳明月: "O", 陆遥: "L", 顾南: "G", 秦朗: "Q", 王: "W", 吕: "L", 罗: "L", 龙: "L",
      邓: "D", 丁: "D", 戴: "D", 艾: "A", 恩: "E", 冯: "F", 孔: "K", 马: "M", 牛: "N", 彭: "P", 任: "R",
      谭: "T", 夏: "X", 叶: "Y", 郑: "Z", 梓: "Z", 琪: "Q", 霖: "L", 苒: "R", 珩: "H", 玥: "Y", 婧: "J",
    };
    for (const [name, letter] of Object.entries(names)) expect(contactIndexLetter(name), name).toBe(letter);
  });

  it("indexes Latin names by their first letter, accents and full width included", () => {
    expect(contactIndexLetter(" alice")).toBe("A");
    expect(contactIndexLetter("Émile")).toBe("E");
    expect(contactIndexLetter("ｗｅｉ")).toBe("W");
  });

  it("puts digits, symbols and emoji under #, and honours the host's index key", () => {
    expect(contactIndexLetter("1号机")).toBe("#");
    expect(contactIndexLetter("😀 Pat")).toBe("#");
    expect(contactIndexLetter("")).toBe("#");
    expect(contactIndexLetter("曾一", "Zeng")).toBe("Z");
    expect(contactIndexLetter("Anyone", "?")).toBe("#");
  });
});

describe("contact ordering", () => {
  it("orders letters A to Z with # last, and names in pinyin order", () => {
    expect(["#", "Z", "A", "L"].sort(compareContactIndexLetters)).toEqual(["A", "L", "Z", "#"]);
    expect(["陆遥", "林夏", "李"].sort(compareContactNames)).toEqual(["李", "林夏", "陆遥"]);
  });
});
