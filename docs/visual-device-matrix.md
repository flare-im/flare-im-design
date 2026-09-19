# Visual Device Matrix

The matrix samples boundaries from the checked token breakpoints: mobile below 600, dual pane at 720, compact shell at 900, triple pane at 1100, expanded shell at 1500.

| Profile | CSS/logical viewport | Expected structure | Required themes/text |
|---|---:|---|---|
| Mobile Small | 360 x 640 | single pane; chat minimum width stress | light, dark, 200% |
| Mobile Standard | 390 x 844 | single pane | light, dark, 200% |
| Mobile Large | 430 x 932 | single pane | light, dark, 200% |
| Tablet | 834 x 1194 | dual pane or task-preserving single pane at extreme text | light, dark, 200% |
| Desktop 1024 | 1024 x 768 | dual pane/compact shell | light, dark, 200% |
| Desktop 1440 | 1440 x 900 | triple pane | light, dark, 200% |
| Desktop 1920 | 1920 x 1080 | triple pane with bounded content widths | light, dark, 200% |

Every profile captures conversation, chat, detail, composer, search, and settings. Dialog/sheet, error/retry, offline, selected/unread, and long content are included at the nearest representative profile rather than duplicated on every device.

Baselines are accepted only from pinned OS/browser, locale, density, font scale, animation setting, theme, and deterministic fixture data. Reviewers must reject broad baseline updates that hide one-component regressions.
