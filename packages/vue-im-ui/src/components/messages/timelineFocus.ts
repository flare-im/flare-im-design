import { inject, provide, type InjectionKey, type Ref } from "vue";
import type { MessageLike } from "../../shared/contracts/messageRow";
import { messageContentTypeForUi } from "../../utils/messageContent";

/**
 * Keyboard focus inside a message list. One message at a time is in the Tab sequence (the one focus
 * was last in, else the newest), the arrow keys move between messages, and a message's hover
 * controls join the Tab sequence only while focus is inside that message. A bubble outside a list
 * keeps its own Tab stop.
 */
export interface TimelineFocus {
  /** Id of the message whose bubble takes Tab; empty when no message can. */
  readonly target: Readonly<Ref<string>>;
  activate(id: string): void;
}

const timelineFocusKey: InjectionKey<TimelineFocus> = Symbol("flare-timeline-focus");

export function provideTimelineFocus(focus: TimelineFocus): void {
  provide(timelineFocusKey, focus);
}

export function injectTimelineFocus(): TimelineFocus | null {
  return inject(timelineFocusKey, null);
}

/** A message whose bubble opens the message menu, and so takes keyboard focus: not a notice, not recalled. */
export function messageTakesFocus(message: MessageLike): boolean {
  if (message.isRecalled) return false;
  const type = messageContentTypeForUi(message.content?.contentType ?? "text");
  return type !== "system" && type !== "notification";
}

/** Keys that move focus between the messages of a list. */
export const TIMELINE_FOCUS_KEYS: ReadonlySet<string> = new Set(["ArrowUp", "ArrowDown", "Home", "End"]);
