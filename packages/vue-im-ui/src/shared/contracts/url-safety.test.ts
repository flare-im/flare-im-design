import { describe, expect, it } from "vitest";
import { isSafeExternalUrl, safeExternalUrl } from "./url-safety";

// DoD 32 — the vector table of spec/security-boundary.json. Message content is
// written by other people; every one of these is something an attacker can put
// in a message.
const hostile = [
  ["javascript.plain", "javascript:alert(1)"],
  ["javascript.uppercase", "JaVaScRiPt:alert(1)"],
  ["javascript.leadingSpace", "   javascript:alert(1)"],
  ["javascript.embeddedTab", "java\tscript:alert(1)"],
  ["javascript.embeddedNewline", "java\nscript:alert(1)"],
  ["data.html", "data:text/html,<script>alert(1)</script>"],
  ["data.base64", "data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg=="],
  ["vbscript", "vbscript:msgbox(1)"],
  ["file", "file:///etc/passwd"],
  ["blob", "blob:https://evil.example/9b2d"],
  ["about", "about:blank"],
  ["empty", ""],
  ["whitespace", "   "],
  ["notAUrl", "just some text"],
] as const;

const allowed = [
  ["http", "http://example.com/path?q=1"],
  ["https", "https://example.com/path#anchor"],
  ["schemeless", "example.com/path"],
  ["schemelessWithPort", "example.com:8443/path"],
] as const;

describe("safeExternalUrl", () => {
  it.each(hostile)("refuses %s", (_id, input) => {
    expect(safeExternalUrl(input)).toBeNull();
    expect(isSafeExternalUrl(input)).toBe(false);
  });

  it.each(allowed)("allows %s", (_id, input) => {
    expect(isSafeExternalUrl(input)).toBe(true);
  });

  it("reads a scheme-less string as https, and never rescues one that has a scheme", () => {
    expect(safeExternalUrl("example.com")).toBe("https://example.com/");
    // The rescue must not turn a hostile scheme into a host name.
    expect(safeExternalUrl("javascript:alert(1)")).toBeNull();
  });

  it("refuses a nullish or non-string value without throwing", () => {
    expect(safeExternalUrl(null)).toBeNull();
    expect(safeExternalUrl(undefined)).toBeNull();
    expect(safeExternalUrl(42 as unknown as string)).toBeNull();
  });
});
