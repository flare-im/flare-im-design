/** Safe, presentation-only user summary. No internal ID, contact data or runtime lookup. */
export interface FlareUserIdentityValue {
  name?: string;
  account?: string;
  avatarUrl?: string;
  state?: "ready" | "loading" | "unavailable";
}
