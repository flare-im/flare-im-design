export type MessageContentKind =
  | "text" | "richText" | "markdown" | "code" | "image" | "multiImage"
  | "video" | "audio" | "file" | "location" | "contactCard" | "linkPreview"
  | "poll" | "task" | "calendarEvent" | "miniApp" | "topic" | "system"
  | "notice" | "forward" | "mergedForward" | "reply" | "threadRoot"
  | "ephemeral" | "readOnce" | "burnAfterRead";

export type MessageContentFamily =
  | "text" | "richText" | "code" | "image" | "video" | "audio" | "file"
  | "location" | "card" | "link" | "poll" | "task" | "calendar" | "miniApp"
  | "topic" | "system" | "forward" | "reply" | "thread" | "treatment";

export type MessageContentCapability =
  | "select" | "copy" | "openLink" | "horizontalScroll" | "open" | "save"
  | "retry" | "zoom" | "swipe" | "play" | "pause" | "fullscreen" | "seek"
  | "reveal" | "vote" | "toggleTask" | "jumpToOriginal" | "openThread" | "openOnce";

export interface MessageContentContract {
  kind: MessageContentKind;
  wireType?: string;
  family: MessageContentFamily;
  capabilities: ReadonlySet<MessageContentCapability>;
}

const definitions: Record<MessageContentKind, readonly [string | undefined, MessageContentFamily, readonly MessageContentCapability[]]> = {
  text: ["text", "text", ["select", "copy"]],
  richText: ["rich_text", "richText", ["select", "copy", "openLink"]],
  markdown: ["rich_text", "richText", ["select", "copy", "openLink"]],
  code: ["rich_text", "code", ["select", "copy", "horizontalScroll"]],
  image: ["image", "image", ["open", "save", "retry", "zoom"]],
  multiImage: ["image_group", "image", ["open", "save", "retry", "zoom", "swipe"]],
  video: ["video", "video", ["play", "pause", "fullscreen", "save", "retry"]],
  audio: ["audio", "audio", ["play", "pause", "seek", "retry"]],
  file: ["file", "file", ["open", "save", "reveal", "retry"]],
  location: ["location", "location", ["open"]],
  contactCard: ["card", "card", ["open"]],
  linkPreview: ["link_card", "link", ["open", "copy"]],
  poll: ["vote", "poll", ["vote"]],
  task: ["task", "task", ["toggleTask", "open"]],
  calendarEvent: ["schedule", "calendar", ["open"]],
  miniApp: ["mini_program", "miniApp", ["open"]],
  topic: ["custom", "topic", ["open"]],
  system: ["system", "system", []],
  notice: ["notification", "system", ["open"]],
  forward: ["forward", "forward", ["open"]],
  mergedForward: ["forward", "forward", ["open"]],
  reply: ["quote", "reply", ["jumpToOriginal"]],
  threadRoot: ["thread", "thread", ["openThread"]],
  ephemeral: [undefined, "treatment", []],
  readOnce: [undefined, "treatment", ["openOnce"]],
  burnAfterRead: [undefined, "treatment", ["openOnce"]],
};

export const MESSAGE_CONTENT_KINDS = Object.freeze(Object.keys(definitions) as MessageContentKind[]);

export function resolveMessageContentContract(kind: MessageContentKind): MessageContentContract {
  const [wireType, family, capabilities] = definitions[kind];
  return { kind, wireType, family, capabilities: new Set(capabilities) };
}

const wireDefaults: Record<string, MessageContentKind> = {
  text: "text", rich_text: "richText", image: "image", image_group: "multiImage",
  video: "video", audio: "audio", file: "file", location: "location", card: "contactCard",
  link_card: "linkPreview", vote: "poll", task: "task", schedule: "calendarEvent",
  mini_program: "miniApp", system: "system", notification: "notice", forward: "forward",
  quote: "reply", thread: "threadRoot", custom: "topic",
};

/** Maps host content kinds to default renderers. Hosts may refine rich/custom subtypes. */
export function messageContentKindFromWire(wireType: string): MessageContentKind | undefined {
  return wireDefaults[wireType];
}
