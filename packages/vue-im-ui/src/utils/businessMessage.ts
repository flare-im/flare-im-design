import type { FlareBusinessDetailRow, FlareContentElem } from "../shared/contracts/message";
import { asRecord, readArray, readString } from "./contentData";
import { pickNestedPayload } from "./contentElem";

export function businessPayload(content: FlareContentElem, nestedKey: string): Record<string, unknown> {
  const nested = pickNestedPayload(content as Parameters<typeof pickNestedPayload>[0], nestedKey);
  return Object.keys(nested).length ? nested : asRecord(content);
}

export function businessTitle(payload: Record<string, unknown>, fallback: string): string {
  return readString(payload, "title", "name", "headline", "subject") || fallback;
}

export function businessSubtitle(payload: Record<string, unknown>): string {
  return readString(payload, "description", "detail", "summary", "content", "text");
}

export function businessStatus(payload: Record<string, unknown>): string {
  return readString(payload, "status", "state", "phase");
}

export function businessRows(payload: Record<string, unknown>, labels: Record<string, string>): FlareBusinessDetailRow[] {
  const rows: FlareBusinessDetailRow[] = [];
  const mappings: Array<[string, ...string[]]> = [
    ["owner", "owner", "ownerName", "owner_name", "creator", "creatorName", "creator_name"],
    ["assignee", "assignee", "assigneeName", "assignee_name", "assignedTo", "assigned_to", "executor"],
    ["dueTime", "dueTime", "due_time", "dueDate", "due_date", "deadline", "endTime", "end_time", "endTimeMs", "end_time_ms"],
    ["location", "location", "address", "place"],
    ["participants", "participants", "participantUserIds", "participant_user_ids", "members"],
    ["options", "options", "choices", "voteOptions", "vote_options"],
  ];
  for (const [labelKey, ...keys] of mappings) {
    const label = labels[labelKey];
    if (!label) continue;
    for (const key of keys) {
      const text = businessDisplayValue(payload[key], key);
      if (text) {
        rows.push({ key: labelKey, label, value: text });
        break;
      }
    }
  }
  return rows;
}

export function statusTone(status: string): "default" | "success" | "warning" | "danger" | "info" {
  const normalized = status.toLowerCase();
  if (/(done|complete|finished|closed|success|approved)/.test(normalized)) return "success";
  if (/(pending|todo|open|draft|waiting)/.test(normalized)) return "warning";
  if (/(overdue|failed|rejected|cancelled|canceled|expired)/.test(normalized)) return "danger";
  if (/(in_progress|processing|active|running)/.test(normalized)) return "info";
  return "default";
}

export function participantIds(payload: Record<string, unknown>): string[] {
  return readArray(payload, "participantUserIds", "participant_user_ids", "participants", "members")
    .map((item: unknown) => {
      if (typeof item === "string") return item.trim();
      if (item && typeof item === "object") {
        return readString(asRecord(item), "userId", "id", "name");
      }
      return "";
    })
    .filter(Boolean);
}

function businessDisplayValue(value: unknown, key: string): string {
  if (typeof value === "string" && value.trim()) return value.trim();
  if (typeof value === "number" && Number.isFinite(value)) {
    return /time|date|deadline/i.test(key) ? formatBusinessTime(value) : String(value);
  }
  if (Array.isArray(value) && value.length) {
    return value
      .map((item: unknown) => {
        if (typeof item === "string" || typeof item === "number") return String(item);
        if (item && typeof item === "object") {
          return readString(asRecord(item), "name", "title", "label", "text", "userId", "id");
        }
        return "";
      })
      .filter(Boolean)
      .join(", ");
  }
  return "";
}

function formatBusinessTime(value: number): string {
  if (!value) return "";
  const millis = value > 1_000_000_000_000 ? value : value * 1000;
  try {
    return new Date(millis).toLocaleString();
  } catch {
    return String(value);
  }
}
