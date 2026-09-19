import type { FlareActionItem } from "./action-menu";
import type { FlareConversationKind } from "./conversation";


export type FlareConversationHeaderPresence =
  | "online"
  | "offline"
  | "busy"
  | "away";

/** Host-owned identity rendered by ConversationHeader. */
export interface FlareConversationIdentity {
  id: string;
  title: string;
  kind?: FlareConversationKind;
  subtitle?: string;
  avatarUrl?: string;
  presence?: FlareConversationHeaderPresence;
  memberCount?: number;
  typingText?: string;
  accessibilityLabel?: string;
  /** Activated from the whole identity block (avatar, title and subtitle), e.g. open the conversation details. */
  action?: FlareConversationHeaderAction;
}

export type FlareConversationHeaderActionPlacement =
  | "primary"
  | "add"
  | "overflow";

/** One host intent in the header. `add` items appear under the dedicated Plus menu. */
export interface FlareConversationHeaderAction<TIcon = string>
  extends FlareActionItem<TIcon> {
  placement?: FlareConversationHeaderActionPlacement;
  capability?: string;
}

/** Business availability supplied by the host. Omitted means defaults are available. */
export interface FlareConversationHeaderCapabilities {
  availableActionIds?: readonly string[];
}

export interface FlareConversationHeaderActionOverride<TIcon = string>
  extends Partial<FlareConversationHeaderAction<TIcon>> {
  id: string;
}

/**
 * Product configuration layered over the library preset. It deliberately keeps
 * policy out of the component and avoids one boolean prop per action.
 */
export interface FlareConversationHeaderConfiguration<TIcon = string> {
  replaceDefaults?: boolean;
  removeActionIds?: readonly string[];
  actionOverrides?: readonly FlareConversationHeaderActionOverride<TIcon>[];
  maxPrimaryActions?: number;
  compactMaxPrimaryActions?: number;
}

export interface ResolveConversationHeaderActionsOptions<TIcon = string> {
  identity: Pick<FlareConversationIdentity, "kind">;
  capabilities?: FlareConversationHeaderCapabilities;
  configuration?: FlareConversationHeaderConfiguration<TIcon>;
  actions?: readonly FlareConversationHeaderAction<TIcon>[];
}

export const FLARE_DIRECT_CONVERSATION_HEADER_ACTIONS: readonly FlareConversationHeaderAction[] = [
  { id: "search", label: "Search messages", icon: "search", placement: "primary", order: 10 },
  { id: "audioCall", label: "Start audio call", icon: "phone", placement: "primary", capability: "audioCall", order: 20 },
  { id: "videoCall", label: "Start video call", icon: "video", placement: "primary", capability: "videoCall", order: 30 },
  { id: "share", label: "Share contact", icon: "share", placement: "add", order: 40 },
  { id: "details", label: "Conversation details", icon: "info", placement: "overflow", order: 90 },
] as const;

export const FLARE_GROUP_CONVERSATION_HEADER_ACTIONS: readonly FlareConversationHeaderAction[] = [
  { id: "search", label: "Search messages", icon: "search", placement: "primary", order: 10 },
  { id: "audioCall", label: "Start audio call", icon: "phone", placement: "primary", capability: "audioCall", order: 20 },
  { id: "videoCall", label: "Start video call", icon: "video", placement: "primary", capability: "videoCall", order: 30 },
  { id: "addMember", label: "Add member", icon: "person-add", placement: "add", order: 40 },
  { id: "share", label: "Share conversation", icon: "share", placement: "add", order: 50 },
  { id: "details", label: "Conversation details", icon: "info", placement: "overflow", order: 90 },
] as const;

export const DefaultDirectConversationHeaderConfig: FlareConversationHeaderConfiguration = {
  maxPrimaryActions: 3,
  compactMaxPrimaryActions: 1,
};

export const DefaultGroupConversationHeaderConfig: FlareConversationHeaderConfiguration = {
  maxPrimaryActions: 3,
  compactMaxPrimaryActions: 1,
};

function defaultActions(
  kind: FlareConversationKind | undefined,
): readonly FlareConversationHeaderAction[] {
  return kind === "group" || kind === "channel"
    ? FLARE_GROUP_CONVERSATION_HEADER_ACTIONS
    : FLARE_DIRECT_CONVERSATION_HEADER_ACTIONS;
}

/** Defaults -> capabilities -> host configuration -> custom actions. */
export function resolveConversationHeaderActions<TIcon = string>({
  identity,
  capabilities,
  configuration,
  actions,
}: ResolveConversationHeaderActionsOptions<TIcon>): FlareConversationHeaderAction<TIcon>[] {
  const source = configuration?.replaceDefaults
    ? []
    : defaultActions(identity.kind).map((item) => ({ ...item })) as FlareConversationHeaderAction<TIcon>[];
  const byId = new Map(source.map((item) => [item.id, item]));

  for (const override of configuration?.actionOverrides ?? []) {
    const current = byId.get(override.id);
    if (current) byId.set(override.id, { ...current, ...override });
  }
  for (const action of actions ?? []) {
    const current = byId.get(action.id);
    byId.set(action.id, current ? { ...current, ...action } : { ...action });
  }

  const removed = new Set(configuration?.removeActionIds ?? []);
  const available = capabilities?.availableActionIds
    ? new Set(capabilities.availableActionIds)
    : undefined;
  const seen = new Set<string>();

  return [...byId.values()]
    .map((action, index) => ({ action, index }))
    .filter(({ action }) => {
      if (!action.id || seen.has(action.id) || removed.has(action.id) || action.visible === false) return false;
      if (available && !available.has(action.capability ?? action.id)) return false;
      seen.add(action.id);
      return true;
    })
    .sort((left, right) =>
      (left.action.order ?? left.index) - (right.action.order ?? right.index)
      || left.index - right.index)
    .map(({ action }) => action);
}
