# Examples

Flare UI provides two kinds of examples with different responsibilities.

## Component Examples

Component Catalog previews use in-memory state and static fixtures to inspect one component's API, states, themes, responsive behavior, and accessibility. They do not initialize the Flare SDK and are not full product assemblies.

- [Component Catalog](/en/components/)
- [Build an IM App](/en/app-kit/)
- [Customization](/en/customization/)

## Real SDK Reference Applications

These applications live in `flare-im-core-client-sdk`. They retain real SDK initialization, authentication, event subscriptions, synchronization, send/retry, media, lifecycle, and platform bridges while composing UI only through public design-package APIs.

These reference apps focus on conversations and messages. They do not expose contact-directory, group-directory, or relationship-graph entry points; group conversations may still appear as messaging targets.

- [Web / Vue](https://github.com/flare-im/flare-im-core-client-sdk/tree/main/examples/flare-core-web-app)
- [Tauri / Vue](https://github.com/flare-im/flare-im-core-client-sdk/tree/main/examples/flare-core-tauri-app)
- [Flutter](https://github.com/flare-im/flare-im-core-client-sdk/tree/main/examples/flare-core-flutter-app)
- [Android / Jetpack Compose](https://github.com/flare-im/flare-im-core-client-sdk/tree/main/examples/flare-core-android-app)
- [iOS / SwiftUI](https://github.com/flare-im/flare-im-core-client-sdk/tree/main/examples/flare-core-ios-app)

Use component examples for visual/API inspection. Use reference applications for real SDK assembly, state flow, and platform integration.
