---
title: TransferProgress
---

# TransferProgress

A presentational attachment upload/download component for Vue, Flutter, SwiftUI and Compose. The host SDK owns transfer execution, measured progress and available operations.

<div class="flare-demo flare-demo--stack"><TransferProgressDemo /></div>

<ComponentApi name="TransferProgress" />

| State | Permitted actions |
|---|---|
| queued | cancel |
| transferring | pause, cancel |
| paused | resume, cancel |
| failed | retry |
| completed | open |
| cancelled | retry |

Pass only supported actions with localized labels in `actionLabels`. Missing or blank labels hide the action. Native implementations also require a callback. Set `busy` before submitting an operation to disable repeated activation; the SDK must still enforce idempotency.

`progress` is a measured ratio from 0 to 1. Null or non-finite values mean unknown; zero remains a known zero. Only the completed state forces 100%. Completion of an attachment upload does not imply message delivery.

The demo uses local state only and never uploads a file. Its text is supplied by the host; use your application's localization for names, status descriptions and action labels. Controls have a minimum 48 logical-unit target and support multiline content.

See the [four-platform integration examples](/components/transfer-progress) and [component-system roadmap](/guide/im-component-system).
