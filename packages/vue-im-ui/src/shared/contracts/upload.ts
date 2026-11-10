/** Controlled presentation state. The host owns files, policy, transfer and preview URLs. */
export type FlareUploadState =
  "empty" | "selected" | "uploading" | "uploaded" | "failed";
