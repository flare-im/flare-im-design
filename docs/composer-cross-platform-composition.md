# Composer Cross-Platform Composition

The four platform implementations share one presentation contract:

| Platform | Public component |
|---|---|
| Vue | `FlareComposer` |
| Flutter | `FlareComposer` |
| Android Compose | `FlareComposer` |
| SwiftUI | `FlareComposer` |

The component owns layout, focus affordances, editor state presentation, action panels, reply/edit strips, recording UI, disabled states, and themed controls. The host owns drafts across conversations, upload and send execution, permissions, file pickers, capability policy, persistence, and retry side effects.

The shared action contract uses typed action IDs. A host may remove unavailable actions but must not add a control that cannot complete. Disabled, offline, permission-denied, upload, and error states require a visible reason and a bounded recovery path.

Mobile controls have at least 44 logical-pixel targets; the shared accessibility contract requires 48 where the component contract marks an interactive target. Panels preserve draft text when modes change. Reduced-motion mode removes nonessential transitions without removing state feedback.

Emoji and stickers, member mentions, and More use one active panel. On desktop the panel opens above the editor; in mobile layouts it follows the editor and toolbar in the same surface. Web and Flutter resolve the layout from the app viewport and mobile input environment; a narrow conversation column alone does not move a desktop panel below the editor. Native Android and iOS keep it below, including on tablets. Opening from the toolbar dismisses the soft keyboard; typing `@` keeps the editor focused. Member choices always come from the current SDK roster.

The inbox uses the shared conversation filters and list. It does not repeat the global search entry as a local conversation search field. Search inside an open chat and the destination picker used when forwarding are independent.

Theme propagation covers the input surface, border, focus ring, send action, disabled action, attachment controls, reply preview, mention treatment, errors, offline state, and upload progress. Components consume semantic or component tokens only.
