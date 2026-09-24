# Recipe: Build Message Actions

Long-press or right-click a message to react, reply, forward, copy, recall or delete. Actions follow two rules. The core decides what a message allows. The screen offers only what it implements. Recipes here come from all five reference apps.

## Components

| Surface | Vue | Flutter | iOS | Compose |
|---|---|---|---|---|
| Menu, hover toolbar and reaction picker | built into `FlareMessageList` | — | — | — |
| Long-press action sheet | `FlareMessageActionSheet` (phones, built in) | `FlareMessageActionSheet.show` | `MessageActionSheetView` in `.sheet` | `MessageActionSheet` in `Dialog` |
| Reaction pills under the bubble | built into the bubble | built into the bubble (`onReact`) | built into the bubble (`onReact`) | built into the bubble (`onReact`) |
| App actions (report, translate) | `actions` plus `@action` on `FlareMessageList` | `actions` on the sheet | `actions` on the sheet | `actions` on the sheet |
| Destructive confirmation | `useFlareConfirm` | `FlareDangerConfirm.show` | `DangerConfirmView` | `DangerConfirm` |
| Forward target picker | `FlareForwardPicker` | `FlareForwardPicker` | `ForwardPickerView` | `ForwardPicker` |

## Vue: attach the intents you implement

`FlareMessageList` builds the menu, the hover toolbar, the reaction picker and the reaction pills. Every control whose intent has no listener is left out, so the listeners are the configuration.

```vue
<script setup lang="ts">
import { FlareMessageList, findMessage, useFlareConfirm, useFlareToast, type MessageMenuExtension } from "@flare-im/vue-ui";

const confirm = useFlareConfirm();
const toast = useFlareToast();

// App actions join the kit menu: ordinary ones before Delete, destructive ones after it.
const actions: MessageMenuExtension[] = [
  { id: "report", label: "举报", icon: "warning", destructive: true, available: (ctx) => !ctx.isSelf },
];
function onAction(actionId: string, kitId: string) {
  if (actionId === "report") openReportFor(findMessage(messages.value, kitId));
}
function onCopy(_kitId: string, copied: boolean) {
  toast(copied ? { message: "已复制", tone: "success" } : { message: "复制失败，请手动选择文字", tone: "danger" });
}

function onReact(kitId: string, emoji: string) {
  // Toggle: remove when the current user already reacted with this emoji, add otherwise.
  void reactTo(coreMessageId(kitId), emoji);
}
function onRecall(kitId: string) {
  void confirm({
    title: "撤回消息",
    description: "撤回后对方将看不到这条消息。",
    target: previewOf(findMessage(messages.value, kitId)),
    confirmText: "撤回",
    action: () => recallMessage(coreMessageId(kitId)),
  });
}
</script>

<template>
  <FlareMessageList
    :messages="messages"
    :current-user-id="uid"
    :conversation-id="convId"
    :has-older="hasOlder"
    :actions="actions"
    @react="onReact"
    @reply="onReply"
    @edit="onEdit"
    @recall="onRecall"
    @delete="onDelete"
    @resend="resendMessage"
    @action="onAction"
    @copy="onCopy"
  />
</template>
```

This screen attaches no forward, pin or multi-select listener, so those controls never appear. `icon` on an app action is a semantic Flare icon name (`warning`, `language`, ...); the same menu is a dropdown on desktop (right-click or the hover toolbar's More) and a bottom sheet on phones.

## Vue: forward, multi-select, pin and download

The web app wires the rest of the menu this way (`flare-social-web-app` `ChatArea.vue` and `social/store.ts`):

- **Forward** (`@forward`) opens `FlareForwardPicker` (embedded in a `FlareFormSheet`) over existing conversations. A merged forward is one `message_builder.create_forward` with `merge: true` and every source; forwarding each message sends one `create_forward` per source and target, because the core rejects several sources with `merge: false`. Then `message.send`. Failed targets stay selected with a toast; sent ones are not sent again.
- **Multi-select** (`@multi-select`, `@toggle-select`) sets `multi-select-mode` and shows `FlareMessageBatchToolbar` with select all, forward each, forward merged and delete; delete confirms first. Escape, the platform back and the first press of a kit back control (ConversationHeader, FlareScreen) leave selection — the toolbar owns those while it is mounted with `@exit`, so the host wires nothing but `@exit`. Select controls are named checkboxes.
- **Pin** (`@pin` with the message id and whether to pin) calls `message.pin_by_message_id` / `unpin_by_message_id`, and `FlarePinnedMessageBar` lists pinned messages above the timeline. The core has no pinned-list op and the local pin has no scope (SDK gap S20), so the app passes `messageMenu.actions.pinSelf: false`.
- **Download** handles the bubble's media action: resolve the media URL through the core and call `downloadUrlWithFileName(href, name)`. An address the page cannot fetch opens in a new tab instead of navigating the app away; only a refused address returns false. With a download handler the image preview shows a download button too.

## Native: the core's availability, the kit sheet, your wiring

```kotlin
// Android (flare-social-android-app ChatScreen.kt)
private val unwiredMessageActions = setOf("reply", "resend", "multiSelect", "mark", "pin", "pinSelf", "unpin", "preview", "save", "edit")

onMessageLongPress = { msg -> scope.launch { actionTarget = msg to session.actionAvailability(msg) } },
onReact = { msg, emoji -> scope.launch { if (session.toggleReaction(msg, emoji)) reload() } },

actionTarget?.let { (msg, availability) ->
    Dialog(onDismissRequest = { actionTarget = null }) {
        MessageActionSheet(
            availability = availability,            // core: message.action_availability
            hiddenActions = unwiredMessageActions,  // standard actions this screen does not implement
            onReact = { emoji -> actionTarget = null; scope.launch { if (session.toggleReaction(msg, emoji)) reload() } },
            onAction = { id ->
                actionTarget = null
                when (id) {
                    "forward" -> forwardTarget = msg
                    "copy" -> (msg.content as? FlareTextContent)?.let { clipboard.setText(AnnotatedString(it.text)) }
                    "recall", "delete" -> confirmTarget = PendingMessageAction(id, msg)
                }
            },
        )
    }
}
```

`actionAvailability` calls `message.action_availability` with `{ messageId, multiSelectMode, isPending, isFailed, isPinned, isConnected }` and reads the result with `FlareMessageActionAvailability.fromJson`. iOS (`SocialSession.actionAvailability`, `FlareMessageActionAvailability(json:)`) and Flutter (`BaseSocialClient.actionAvailability`) do the same.

## Rules

- **The core decides capability.** No hand-written "recall on my own messages" rules.
- **Hide what is not wired:** `hiddenActions` on native sheets, missing listeners on Vue.
- **Reactions toggle:** the strip, the picker and the pills all remove your reaction when you already chose it.
- **The strip follows `canReact`**, so pending, failed and recalled messages get none.
- **Recall and delete confirm**, and the confirmation shows the message text as its target.
- **Recalled messages take no actions:** the kit draws a notice with no long-press and no swipe-reply.
- **Multi-select taps select.** Reaction pills do not toggle while selecting.

## States

| State | Behaviour |
|---|---|
| Availability read fails | Sheet opens with nothing to offer, never with guessed actions |
| Action fails | Confirmation stays open with the error and retry (recall and delete); other actions show a failure toast |
| Forward partly fails | Toast says how many conversations received it; only the failed conversations stay selected for a retry |
| Copy | Vue writes the clipboard and emits `copy` with whether it worked, so the app can confirm or explain a refusal; native apps copy in their `onAction` handler |
