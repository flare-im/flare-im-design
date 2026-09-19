# Package Boundaries

The repository has four cohesive platform packages. General and IM ownership is logical until either layer has enough independent consumers and release needs to justify a physical split.

```text
foundation -> general-ui -> im-ui -> host application
```

| Layer | Owns | May depend on |
|---|---|---|
| Foundation | tokens, themes, icons, shared value contracts | nothing above it |
| General UI | controls, form fields, feedback, overlays, generic layout | Foundation |
| IM UI | conversation, message, composer, media, contact, call, profile, moments | Foundation, General UI |
| Host application | data adapters, navigation, networking, persistence, business rules | Any public library layer |

`spec/component-layers.json` assigns every public component to `general-ui` or `im-ui`. `tooling/check-package-boundaries.mjs` rejects missing assignments, stale entries, invalid dependency direction, and General UI source that imports IM or SDK concepts.

Current package paths are final:

- `packages/vue-im-ui`
- `packages/flutter-im-ui`
- `packages/android-im-ui`
- `packages/ios-im-ui`

There are no forwarding packages, platform parent directories, import aliases for prior paths, or product SDK dependencies. Public coordinates and entry points are documented in `PUBLIC_API.md`.
