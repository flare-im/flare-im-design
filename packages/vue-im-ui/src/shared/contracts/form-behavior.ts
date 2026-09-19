export type FormControlState = "default" | "hover" | "focus" | "pressed" | "filled" | "invalid" | "disabled" | "readOnly" | "loading";
export type FormKeyboardIntent = "none" | "tabForward" | "tabBackward" | "submit" | "closePopup" | "nextOption" | "previousOption" | "firstOption" | "lastOption" | "pageForward" | "pageBackward";

export interface FormKeyboardInput {
  key: string;
  shift?: boolean;
  composing?: boolean;
  popupOpen?: boolean;
  submitOnEnter?: boolean;
}

/**
 * One rule for every desktop key a form control sees.
 *
 * While an IME composition is open the IME owns the keyboard — Enter commits a
 * candidate, Escape cancels the composition, Tab and the arrows walk the
 * candidate window. So composing short-circuits everything: the control must not
 * submit, close its popup, or move focus out from under the user mid-word.
 */
export function resolveFormKeyboardIntent(input: FormKeyboardInput): FormKeyboardIntent {
  if (input.composing) return "none";
  const key = input.key.toLowerCase();
  if (key === "tab") return input.shift ? "tabBackward" : "tabForward";
  if (key === "escape" && input.popupOpen) return "closePopup";
  if (key === "enter" && input.submitOnEnter) return "submit";
  if (!input.popupOpen) return "none";
  if (key === "arrowdown") return "nextOption";
  if (key === "arrowup") return "previousOption";
  if (key === "home") return "firstOption";
  if (key === "end") return "lastOption";
  if (key === "pagedown") return "pageForward";
  if (key === "pageup") return "pageBackward";
  return "none";
}
