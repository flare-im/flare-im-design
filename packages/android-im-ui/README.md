# flare-im-ui-compose

Native Jetpack Compose implementation of the Flare IM component contract. Composables receive host-owned presentation state and emit callbacks. The package owns no session, transport, persistence, navigation, or business authorization.

`IMAppKit` is the public adaptive application shell. Its primary pane is
optional for full-width workspaces, and `hideMobileNavigation` removes the
bottom bar while a phone-sized conversation route is open.

- Maven coordinates: `com.flare.im:im-ui-compose:2.0.0-rc.1`
- Namespace: `com.flare.im.ui`
- Minimum Android SDK: 26
- Compile SDK: 35
- JDK: 17

## Install

For repository development, include the self-contained package:

```kotlin
include(":im-ui-compose")
project(":im-ui-compose").projectDir = file("vendor/flare-im-design/packages/android-im-ui")
```

Published Maven metadata carries Compose dependencies. For a raw AAR workflow, follow [`../../docs/MANUAL-INSTALL-ANDROID-IOS.md`](../../docs/MANUAL-INSTALL-ANDROID-IOS.md).

```kotlin
import com.flare.im.ui.*
```

## Components

The package implements the General UI, IM UI, form, layout, media, contacts, call, profile, and pattern symbols declared in [`../../spec/components.json`](../../spec/components.json). The generated cross-platform symbol index is [`../../spec/public-export-map.json`](../../spec/public-export-map.json).

## Usage

```kotlin
FlareThemeProvider(brand = FlareBrandTheme.Ocean) {
    Column {
        MessageList(
            modifier = Modifier.weight(1f),
            messages = timeline,
            currentUserId = currentUserId,
            onMessageLongPress = ::openMessageActions,
        )
        Composer(onSend = ::sendText)
    }
}
```

Pass a custom `FlareColors` value to `FlareThemeProvider(colors = ...)` for semantic overrides. Components do not consume raw palette constants.

`FlareThemeProvider` also supplies the corresponding Material color scheme and
token-based typography. Page composition can read `MaterialTheme.typography`
without maintaining another app type scale. Pass the matching `dark` value for
custom color sets; the provider remains the theme owner.

## Ownership

The package owns native rendering, focus, semantics, adaptive composition, and deterministic UI state projection. The host maps authoritative conversation/message data into package models and owns commands, media loading, permissions, and side effects.

## Develop

```bash
./gradlew test lint assembleRelease
```

Generated tokens live in `src/main/kotlin/com/flare/im/ui/FlareTokens.kt`. Edit `../../tokens/tokens.json` or `../../tokens/themes.json` and run the repository generator instead of editing that file.
