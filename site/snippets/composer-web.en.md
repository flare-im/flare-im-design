## Web component integration

The live preview uses the production `FlareComposer`: PC / App layouts, rich text, equal-width emoji / mention / voice panels, and normal / offline / muted states. The image button opens the native file chooser.

- `v-model` owns the draft; `rich-mode` and `toggle-rich-mode` control formatting.
- `conversation-key` resets recordings and panels on conversation changes. `active-panel` and `toggle-panel` control emoji, stickers and more.
- Place `FlareComposerEmojiStickerPanel` inside the `media-panel` slot with `show-send-button=false`.
- `read-only` blocks editing and sending; `send-blocked` keeps the draft editable. Supply a localized explanation using `status-hint`.
- `attach-actions` configures ordering, icons and `disabled / disabledReason`. An empty array means no actions. Pages contain eight actions.
- `more-search-visible / more-title-visible / more-close-visible` default to false.
- `send-voice-handler` receives the explicitly confirmed recording. Rejection retains the preview for retry. Sending voice preserves the text draft.

The cross-platform specification below is conceptual; use these properties for the Vue implementation.

