# Flutter image upload slot

`FlareImageUploadSlot` is a controlled, presentational form component. Its states
match the other kits: `empty`, `selected`, `uploading`, `uploaded`, and `failed`.
It owns no file picker, transport, storage, authorization, or document policy.

- `title` and `statusText` name the material and its current state.
- `pickLabel` / `onChoose` describe the image-region intent.
- `actionLabel` / `onAction` optionally provide an explicit upload or retry.
- `preview` accepts a host-owned widget. A host may supply a current-session
  `Image.memory`; the slot never fetches a private URL or retains image bytes.
- `disabled` prevents both intents. Uploading and uploaded states are inert even
  when callbacks remain supplied. Completed private files without a local image
  show an uploaded placeholder; no replace/remove action is invented.

Hosts put the format/size guidance once above the group, then compose a responsive
grid. The realname composition uses three columns from 600 logical pixels, two
from 320, and one on narrower layouts or enlarged text. The page limits its
content width using the shared directory token. Those breakpoints describe the
available content width, after page padding.

The image region is keyboard reachable and exceeds the 44-pixel minimum target.
The optional action uses the compact kit button with its full touch target.
Status colors use semantic theme tokens, transfers expose an indeterminate
progress indicator until the host has authoritative numeric progress, and
screen-reader labels include the title, state, and available choose intent.

The Flutter realname screen continues to use the SDK's existing automatic upload
after picking. A failed local selection retains its existing choose-again and
retry intents. The SDK owns idempotency, command recovery and all state changes.
