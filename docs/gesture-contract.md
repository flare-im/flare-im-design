# Gesture Contract

Gesture behavior is a platform adapter over typed message/conversation actions. It does not create new IM semantics.

| Surface | Gesture | Result | Conflict rule | Fallback |
|---|---|---|---|---|
| Message | long press | Open available message actions | Native long-press recognition must not block vertical scrolling before recognition | Keyboard/context-menu action |
| Message | horizontal swipe | Reply only when host exposes reply | Native touch slop and direction lock; vertical movement wins message-list scrolling | Reply action in sheet |
| Conversation | swipe action | Platform-supported pin/mute/archive/read action | One row open at a time; list vertical scroll wins before horizontal lock | Action sheet/context menu |
| Conversation | long press | Open typed conversation actions | No action unavailable by capability may appear | Keyboard/context menu |
| Media viewer | pinch | Native zoom within media bounds | Viewer owns multi-touch only after pinch begins | Zoom controls where provided |
| Media viewer | horizontal swipe | Move between media | Disabled while zoomed content is panned | Previous/next controls |
| Media viewer | dismiss/back | Close viewer and restore origin | System back wins at edge; unsaved/destructive work requires confirmation | Close button/Escape |
| Composer | keyboard avoidance | Keep draft and primary controls visible | Insets resize/scroll content; never translate controls outside safe area | Scroll-to-field |
| Voice composer | hold/slide where supported | Record/cancel/lock according to platform affordance | Cancellation is visually and semantically announced; list scrolling is disabled only during captured recording | Explicit record/cancel buttons |

The contract intentionally does not freeze a pixel threshold. Flutter, Compose, and SwiftUI use each platform's native touch slop and system-back arbitration.

## Manual Cases

- `GEST-MESSAGE-REPLY`: start a mostly vertical drag on a message, then a horizontal drag; only the latter may reveal reply and it must not accidentally send.
- `GEST-CONVERSATION-ACTIONS`: open one swipe row, scroll, then open another; no stale action layer may remain.
- `GEST-VIEWER-ZOOM-BACK`: pinch, pan, swipe, then use system back/edge gesture; zoom and dismiss must not fight.
- `GEST-COMPOSER-KEYBOARD`: focus the last multiline line, rotate, attach media, and dismiss keyboard; draft and send/cancel stay reachable.
- `GEST-VOICE-CANCEL`: begin recording, cross the platform cancel affordance, release, background the app, and return; no clip is sent and resources are released.

Each case requires a physical-device video, input method, OS/build, expected/actual result, and tester. Simulator execution is diagnostic evidence only.
