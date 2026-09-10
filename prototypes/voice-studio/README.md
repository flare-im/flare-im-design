# Voice composer prototype

Run `python3 -m http.server 4182` in this directory.

Prototype only: no microphone capture, server messaging or production changes. Playback uses a quiet synthesized tone to demonstrate play/pause/progress.

Design: 106–112px desktop voice strip anchored to composer, 42px primary control, 20px glyphs, muted chromatic waveform; purple confirms actions and coral indicates recording. System UI font for labels and monospaced timer. Light and dark tokens preserve existing Flare visual language.

States: idle → recording → ready → playing/paused → sending → local delivered. Collapse stops recording and retains it as a voice draft. Delete asks inline confirmation. Offline blocks sending while keeping the draft. Permission denied is recoverable via scenario selector. Failed first send preserves audio; retry succeeds in the demo. Text draft is independent. Max 120 seconds, min 1 second.

Production follow-up after design approval: map to MediaRecorder, real waveform, microphone permissions, stream cleanup, device interruption, background handling, upload cancellation and SDK send/retry states. Mobile uses the same explicit start/stop interaction; press-and-hold can be added as an optional shortcut, not a required gesture.
