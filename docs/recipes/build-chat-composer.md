# Recipe: Build the Chat Composer

The composer writes and sends: text, replies, edits, emoji and stickers, attachments and voice. This recipe follows the golden reference app (`flare-social-web-app/src/components/ChatArea.vue`), with the Flutter reference (`flare-social-flutter-app/lib/screens/chat_screen.dart`) for sends that report their result.

## Components

| Region | Vue | Flutter | iOS | Compose |
|---|---|---|---|---|
| Composer (input, send, reply and edit strips, attach, voice) | `FlareComposer` | `FlareComposer` | `ComposerView` | `Composer` |
| Emoji and sticker picker | `FlareEmojiStickerPicker` in `#media-panel` | `FlareEmojiStickerPicker` under the composer | `FlareEmojiStickerPicker` in a sheet | `FlareEmojiStickerPicker` under the composer |
| Reply strip (inside the composer) | `FlareComposerReplyStrip` | `FlareComposerReplyStrip` | `FlareComposerReplyStrip` | `FlareComposerReplyStrip` |

## Composition (Vue)

```vue
<script setup lang="ts">
import { ref } from "vue";
import { FlareComposer, FlareEmojiStickerPicker, type FlareComposerCapabilities } from "@flare-im/vue-ui";

const draft = ref("");
const panel = ref<"emoji" | "sticker" | "more" | null>(null);
const composer = ref<{ insertAtCursor(text: string): void } | null>(null);
// Keep the kit's attach tiles and pick the ids this app sends (a host `actions` list replaces the defaults instead).
const attachCapabilities: FlareComposerCapabilities = { availableActionIds: ["image", "file"] };

// The picker reports an emoji pack key; the app turns it into its text token and inserts it at the caret.
function insertEmoji(key: string) {
  composer.value?.insertAtCursor(emojiPackToken(key));
}

function onSend(text: string) {
  const body = text.trim();
  if (!body) return;
  if (editTarget.value) void editMessage(coreMessageId(editTarget.value.id), body);
  else if (replyTarget.value) void replyText(coreMessageId(replyTarget.value.id), body);
  // A rich send that fails before the message exists gives the text back.
  else if (sendAsRich.value) void sendRich(body).catch(() => { draft.value = body; });
  else void sendText(body);
  draft.value = "";
}
</script>

<template>
  <FlareComposer
    ref="composer"
    v-model="draft"
    v-model:send-as-rich-doc="sendAsRich"
    :conversation-key="uid + convId"
    :send-voice-handler="sendVoiceRecording"
    :active-panel="panel"
    :target-name="activeHeader.title"
    :capabilities="attachCapabilities"
    :reply-sender="replyTarget?.sender"
    :reply-preview="replyTarget?.preview"
    :editing="Boolean(editTarget)"
    placeholder="输入消息…"
    @toggle-panel="panel = $event"
    @send="onSend"
    @build="onBuild"
    @clear-reply="replyTarget = null"
    @clear-edit="editTarget = null"
  >
    <template #media-panel>
      <FlareEmojiStickerPicker
        v-if="panel === 'emoji' || panel === 'sticker'"
        :active-tab="panel"
        :show-send-button="false"
        @update:active-tab="panel = $event"
        @insert-emoji="insertEmoji"
        @send-sticker="($event.picks[0] && sendSticker($event.picks[0]))"
      />
    </template>
  </FlareComposer>
</template>
```

The `#media-panel` slot is the emoji and sticker panel: the composer shows it whenever the active panel is `emoji` or `sticker`, whether the panel state is controlled (`active-panel` plus `@toggle-panel`) or left to the composer. An earlier extra visibility flag was why the picker never opened in two reference apps (friction FR-011); it no longer exists.

## Sends that report their result (Flutter)

`onSend` returns whether the send worked. The composer shows the send control busy while the future runs, clears the text and the reply strip only on `true`, and keeps the text on `false` or an error:

```dart
FlareComposer(
  onSend: (text) => widget.client.sendText(widget.conversation.id, text),
  mentionCandidates: isGroup ? members : const [],
  capabilities: const FlareComposerCapabilities(availableActionIds: {'image'}),
  /* … */
)
```

Compose hoists the text with `value` and `onValueChange` (the app keeps a draft per conversation); iOS takes `text:` as a binding.

## States

| State | Behaviour |
|---|---|
| Reply | Reply strip with sender and preview; clearing it returns to a plain send |
| Edit | Editing strip and prefilled text; send edits instead of sending |
| Switching conversations | `conversation-key` resets panels and strips; the app saves the draft of the conversation it leaves through the core (`conversation.update_draft`), restores the next one's, and clears reply and edit targets |
| Typing | `user-input` fires only for the user's own edits (not for a restored draft or the clear after send); send the typing signal from it and let the core throttle |
| Format mode | Send a normalised document: `rich_doc_v2.normalize_from_markdown` with the Markdown, then `message_builder.create_rich_doc` with its `docJson`, `contentSchema`, `plainText` and the other fields it returns. A `{ markdown }` request fails on the real core (SDK gap S19); a failed normalise or create is a failed send |
| Upload in progress | Bubble shows progress from the message's `localState` |
| Send failed before the message exists | Text returns to the composer, with a failure toast |
| Voice | Offered only with `send-voice-handler` (or a `send-voice` listener); the microphone then sits in the toolbar and the "+" grid |

## Do and don't

- Do offer only attachments the app sends: `capabilities.availableActionIds` keeps the kit tiles; a full `actions` list replaces them, and an action without an icon keeps the kit glyph of its id.
- Don't clear the composer yourself before a send that can fail synchronously. Rely on the optimistic clear plus restore.
- For group chats, pass the members as `mention-candidates` (the web app loads them per group). Typing "@" at the start of a word then opens the member picker (arrow keys and Enter pick; an IME Enter does not), and the pick replaces the "@" with the member's display name. Send the text as it is: `message_builder.create_text` resolves `@display name` and `@全员` against the roster, so don't build mention entities in the app. Known gap S14: the core currently keeps a mention only where the literal `@userId` appears, so a member picked by name gets no highlight and no @me until the core fix lands; @全员 works. Direct chats pass no roster, so "@" stays plain text. Flutter, SwiftUI and Compose take `mentionCandidates`.
