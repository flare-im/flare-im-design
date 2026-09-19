import { describe, expect, it } from "vitest";
import { renderMarkdown } from "./markdown";

// DoD 32 — the one place in the kit that produces HTML from message text. Every
// input here is something an attacker can put in a message; the assertions are
// what must never appear in the output.
function render(input: string): string {
  return renderMarkdown(input);
}

describe("renderMarkdown against hostile message text", () => {
  it("never emits a script tag", () => {
    for (const input of [
      "<script>alert(1)</script>",
      "<SCRIPT>alert(1)</SCRIPT>",
      "<img src=x onerror=alert(1)>",
      "<svg onload=alert(1)>",
      "<iframe src=https://evil.example></iframe>",
    ]) {
      const html = render(input);
      expect(html, input).not.toMatch(/<script/i);
      expect(html, input).not.toMatch(/<iframe/i);
      // Escaped text may well contain the word "onerror"; what must not exist is
      // a live element carrying an event handler.
      expect(html, input).not.toMatch(/<[a-z][^>]*\son[a-z]+\s*=/i);
    }
  });

  it("never turns a hostile scheme into a link", () => {
    for (const input of [
      "[click](javascript:alert(1))",
      "[click](JaVaScRiPt:alert(1))",
      "[click](  javascript:alert(1))",
      "[click](vbscript:msgbox(1))",
      "[click](data:text/html,<script>alert(1)</script>)",
      "![img](javascript:alert(1))",
      "javascript:alert(1)",
      '<a href="javascript:alert(1)">x</a>',
    ]) {
      const html = render(input);
      expect(html, input).not.toMatch(/href\s*=\s*["']?\s*javascript:/i);
      expect(html, input).not.toMatch(/href\s*=\s*["']?\s*vbscript:/i);
      expect(html, input).not.toMatch(/href\s*=\s*["']?\s*data:/i);
      expect(html, input).not.toMatch(/src\s*=\s*["']?\s*javascript:/i);
    }
  });

  it("opens a real link in a new context without handing over the opener", () => {
    const html = render("[ok](https://example.com)");
    expect(html).toContain('href="https://example.com"');
    expect(html).toContain('rel="noopener noreferrer"');
    expect(html).toContain('target="_blank"');
  });

  it("only un-escapes the bare underline tag, never one carrying attributes", () => {
    // `html: false` escapes every tag; the renderer then restores <u> alone,
    // because markdown has no underline of its own.
    expect(render("<u>underline</u>")).toContain("<u>underline</u>");
    const withAttribute = render("<u onmouseover=alert(1)>x</u>");
    expect(withAttribute).not.toMatch(/<u\s/);
    expect(withAttribute).toContain("&lt;u onmouseover=alert(1)&gt;");
  });

  it("leaves an entity the sender typed as an entity", () => {
    // A sender writing the escaped form must not get a live tag out of it.
    expect(render("&lt;u onmouseover=alert(1)&gt;x")).not.toMatch(/<u\s/);
  });
});
