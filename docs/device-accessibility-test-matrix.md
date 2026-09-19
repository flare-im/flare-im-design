# Device Accessibility Test Matrix

Automated semantics, focus, keyboard, reduced-motion, and layout checks are separate from these tests. A simulator result may support debugging but cannot change a physical-device row to `PASS`.

## A11Y-IOS-VOICEOVER

- Platform: iOS 16+; physical small or standard iPhone
- Device class: touch phone with VoiceOver
- Precondition: release candidate installed; English locale; VoiceOver enabled; seeded unread, failed, recalled, media, and thread messages
- Steps: 1. Open Conversation List. 2. Swipe to an unread conversation. 3. Activate it. 4. Swipe through sender, message content, MessageMeta, failed retry, reply, and thread controls. 5. Open and close the message action sheet. 6. Return to the list.
- Expected result: the unread row is announced as conversation name, unread state/count, latest message, and timestamp; decorative icons are skipped; failed status exposes one retry action; action-sheet order is stable; closing restores focus to the invoking message; no focus escapes behind the sheet.
- Evidence required: screen recording with audio, accessibility inspector capture, device/OS/build/locale, actual spoken sequence, result and tester
- Status: `MANUAL_REQUIRED`
- Failure severity: P1; P0 if sending, retry, or navigation becomes unreachable

## A11Y-ANDROID-TALKBACK

- Platform: Android 26+; physical small or standard phone
- Device class: touch phone with TalkBack
- Precondition: RC installed; TalkBack enabled; same seeded states as iOS
- Steps: 1. Open Conversation List. 2. Swipe to an unread row. 3. Activate chat. 4. Traverse message content, delivery state, retry, reply/thread, composer, attachment, and send. 5. Long-press a message and dismiss the action sheet. 6. Navigate back.
- Expected result: row name/unread/latest/timestamp are spoken once; role/state/action labels are present; decorative glyphs are silent; focus remains in the active sheet and returns to the message; back and send remain reachable.
- Evidence required: screen recording with TalkBack audio, Accessibility Scanner export, device/OS/build/locale, spoken sequence, result and tester
- Status: `MANUAL_REQUIRED`
- Failure severity: P1; P0 for unreachable primary actions or crash

## A11Y-IOS-LARGE-TEXT

- Platform: iOS 16+ physical iPhone and iPad
- Device class: small phone plus split-view tablet
- Precondition: Larger Accessibility Sizes set to 200%, then maximum; portrait and landscape
- Steps: 1. Visit conversation, chat, detail, search, settings, dialog, drawer/sheet, toast, and composer. 2. Open long translated labels and long filenames. 3. Type a multiline draft and open the keyboard. 4. Rotate once.
- Expected result: ConversationItem, MessageBubble/Meta, Composer, Form, Button/Input, dialogs and workbench reflow; critical text is not clipped into meaninglessness; controls stay reachable by scrolling; composer is not hidden by the keyboard; no off-screen confirmation action.
- Evidence required: screenshots at 200% and maximum for every workspace, device/OS/build, failures annotated with component and viewport
- Status: `MANUAL_REQUIRED`
- Failure severity: P1; P0 when a destructive confirmation or send/cancel action is unreachable

## A11Y-ANDROID-LARGE-TEXT

- Platform: Android 26+ physical phone/tablet
- Device class: small phone plus tablet
- Precondition: font size 200% or nearest OS step, display size default; repeat at maximum font size
- Steps: follow `A11Y-IOS-LARGE-TEXT`, including keyboard-open composer and orientation change.
- Expected result: identical task-level criteria; geometry may change, but content and actions remain scrollable and reachable without overlap.
- Evidence required: screenshots, device/OS/build/font scale, component-level notes and result
- Status: `MANUAL_REQUIRED`
- Failure severity: P1; P0 for blocked primary/destructive recovery actions

## A11Y-HIGH-CONTRAST

- Platform: iOS Increase Contrast, Android high-contrast text, Windows/browser forced colors
- Device class: one physical iOS device, one physical Android device, one desktop browser
- Precondition: dark and light theme fixtures; contrast feature enabled
- Steps: inspect MessageStatus, Error, Warning, Selected, Unread, Mention, Online, focus ring, input, dialog, tooltip, overlay and media controls; trigger failed/send/read states.
- Expected result: meaning never depends on hue alone; status has text/icon/shape/semantics as applicable; selected and focus remain distinguishable; disabled text remains readable; outgoing dark MessageDoubleCheck remains visible.
- Evidence required: paired screenshots, browser forced-colors trace, device settings capture, result and tester
- Status: `MANUAL_REQUIRED`
- Failure severity: P1

## A11Y-HARDWARE-KEYBOARD

- Platform: iPadOS, Android tablet, Vue PC, Flutter PC
- Device class: physical tablet keyboard plus desktop
- Precondition: keyboard connected; command fixture enabled; one modal and one context menu available
- Steps: 1. Traverse with Tab and Shift+Tab. 2. Activate controls with Enter/Space. 3. Open search and command palette with documented shortcuts. 4. Navigate conversations with arrows. 5. Send/newline, copy, reply, details and close overlay. 6. Close the modal with Escape and continue tabbing.
- Expected result: visible focus never disappears; modal traps focus; initial focus is deterministic; context menu is keyboard reachable; Escape restores focus to invoker; IME composition does not submit; no duplicate command handling.
- Evidence required: screen recording with keystroke overlay, focus sequence, device/OS/build/layout, result and tester
- Status: `MANUAL_REQUIRED`
- Failure severity: P1; P0 if keyboard-only users cannot send, cancel, or escape

## A11Y-REDUCED-MOTION

- Platform: physical iOS and Android; Vue and Flutter desktop
- Device class: phone and desktop
- Precondition: Reduce Motion/remove animations enabled before app launch
- Steps: open loading skeleton, sending/retrying status, dialog, drawer, context sheet, viewer, pane resize and conversation switch.
- Expected result: information remains available without continuous motion; loading/sending state has semantic text; overlays and navigation do not depend on animation completion; no flashing or forced parallax.
- Evidence required: video, platform setting capture, state list, result and tester
- Status: `MANUAL_REQUIRED`
- Failure severity: P1

## Result Record

For every ID record `device`, `OS`, `build SHA`, `locale`, `text scale`, `theme`, `expected`, `actual`, `evidence URI`, `tester`, `date`, and `PASS/FAIL/BLOCKED`. Stable requires real results for VoiceOver, TalkBack, both large-text rows, hardware keyboard, and representative gestures.
