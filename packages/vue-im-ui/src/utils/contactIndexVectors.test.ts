import { describe, expect, it } from "vitest";
import vectors from "../../../../spec/contact-index-vectors.json";
import { contactIndexLetter } from "./contactIndex";

// FR-044: one index letter per character, on all four kits. Vue and SwiftUI read the platform's pinyin
// collation; Flutter and Compose read the table generated from it. A kit that disagrees here has a
// defect, not a dialect — 曾 was Z on Flutter and C everywhere else for three rounds because nothing
// compared them.
describe("the shared contact-index table", () => {
  it("covers every group the table names", () => {
    const listed = Object.values(vectors.groups).join("");
    expect(new Set(listed).size).toBe(Object.keys(vectors.letters).length);
  });

  it("reads every character the way the table says", () => {
    const wrong: string[] = [];
    for (const [character, letter] of Object.entries(vectors.letters)) {
      const actual = contactIndexLetter(character);
      if (actual !== letter) wrong.push(`${character}: ${actual} (table says ${letter})`);
    }
    expect(wrong).toEqual([]);
  });

  it("still reads the characters the old tables missed", () => {
    for (const character of vectors.groups.formerlyMissing) {
      expect(contactIndexLetter(character)).not.toBe("#");
    }
  });
});
