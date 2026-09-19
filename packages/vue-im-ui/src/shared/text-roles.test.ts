import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import tokens from "../../../../tokens/tokens.json";

// FR-051: a title, a section header, body text and a caption are named once, in the token source, and
// generated for every kit. Before this, apps reached for SwiftUI fonts, Material text styles and
// TextStyle literals, and no two agreed.

const roles = tokens.sizes.textRole as Record<string, { fontSize: string; lineHeight: string; weight: string }>;
const read = (path: string) => readFileSync(new URL(path, import.meta.url), "utf8");

describe("text roles", () => {
  it("names the four roles a screen needs", () => {
    expect(Object.keys(roles)).toEqual(["title", "section", "body", "caption"]);
  });

  it("reaches the web as three custom properties per role", () => {
    const css = read("../../../../tokens/dist/tokens.css");
    for (const [name, role] of Object.entries(roles)) {
      expect(css, name).toContain(`--flare-text-${name}-font-size: ${role.fontSize};`);
      expect(css).toContain(`--flare-text-${name}-line-height: ${role.lineHeight};`);
      expect(css).toContain(`--flare-text-${name}-weight: ${role.weight};`);
    }
  });

  it("reaches all three native kits with the same numbers", () => {
    const dart = read("../../../../packages/flutter-im-ui/lib/src/tokens/flare_tokens.dart");
    const swift = read("../../../../packages/ios-im-ui/Sources/FlareIMUI/Tokens/FlareTokens.swift");
    const kotlin = read("../../../../packages/android-im-ui/src/main/kotlin/com/flare/im/ui/FlareTokens.kt");
    for (const [name, role] of Object.entries(roles)) {
      const size = parseFloat(role.fontSize);
      const height = parseFloat(role.lineHeight);
      const weight = parseInt(role.weight, 10);
      expect(dart, name).toContain(`static const FlareTextRole ${name} = FlareTextRole(fontSize: ${size.toFixed(1)}, lineHeight: ${height}, weight: ${weight});`);
      expect(swift, name).toContain(`public static let ${name} = FlareTextRole(fontSize: ${size}, lineHeight: ${height}, weight: ${weight})`);
      const pascal = name[0].toUpperCase() + name.slice(1);
      expect(kotlin, name).toContain(`val ${pascal} = FlareTextRole(${size}.sp, ${height}f, ${weight})`);
    }
  });
});
