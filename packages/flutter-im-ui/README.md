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

Use `FlareTheme(colors: customColors, child: ...)` for a custom semantic theme. Build overrides from a built-in `FlareColors` value with `copyWith`; components never require raw palette values.

`FlareImagePreview.imageBuilder` and `FlareImagePreview.present(..., imageBuilder:)`
let a host resolve local files, authenticated media, or cached images while the
package continues to own the full-screen viewer, zoom gestures, and controls.

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
