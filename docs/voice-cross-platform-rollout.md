# Inline voice rollout · 2026-09-09

Accepted contract: bare 20px icons, 44px mobile targets, compact row replaces input; explicit start/pause/resume/preview/send. Keyboard cancels and deletes capture, retains text. Conversation/lifecycle/permission changes release capture. Failed requests preserve clip for retry. Existing rich text and attachments remain functional.

Targets: Core Tauri/iOS/Flutter/Android; Social Web/Tauri/iOS/Flutter/Android. Shared Vue, SwiftUI, Compose and Flutter adapters now implement the inline voice row. SDK message creation/upload remains in each host. No server deployment or store signing requested this turn.

Progress and validation are recorded below as each platform completes.

## Integration matrix

| App | Implementation | Verification |
| --- | --- | --- |
| Core Tauri | Shared Vue composer, recording send handler, inline emoji slot, microphone usage description | Frontend typecheck/build and native `cargo check` passed |
| Core iOS | Shared SwiftUI inline voice adapter, native PCM capture, SDK upload/send | arm64 iOS Simulator build passed, signing disabled |
| Core Flutter | Shared Flutter capture row, safe area, SDK sendAudioByPath, Android microphone permission | Targeted analyzer passed; APK verification recorded below |
| Core Android | Shared Compose capture row, local WAV SDK message creation | `:app:compileDebugKotlin` passed |
| Social Web | Shared Vue voice handler, SDK byte upload; emoji insertion at cursor and sticker handler | Typecheck and production build passed |
| Social Tauri | Shared Vue voice handler, canonical `media.upload_bytes`, SDK audio/send, microphone usage description | Frontend build and native `cargo check` passed |
| Social iOS | Shared SwiftUI inline voice handler, Social SDK sendVoice | arm64 iOS Simulator build passed, signing disabled |
| Social Flutter | Shared Flutter capture row, Social SDK sendVoice, microphone declarations | Targeted analyzer passed; APK verification recorded below |
| Social Android | Shared Compose capture row, Social SDK sendVoice, local kit substitution | `:app:compileDebugKotlin` passed |

## Behavior and compatibility

- Permission is requested only after pressing the microphone. Returning to keyboard invalidates pending permission callbacks and discards the local recording.
- Pause/resume retains PCM content. WAV previews avoid concatenating independent compressed containers. Active recording is capped at 65 seconds; clips shorter than 250 ms cannot send.
- Keyboard and microphone icons use a 20-point visual size, with 44-point mobile hit areas and transparent button backgrounds. The outer composer boundary remains.
- Existing text drafts survive voice mode. Failure leaves the clip available for retry. On accepted send the SDK owns the source file lifetime so pending uploads are not broken by view teardown.
- Older hold-to-talk callbacks remain compatible for consumers that do not provide the new async voice handler. All nine listed hosts provide the new handler.
- Shared Flutter tests: 18 passed, including generated WAV header/length, pause/resume, retry after failure, late permission cancellation, and existing composer/media behaviors.

## Validation limits

Builds and synthetic recording tests do not establish physical microphone quality, Bluetooth routing, device interruption behavior, or end-to-end server delivery on every OS. No real contacts received test audio. No server deployment, App Store signing, or registry publication was performed for this rollout. Social Android uses the workspace kit by default; `-Pflare.usePublishedKit` opts back into its published dependency.

### Final Flutter build result

Both APK attempts reached Gradle dependency resolution, then failed on Google Maven / Maven Central TLS handshakes (`record_android` AGP 8.12.3 artifacts and `package_info_plus` Kotlin 2.2.0 artifacts). Retried using the installed OpenJDK and local cache; the required artifacts are not cached. APK packaging is therefore **not verified**. Do not interpret the passed Dart analysis/tests as a successful APK build. Core rich-text regression also passed (1 test).
