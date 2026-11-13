# FullScreen

iOS `FullScreenView` with `.flareFullScreen`. Vue, Flutter and Compose have no kit counterpart yet; their hosts present a full-screen task with the platform's own route (a Flutter page route, a Compose full-screen dialog, a Vue page).

## Overview
A layer that takes the whole screen for a task the user finishes or leaves there. The content owns its chrome; the kit draws the ground under the whole screen, keeps the content in the safe area, fades it in and out, and keeps the layer in the feedback stack like the other overlays.

## When to use
A camera viewfinder, a document capture (`FlareDocumentCapture`), a media viewer: content that needs every pixel and brings its own cancel or close button.

## When not to use
Do not use it for a short task (use BottomSheet `auto`), for a focused form (use Modal), for secondary content beside the page (use Drawer), or for a real navigation destination (use a page).

## Anatomy
Ground (`colors.bgPrimary`, or `colors.mediaStage` with `ground: .stage`) under the whole screen, safe areas included; the content inside the safe area. No scrim, no header and no close button: the content draws its own.

## Variants
`ground` `.surface` (default) or `.stage`. `isPresented` and `item` forms, like the other presenters.

## States
Closed, open. `dismissible: false`, or content raising `flareLayerDismissDisabled(true)`, keeps Escape and the escape gesture from closing it, for example while a photo is being processed.

## Interactions
The content closes the layer by setting `isPresented` to false (or `item` to nil) or by calling `dismiss()`; `onDismiss` runs once it is gone. Escape and the VoiceOver escape gesture close it while it is dismissible. There is no scrim to tap and no swipe down.

## Accessibility
A modal container named by `label`, else the kit's modal name (`FlareStrings.modalLabel`); the escape action closes it. Reduced motion shows and hides it at once.

## Platform differences
iOS 16.4+ presents it over a clear full-screen cover with the kit-drawn ground; earlier iOS and macOS fall back to a system sheet, as Modal and Drawer do. `FlareFeedback` toasts show above it and confirmations wait until it is gone.

## Code examples
```swift
.flareFullScreen(item: $captureRequest, label: FlareDocumentCapture.sideLabel(strings, side)) { request in
    DocumentCaptureScreen(request: request) { captureRequest = nil }
}
```

## Do / Don't
Do name every full-screen layer and give its content a visible way out. Don't use a raw `fullScreenCover` in an app: overlays go through the kit presenters, which the example apps' kit-reference check enforces.
