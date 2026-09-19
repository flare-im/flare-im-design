// Form-control shared contracts.

export type FlareButtonVariant = "primary" | "secondary" | "ghost" | "danger" | "text";
export type FlareControlSize = "sm" | "md" | "lg";

/** One option in a select / radio group. */
export interface FlareSelectOption {
  value: string;
  label: string;
  disabled?: boolean;
}
