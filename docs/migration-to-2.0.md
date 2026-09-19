# Migrating To 2.0

Status: candidate migration guide for 2.0.0-rc.1. Do not install or announce 2.0.0 until the release checklist is complete.

## Package Imports

Use `@flare-im/vue-ui`, `package:flare_im_ui/flare_im_ui.dart`, `com.flare.im.ui` and `import FlareIMUI`. The Swift artifact lives at `packages/ios-im-ui`; the monorepo root is not a Swift package. Relative package dependencies are appropriate for local development; importing implementation files is not.

## Actual Replacements

| Previous path / usage | Canonical replacement | Host responsibility |
| --- | --- | --- |
| App-owned message bubble and body styles | Public MessageBubble and MessageContentView | Convert SDK data, resolve media, handle intents |
| Vue EnhancedComposer implementation imports | Public FlareComposer | Bind draft and send/action events |
| Native/runtime handwritten voice body | FlareVoiceMessage / VoiceMessage / VoiceMessageView | Playback state, permission, actual media URL |
| Local chat-header primitives | ConversationHeader identity + action configuration | SDK presence and capability projection |
| Native body-level bubbles around TextMessage | MessageBubble wrapping message data | Do not add a second background, border, time or read state |
| Flutter example FlareThemeTokens static aliases | FlareColors.of(context) | Place the kit theme above the host screen |
| Text-only native fallbacks for poll/task/calendar/mini-app/announcement | Typed Flare*Content models dispatched by MessageContentView | Preserve full data; wire allowed business actions |
| Hand-built sticker URL decoding in a host | Public StickerMessage body | Resolve a URL/pack ID; resource and permission lifecycle |

These are observed RC/development paths, not invented historical package APIs.

## Message Chrome

Message row owns alignment/grouping. Content owns only the body. MessageMeta owns timestamp, delivery/read state, edited and ephemeral annotations. Reaction and MessageActions own their respective controls. Sticker/GIF/large emoji use external metadata. Image/video use the media presentation policy. Do not reproduce these rules in an SDK example.

Vue TextMessage uses the shared safe Markdown renderer (raw HTML disabled) and preserves emoji-pack display. A `linkClick` listener may take over navigation; otherwise a safe rendered link uses normal browser navigation.

## Poll And Link Cards

`FlareVoteOption.pct` is optional/nullable. Omission means unknown, not 0%. Vue `readOnly` renders non-button options; native callers omit `onSelect`.
Native LinkCardMessage accepts a leading `icon` and `descriptionMaxLines`; use null in Flutter/Swift or Int.MAX_VALUE in Compose for full announcement content.

## Composer And Header

Start with a draft and send handler. Add capabilities and action overrides only as needed. Resolve visibility, disabled state, order, label/icon overrides and custom intents through the public action configuration; do not grow app-local showFoo flags. Keep recording, filesystem, permission prompts, transport and retries in the host adapter.

## Themes

Read semantic colors from the current provider, not Light/Dark constants in leaf components. Six generated brand presets and custom colors share the same semantic contract. Keep density and breakpoints separate from brand choice.

## Verification

Run the package tests and the ownership/public-import gate on each consumer. Exercise send, reply, retry, image preview, media errors, offline restoration and large text. Run `npm run release:check` against the same candidate sources. Never upgrade only the metadata to make an incomplete migration appear Stable.

## Known Incomplete Migration

Native RichDoc, multi-image, quote/forward mapping, host media actions and residual local form/theme presentation still block the final freeze. This guide does not claim those paths are fully migrated.

