/** Dynamic directory choices. Keys use absolute JSON pointers, including array indexes. */
export interface SchemaSelection {
  options: { value: string; label: string; disabled?: boolean }[];
  loading?: boolean;
  remote?: boolean;
  error?: string;
  invalid?: string;
  disabled?: boolean;
  hasMore?: boolean;
  emptyOptionLabel?: string;
}
export interface SchemaSelectionLabels {
  loading?: string;
  placeholder: string;
  empty: string;
  more: string;
  retry: string;
  unavailable: string;
}
export function schemaFieldPath(parent: string, key: string | number): string {
  return `${parent}/${String(key).replace(/~/g, "~0").replace(/\//g, "~1")}`;
}
