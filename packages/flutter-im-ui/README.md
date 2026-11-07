# flare_im_ui

Native Flutter implementation of the Flare IM component contract. Widgets receive host-owned presentation state and emit callbacks. The package owns no session, transport, persistence, navigation, or business authorization.

## Install

```bash
flutter pub add flare_im_ui
```

```dart
import 'package:flare_im_ui/flare_im_ui.dart';
```

The public entry point also exports `ComposerInlineTextField` and the
`RichComposerMarkdownSerializer` contract for SDK adapters that preserve rich
composer drafts. Applications must not import files below `lib/src`.

During monorepo development, use a path dependency pointing to `packages/flutter-im-ui`.

## Components

The package implements the General UI, IM UI, form, layout, media, contacts, call, profile, and pattern symbols declared in [`../../spec/components.json`](../../spec/components.json). The generated cross-platform symbol index is [`../../spec/public-export-map.json`](../../spec/public-export-map.json).

## Usage

```dart
FlareTheme(
  brand: FlareBrandTheme.ocean,
  child: Column(
    children: [
      Expanded(
        child: FlareMessageList(
          messages: timeline,
          currentUserId: currentUserId,
          onMessageLongPress: openMessageActions,
          onLoadOlder: loadOlder,
        ),
      ),
      FlareComposer(onSend: sendText),
    ],
  ),
)
```

Use `FlareTheme(colors: customColors, child: ...)` for a custom semantic theme. Build overrides from a built-in `FlareColors` value with `copyWith`; components never require raw palette values. `colors` alone holds in either brightness; add `darkColors` and each brightness takes its own, so a subtree that sets its own `Theme` follows it.

Group and contact details use small buttons with the shared minimum touch target. Settings rows render a compact switch and handle activation across the entire row. In `FlareComposer`, tapping outside the editor or opening a tool dismisses the keyboard. Emoji insertion preserves the draft and keeps the picker open until the user taps the editor or switches tools.

`FlareImagePreview.imageBuilder` and `FlareImagePreview.present(..., imageBuilder:)`
let a host resolve local files, authenticated media, or cached images while the
package continues to own the full-screen viewer, zoom gestures, and controls.

## Desktop message actions

`FlareMessageBubble` keeps its react, reply, and more controls beside the
message surface on pointer devices: incoming actions on the right, outgoing
on the left, with the shared small spacing between them. Pointer and keyboard
focus reveal the same controls; Tab traverses them and Enter or Space activates
the focused control with a visible focus ring. Card and media menus centre on
the content frame, with the timestamp and retry state remaining below it.
Hidden controls reserve their width so long
messages do not reflow on hover; narrow panes constrain the message rather
than clipping the controls. Touch devices continue to use the long-press sheet.
Secondary-click menus retain their click-position anchor and host-owned action
availability.

## Ownership

The package owns native rendering, focus, semantics, adaptive composition, and deterministic UI state projection. The host maps authoritative conversation/message data into package models and owns commands, media loading, permissions, and side effects.

## Develop

```bash
flutter pub get
flutter analyze
flutter test
dart pub publish --dry-run
```

Generated tokens live in `lib/src/tokens/flare_tokens.dart`. Edit `../../tokens/tokens.json` or `../../tokens/themes.json` and run the repository generator instead of editing that file.
