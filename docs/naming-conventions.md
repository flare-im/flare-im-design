# Naming Conventions

Semantic component names are cross-platform; file and declaration casing remain idiomatic.

| Concern | Rule | Example |
|---|---|---|
| Contract | PascalCase semantic name | `MessageStatus`, `ConversationRow` |
| Vue | `Flare`-prefixed PascalCase public export; PascalCase `.vue` | `FlareMessageStatus`, `FlareButton.vue` |
| Dart | `Flare`-prefixed PascalCase declaration; snake_case file | `FlareMessageStatus`, `flare_message_status.dart` |
| Kotlin | PascalCase declaration/file; package `com.flare.im.ui` | `MessageStatus`, `MessageStatus.kt` |
| Swift | PascalCase declaration/file, usually `View` suffix | `MessageStatusView`, `MessageStatusView.swift` |
| Tokens | lower camel JSON path; kebab CSS variable; lower camel native field | `messageStatus.read`, `--flare-color-message-status-read`, `messageStatusRead` |
| Events | host intent, not completed side effect | `retry`, `send`, `select`, `open` |
| Boolean | one canonical positive semantic | `loading`, not `loading` + `isLoading` + `showLoading` |

Platform aliases are registered in `spec/components.json#lexicon`; do not add silent per-platform synonyms. Product names, SDK type names, transport details, and business workflows cannot leak into General UI names.
