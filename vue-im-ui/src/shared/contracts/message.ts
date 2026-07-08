export type FlareContentElem = Record<string, unknown> & {
  contentType: string;
};

export type FlareMessageContentLike = {
  contentType?: string;
  data?: Record<string, unknown>;
};

export type FlareBusinessDetailRow = {
  key: string;
  label: string;
  value: string;
  tone?: "default" | "success" | "warning" | "danger" | "info";
};
