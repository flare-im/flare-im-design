/**
 * The host-owned contract of FlareDescriptionList and the pure rules it draws from: what an empty
 * value is, how wide an item may be, what a copy key writes. Nothing here touches the DOM.
 */

export type FlareDescriptionValue = string | number | null | undefined;

export interface FlareDescriptionItem {
  /** Stable id of the line; also names the `item-<key>` slot. */
  key: string;
  /** What the value is. */
  label: string;
  /** The value as text. `null`, `undefined` and an empty string are "not set", never a blank. */
  value?: FlareDescriptionValue;
  /** Columns this line spans; clamped to the list's columns. Default 1. */
  span?: number;
  /** Draw the value in the monospaced face — ids, codes, keys. */
  monospace?: boolean;
  /** Draw a copy key after the value; it copies the value's text. */
  copyable?: boolean;
}

export type FlareDescriptionLabelPlacement = "start" | "top";

/** The most columns a list lays out; more than this stops reading as a list of facts. */
export const FLARE_DESCRIPTION_MAX_COLUMNS = 4;

/** Columns the list asks for, as a whole number between 1 and the maximum. */
export function descriptionColumns(columns: number | undefined): number {
  const value = Math.floor(Number(columns ?? 2));
  if (!Number.isFinite(value) || value < 1) return 1;
  return Math.min(value, FLARE_DESCRIPTION_MAX_COLUMNS);
}

/** Columns one line takes: its `span`, never more than the list has and never less than one. */
export function descriptionSpan(item: FlareDescriptionItem, columns: number): number {
  const span = Math.floor(Number(item.span ?? 1));
  if (!Number.isFinite(span) || span < 1) return 1;
  return Math.min(span, descriptionColumns(columns));
}

/** A value with nothing to show: drawn as a dash and read as "not set". Zero and `false`-like text are values. */
export function descriptionIsEmpty(value: FlareDescriptionValue): boolean {
  if (value === null || value === undefined) return true;
  if (typeof value === "number") return !Number.isFinite(value);
  return value.trim() === "";
}

/** The text a line shows and a copy key writes; empty for a value that is not set. */
export function descriptionText(value: FlareDescriptionValue): string {
  return descriptionIsEmpty(value) ? "" : String(value);
}
