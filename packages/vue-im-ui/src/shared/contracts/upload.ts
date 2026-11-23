/** Controlled presentation state. The host owns files, policy, transfer and preview URLs. */
export type FlareUploadState =
  "empty" | "selected" | "uploading" | "uploaded" | "failed";

/** A host-owned item. Progress, preview URLs and every outcome remain authoritative inputs. */
export interface FlareMediaUploadItem {
  id: string;
  name: string;
  state: FlareUploadState;
  statusText: string;
  previewUrl?: string;
  progress?: number;
  /** Lock this item while unrelated selections and recovery actions remain available. */
  disabled?: boolean;
}
