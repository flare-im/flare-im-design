# Visual regression

The shared fixtures live in `examples/gallery/gallery-manifest.json`. A renderer must
apply the same scenario id, viewport, theme, text scale, direction, motion
preference, and content fixture before comparing pixels.

Flutter has an active deterministic golden. Vue, Compose, and SwiftUI keep an
explicit runner contract below; they remain `scaffolded` until a browser or
native snapshot dependency is accepted by the repository.
