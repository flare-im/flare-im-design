# Native-platform demos (iOS / Android / Flutter) → IDE previews + Flutter example

User chose: **IDE previews + Flutter example** (over full gallery apps / doc screenshots).
The native equivalent of the web per-component demos — rendered in Xcode / Android Studio canvas,
all using the REAL components + mock data, compile-verified.

## Status: DONE ✅
- [x] **iOS** — `ios-im-ui/Sources/FlareIMUI/Previews.swift`: `#if DEBUG` + ~30 `PreviewProvider`
  structs covering all ~40 components (Avatar/TimeStamp/MessageStatus/EmptyState/Search/Input/Markdown,
  conversation row+list+details, contacts+profile+settings, all message bodies + bubble + list, composer
  parts + composer + rich input + action sheet, chat header, call views). `swift build` clean.
- [x] **Android** — `android-im-ui/src/main/kotlin/com/flare/im/ui/Previews.kt`: `@Preview @Composable`
  per component (same coverage). `:compileDebugKotlin` clean.
- [x] **Flutter** — `flutter-im-ui/example/` gallery app (`pubspec.yaml` + `lib/main.dart`): a scrolling
  gallery of every widget with mock data. `flutter analyze` → No issues found.

All render the REAL components + mock data (mirrors the web demos). Gotchas: iOS 16 → `PreviewProvider`
not `#Preview`; Kotlin `flareColors()` needs no theme wrapper; Flutter models are `FlareContact`/
`FlareGroupSummary` (prefixed, non-const) while `ConversationRowData`/`FlareMessageData` are const.

## Notes
- Real components only (same as the web demos); mock data built from each component's public init +
  the kit's data models (ConversationRowData, FlareMessageData(FlareTextContent), Contact, etc.).
