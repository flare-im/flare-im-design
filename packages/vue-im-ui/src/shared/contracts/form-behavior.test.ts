import { describe, expect, it } from "vitest";
import { resolveFormKeyboardIntent, type FormKeyboardIntent } from "./form-behavior";

// DoD 20 — the vector table of spec/form-keyboard-contract.json. The four
// platforms run the same ids; tooling/check-form-keyboard.mjs fails when one of
// them stops exercising a vector.
const vectors: [string, Parameters<typeof resolveFormKeyboardIntent>[0], FormKeyboardIntent][] = [
  ["enter.submits", { key: "Enter", submitOnEnter: true }, "submit"],
  ["enter.withoutSubmitMode", { key: "Enter" }, "none"],
  ["enter.composing", { key: "Enter", composing: true, submitOnEnter: true }, "none"],
  ["tab.forward", { key: "Tab" }, "tabForward"],
  ["tab.backward", { key: "Tab", shift: true }, "tabBackward"],
  ["tab.composing", { key: "Tab", composing: true }, "none"],
  ["escape.closesPopup", { key: "Escape", popupOpen: true }, "closePopup"],
  ["escape.withoutPopup", { key: "Escape" }, "none"],
  ["escape.composing", { key: "Escape", composing: true, popupOpen: true }, "none"],
  ["arrowDown.nextOption", { key: "ArrowDown", popupOpen: true }, "nextOption"],
  ["arrowUp.previousOption", { key: "ArrowUp", popupOpen: true }, "previousOption"],
  ["arrowDown.composing", { key: "ArrowDown", composing: true, popupOpen: true }, "none"],
  ["arrowDown.withoutPopup", { key: "ArrowDown" }, "none"],
  ["home.firstOption", { key: "Home", popupOpen: true }, "firstOption"],
  ["end.lastOption", { key: "End", popupOpen: true }, "lastOption"],
  ["pageDown.pageForward", { key: "PageDown", popupOpen: true }, "pageForward"],
  ["pageUp.pageBackward", { key: "PageUp", popupOpen: true }, "pageBackward"],
  ["unknownKey", { key: "F13", popupOpen: true }, "none"],
];

describe("desktop form behavior", () => {
  it.each(vectors)("%s", (_id, input, expected) => {
    expect(resolveFormKeyboardIntent(input)).toBe(expected);
  });

  it("gives the IME every key it asks for while a composition is open", () => {
    // The guard is unconditional on purpose: a composing Tab must not move focus
    // out from under a half-typed word, and a composing Escape belongs to the IME.
    for (const key of ["Enter", "Tab", "Escape", "ArrowDown", "ArrowUp", "Home", "End", "PageDown", "PageUp"]) {
      expect(resolveFormKeyboardIntent({ key, composing: true, popupOpen: true, submitOnEnter: true, shift: true })).toBe("none");
    }
  });

  it("is case-insensitive about the key name", () => {
    expect(resolveFormKeyboardIntent({ key: "enter", submitOnEnter: true })).toBe("submit");
    expect(resolveFormKeyboardIntent({ key: "ARROWDOWN", popupOpen: true })).toBe("nextOption");
  });
});
