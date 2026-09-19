# SwiftUI snapshot runner

The active host snapshot uses SwiftUI `ImageRenderer` with fixed size, scale,
color scheme, and reduced motion. Run `swift test --filter VisualSnapshotTests`
from `packages/ios-im-ui`. Regenerate only after review with
`UPDATE_GOLDENS=1 swift test --filter VisualSnapshotTests`.

The baseline proves shared SwiftUI rendering on the package's macOS test host.
Pinned iOS simulator and physical VoiceOver/Dynamic Type checks remain
`MANUAL_REQUIRED`; host snapshots do not claim those device results.
