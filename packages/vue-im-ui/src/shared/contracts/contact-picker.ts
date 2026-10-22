/**
 * Contact picker contracts (spec ContactPicker): the people a contact card can name, grouped the way
 * the host knows them. The kit filters and draws; who may be shared is the host's and the server's rule.
 */

/** One person the picker can return. */
export interface FlareContactPickerEntry {
  userId: string;
  name: string;
  avatarUrl?: string;
  /** A secondary line (department, handle); searched with the name. */
  subtitle?: string;
  /** The signed-in user: drawn with the "(me)" suffix and still selectable. */
  isSelf?: boolean;
}

/** The group ids the kit can label itself; any other id needs a `label`. */
export type FlareContactPickerGroupId = "friends" | "groupMembers";

/** One tab of the picker. A picker with a single group shows no tabs. */
export interface FlareContactPickerGroup {
  id: FlareContactPickerGroupId | (string & {});
  /** Tab label; defaults to the kit's words for `friends` and `groupMembers`. */
  label?: string;
  entries: FlareContactPickerEntry[];
}

/** Case-insensitive match of a query against an entry's name and subtitle; a blank query matches all. */
export function matchesFlareContactPickerEntry(entry: FlareContactPickerEntry, query: string): boolean {
  const needle = query.trim().toLocaleLowerCase();
  if (!needle) return true;
  return entry.name.toLocaleLowerCase().includes(needle)
    || (entry.subtitle?.toLocaleLowerCase().includes(needle) ?? false);
}
