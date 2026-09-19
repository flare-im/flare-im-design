# Recipe: Build Mobile Chat Navigation

On a phone the app shows one thing at a time: the inbox, a conversation, or its details. Back always goes one step up. On wider screens the same content sits side by side. This recipe follows the golden reference app (`flare-social-web-app/src/views/MainView.vue`), the kit's reference app (`examples/vue/src/App.vue`), and the Android reference for system back.

## Components

| Region | Vue | Flutter | iOS | Compose |
|---|---|---|---|---|
| Shell: navigation and destinations | `FlareIMAppKit` `destination` slot | `FlareIMAppKit` `destinationBuilder` | `IMAppKitView` `destination` | `IMAppKit` `destination` |
| A destination's panes, phone single pane | `FlareAppLayout` | `FlareAppLayout` | `AppLayoutView` | `AppLayout` |
| Back in the chat header | `FlareConversationHeader` `show-back` | `FlareConversationHeader` | `ConversationHeaderView` `showBack` | `ConversationHeader` `showBack` |
| Open details from the header | identity `action` (the avatar, title and subtitle are one button) | identity `action` | identity `action` | identity `action` |
| Secondary panels on wide screens | `FlareBottomSheet` / `FlareFormSheet`: a sheet on phones, a dialog on pointer devices, `presentation="drawer"` for long panels | `FlareBottomSheet.show`, `FlareDialog.show` | `flareBottomSheet(item:)` | `BottomSheet` |
| Back on secondary pages | `FlareScreen` `back` | `FlareScreen` | `FlareScreen` | `FlareScreen` `onBack` |
| A host-drawn secondary page hides the tab bar | `useFlareDestinationDepth(active)` | `FlareDestinationDepth` | `.flareDestinationDepth(_:)` | `FlareDestinationDepth(active)` |

## A destination owns its panes (Vue)

The shell measures its own box, renders one destination per navigation item and keeps a visited one alive. The messages destination arranges its own panes with `FlareAppLayout`; the other tabs are whatever they are. This is the golden app's `MainView.vue`:

```vue
<script setup lang="ts">
import { computed, ref } from "vue";
import { FlareAppLayout, FlareIMAppKit, type FlareLayoutChange, type FlareWorkspacePane } from "@flare-im/vue-ui";

const tab = ref<"chats" | "contacts" | "moments" | "me">("chats");
const activePane = ref<"list" | "chat" | "detail">("list");

// Phone shows one pane of the messages destination; the layout picks it from the same slots the wide layout uses.
const chatsPane = computed<FlareWorkspacePane>(() =>
  activePane.value === "list" ? "primary" : activePane.value === "detail" ? "detail" : "content");

// The chat header shows back only while the layout is actually showing one pane.
const singlePane = ref(false);
function onLayoutChange(layout: FlareLayoutChange) {
  singlePane.value = layout.paneMode === "singlePane";
}
</script>

<template>
  <FlareIMAppKit :configuration="configuration" :active-navigation-id="tab" @navigate="tab = $event">
    <template #destination="{ id, active }">
      <FlareAppLayout
        v-if="id === 'chats'"
        :pane-mode="hasDetail ? 'triplePane' : 'dualPane'"
        :detail-mode="hasDetail ? 'inline' : 'hidden'"
        :has-detail="hasDetail"
        :active-pane="chatsPane"
        @layout-change="onLayoutChange"
      >
        <template #primary><ConversationPane @select="openConversation" /></template>
        <template #content>
          <ChatArea :show-back="singlePane" @back="activePane = 'list'" @open-settings="activePane = 'detail'" />
        </template>
        <template #detail><GroupDetailPanel v-if="hasDetail" :group-id="chatGroupId" @back="activePane = 'chat'" /></template>
      </FlareAppLayout>
      <ContactsTab v-else-if="id === 'contacts'" />
      <MomentsTab v-else-if="id === 'moments'" :active="active" />
      <MeTab v-else />
    </template>
  </FlareIMAppKit>
</template>
```

There is no mode to pass and no tab bar to hide by hand: the shell measured its box, and a single-pane `FlareAppLayout` showing a pane other than the list reports the depth that hides the phone tab bar. Leaving the chat reports it gone.

## Width behaviour

| Mode | List | Conversation | Details | Navigation |
|---|---|---|---|---|
| Mobile | Full page when the active pane is `primary` | Full page, back in the header | Full page when `hasDetail` | Bottom tabs, hidden while a destination reports depth |
| Tablet | Left pane | Main pane | Overlay | Rail |
| Desktop | Left pane | Main pane | Third pane when it fits, overlay otherwise | Rail |

How many panes fit is one rule on four kits (`resolvePaneMode`): navigation + list + a 360 px chat times the text scale, plus the detail for three.

## System back (Android)

Compose kit surfaces that show a back control also honour the system back gesture: `FlareScreen` with `onBack`, `ConversationHeader` with `showBack`, and `FlareGroupDetail` with `onBack`. The innermost visible one wins, and a surface without a back control leaves back to the host. Route state stays in the app:

```kotlin
val route: (@Composable () -> Unit)? = when {
    openGroupId != null -> ({ GroupDetailScreen(session, openGroupId!!, onBack = { openGroupId = null }) })
    showSearch -> ({ SearchScreen(session, onBack = { showSearch = false }) })
    else -> null
}
// ChatScreen: ConversationHeader(showBack = true, onBack = { openId = null })
```

The host must declare `nativeBack` in its platform capabilities (the Android default does).

## Browser back (web)

On a phone browser, back closes the open layer before it leaves the page. Vue kit layers register with the platform back while they are open and the host handles their close: `FlareConversationHeader` with `show-back` and a `back` listener, `FlareScreen` with `back`, `FlareBottomSheet` and the sheets built on it, the message action sheet, image and video previews, the merged-forward view and danger confirmations. The layer opened last closes first. Opt in once; the web adapter keeps one marked history entry while a layer is open:

```vue
<script setup lang="ts">
import { FlareUiProvider, createWebPlatformAdapter, type FlarePlatformOptions } from "@flare-im/vue-ui";
const platform: FlarePlatformOptions = { adapter: createWebPlatformAdapter({ historyBack: true }) };
</script>

<template>
  <FlareUiProvider :platform="platform"><RouterView /></FlareUiProvider>
</template>
```

An app overlay that is not a kit layer registers itself with `useFlareNativeBack(active, onBack)`; `active` must be false whenever the overlay is off screen (the web app's global search: `useFlareNativeBack(true, () => emit("close"))`, mounted only while open).

## States

| State | Behaviour |
|---|---|
| Open a conversation from another tab | Switch to the chats tab, set the conversation pane, open the conversation |
| Details for a direct chat without a peer id | Stay on the conversation; `hasDetail` is false |
| Rotate or resize across a breakpoint | Same state, new presentation: the open conversation stays open |
| Switch tabs and come back | The destination is where it was, scroll position included; the shell keeps a visited destination alive |

## Do and don't

- Don't render a second copy of a pane for phone. Set `active-pane` on the destination's `FlareAppLayout`.
- Don't measure the window or keep tabs alive yourself; the shell does both.
- Don't add a separate back bar above the chat header on phone.
- Don't listen to `popstate` for overlays; register them with `useFlareNativeBack` so the innermost layer closes first.
- On wide panes, give full pages (我, 设置, 圈子, 通讯录) `FlareScreen` `readable` so content stays in a 720 px column.
- Don't open conversation details from a separate icon only; set the header identity `action` so the avatar and title open them.
- Don't hide navigation by hand. A secondary page the kit does not draw registers its depth (`useFlareDestinationDepth`).
