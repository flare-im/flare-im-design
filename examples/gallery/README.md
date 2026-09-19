# Cross-platform Gallery

The gallery matrix in `gallery-manifest.json` names public spec components only. Scenario data has one source of truth: `spec/scenarios/rc.json`. Vue uses the VitePress component site, Flutter uses the runnable package example, Compose uses Android Studio previews, and SwiftUI uses Xcode previews.

Every comparison pass covers default, hover/pressed where available, focus, disabled, loading, long content, dark mode, large text, and reduced motion. Platform-native interaction differences are expected; component semantics, state meaning, hierarchy, tokens, and recovery actions are compared.

`Drawer`, `Progress`, and generic `List` currently use stable public capabilities (`MasterDetailLayout.overlay`, `TransferProgress`, and `ConversationList`) while dedicated General UI contracts remain planned. The aliases are explicit so a future extraction can replace them without inventing demo-only widgets.

Run `node tooling/check-gallery.mjs` to verify that every fixture points to a real public component and that all platform gallery sources and state dimensions remain present.
